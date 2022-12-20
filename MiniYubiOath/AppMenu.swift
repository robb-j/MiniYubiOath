//
//  AppMenu.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 02/12/2022.
//

import SwiftUI
import RegexBuilder
import CryptoTokenKit
import OrderedCollections

class AuthCode : Identifiable {
    var id: String { account }
    
    let issuer: String
    let account: String
    let otp: String
    let type: CodeType
    
    init(issuer: String, account: String, otp: String, type: CodeType) {
        self.issuer = issuer
        self.account = account
        self.otp = otp
        self.type = type
    }
}

enum CodeType {
    case htop
    case touch
    case truncated
    case full
}

enum YubiError: Error {
    case notSupported
    case notConnected
    case cannotStart
    case lostConnection
}

/// https://github.com/Yubico/yubikit-ios/blob/a9c57323fa7ecddaed2d38ddc360fb94ff03503c/YubiKit/YubiKit/Connections/Shared/Errors/YKFAPDUError.h
struct APDUResult {
    static let success = 0x9000
    static let insNotSupported = 0x6D00
    static let moreData = 0x61 // 0x61XX
}

struct APDUTag {
    static let name = 0x71
}

// TODO: update every 30s on-the-30
// TODO: catch errors in Yubi#updateCodes
// TODO: parse responses
// TODO: run USB commands in a serial queue?
// TODO: lock USB with a semaphore?

func yubiTask<T>(block: (TKSmartCard) async throws -> T) async throws -> T {
    guard let manager = TKSmartCardSlotManager.default else {
        throw YubiError.notSupported
    }
    guard let yubi = manager.slotNames.first(where: { $0.contains("YubiKey") }) else {
        throw YubiError.notConnected
    }
    
    guard let slot = manager.slotNamed(yubi) else { throw YubiError.notConnected }
    guard let card = slot.makeSmartCard() else { throw YubiError.notConnected }
    
    switch slot.state {
    case .missing:
        print("Missing")
    case .empty:
        print("Empty")
    case .probing:
        print("Probing")
    case .muteCard:
        print("Muted card")
    case .validCard:
        print("Valid card")
    @unknown default:
        print("Unknown")
    }
    
//    card.useExtendedLength = false
//    card.useCommandChaining = false
    
    let connected = try await card.beginSession()
    if !connected { throw YubiError.cannotStart }
    
//    // Wait a little bit?
//    try await Task.sleep(for: .milliseconds(200))
    
//    guard card.isValid else { throw YubiError.lostConnection }
    
    defer {
        card.endSession()
    }

    return try await block(card)
}

@MainActor
class Yubi: ObservableObject {
    @Published private(set) var oathCodes: OrderedDictionary<String, [AuthCode]> = [:]
    @Published private(set) var message = "Loading…"
    
    var timer: Timer?
    
    func updateCodes() async {
        oathCodes = [:]
        do {
            oathCodes = try await readYubiKey()
            message = "Connected"
        } catch {
            message = "Not connected"
        }
    }
    
    func schedule() {
        let startDate = Date(timeIntervalSince1970: ceil(Date().timeIntervalSince1970 / 60) * 60)
        
        let timer = Timer(fire: startDate, interval: 15, repeats: true) { timer in
            Task { await self.updateCodes() }
        }
        RunLoop.current.add(timer, forMode: .default)
        self.timer = timer
    }
    
    func readYubiKey() async throws -> OrderedDictionary<String, [AuthCode]> {
        let oathCodesData = try await yubiTask { card in
            
            // Select the OATH application on the smart card
            let selectApp = try card.send(apdu: SelectApplicationAPDU(application: .oath))
            
            guard selectApp.sw == APDUResult.success else {
                print("Failed to select OATH: \(selectApp.sw)")
                throw YubiError.notSupported
            }
            
            // TODO: respond to challenge if requested ?
            
            // Calculate all OATH codes
            let calculateAll = try card.send(apdu: CalculateAllAPDU(truncated: true, timestamp: Date().timeIntervalSince1970))
            
            if calculateAll.sw >> 8 == APDUResult.moreData {
                print("TODO: More data to send...")
            }
            
            guard calculateAll.sw == APDUResult.success else {
                print("Calculate all failed: \(calculateAll.sw)")
                throw YubiError.notSupported
            }
            
            return calculateAll.response
        }
        
        var output: OrderedDictionary<String, [AuthCode]> = [:]
        
        for code in AuthCodeParser(data: oathCodesData) {
            if let existing = output[code.issuer] {
                output[code.issuer] = existing + [code]
            } else {
                output[code.issuer] = [code]
            }
        }
        
        output.sort()
        
        return output
    }
}

struct AuthCodeParser: Sequence, IteratorProtocol {
    typealias Element = AuthCode
    
    var data: Data
    
    mutating func next() -> AuthCode? {
        guard data.endIndex > data.startIndex else { return nil }
        guard let (code, length) = parseCode(data) else { return nil }
        data = data.subdata(in: data.startIndex + length ..< data.endIndex)
        return code
    }
    
    func parseCode(_ data: Data) -> (AuthCode, Int)? {
        guard data[0] == APDUTag.name else { return nil }
        
        let nameLength = Int(data[1])
        guard let name = String(data: data[2 ..< (nameLength + 2)], encoding: .utf8) else { return nil }
        
        let responseTag = Int(data[nameLength + 2])
        let responseLength = Int(data[nameLength + 3])
        
        let otpDigits = data[4 + nameLength]
        let otpData = data[5 + nameLength ..< (4 + nameLength + responseLength)]
            .reduce(into: UInt()) { result, byte in result = (result << 8) | UInt(byte) }
        
        // ykf_parseOATHOTPFromIndex
        // TODO: parse otp properly + pad start
        let otp = String(format: "%0\(otpDigits)d", otpData)
        
        let type: CodeType
        
        switch responseTag {
        case 0x77: type = .htop
        case 0x7c: type = .touch
        case 0x75: type = .truncated
        case 0x76: type = .full
        default:
            print("Unknown response: \(responseTag)")
            return nil
        }
        
        let parts = name.split(separator: /:/)
        let issuer = String(parts.first != nil ? String(parts.first!) : "Unknown")
        let account = parts.last != nil ? String(parts.last!) : ""
        
        return (
            AuthCode(issuer: issuer, account: account, otp: otp, type: type),
            4 + nameLength + responseLength
        )
    }
}

struct OathCodeRow: View {
    let issuer: String
    let oathCodes: [AuthCode]
    
    var body: some View {
        if oathCodes.count == 1 {
            Button(issuer) {
                copy(text: "\(oathCodes.first!.otp)")
            }
        } else {
            Menu {
                ForEach(oathCodes) { code in
                    Button(code.account) {
                        copy(text: "\(code.otp)")
                    }
                }
            } label: {
                Text(issuer)
            }
        }
    }
    
    func copy(text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

struct AppMenu: View {
    @StateObject private var yubi = Yubi()
    
    var body: some View {
        Button("Fetch") {
            Task {
                await yubi.updateCodes()
            }
        }
        Text(yubi.message)
        Group {
            ForEach(yubi.oathCodes.keys, id: \.self) { issuer in
                OathCodeRow(issuer: issuer, oathCodes: yubi.oathCodes[issuer]!)
            }
        }
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}

// 121 - 0x79       version tag
// 3   - 0x3        version length
// 5   - 00000101
// 4   - 00000100
// 3   - 00000011   version=328707 or 197637 ?

// 113 - 0x71       name tag
// 8   - 0x8        name length
// 117
// 239
// 41
// 41
// 162
// 141
// 167
// 102
