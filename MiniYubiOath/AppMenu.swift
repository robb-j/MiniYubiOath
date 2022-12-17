//
//  AppMenu.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 02/12/2022.
//

import SwiftUI
import RegexBuilder
import CryptoTokenKit

struct AuthCode : Identifiable {
    var id: String { account }
    
    let account: String
    let otp: String
    let type: CodeType
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
    @Published private(set) var codes: [AuthCode] = []
    @Published private(set) var message = "Loading…"
    
    var timer: Timer?
    
    func updateCodes() async {
        codes = []
        do {
            codes = try await readYubiKey()
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
    
    func readYubiKey() async throws -> [AuthCode] {
        let date = Date()
//        let chal = UInt64(date.timeIntervalSince1970 / 30)
        let chal = CFSwapInt64HostToBig(UInt64(date.timeIntervalSince1970 / 30));
        
        let app = Data([0xA0, 0x00, 0x00, 0x05, 0x27, 0x21, 0x01] as [UInt8])
        
        let challenge = Data([
            0x74, // Data[0] / tag
            0x08, // Data[1] / length of challenge
            
            UInt8((chal >>   0) & 0xFF), // Data[2] | challenge[0]
            UInt8((chal >>   8) & 0xFF), // Data[3] | challenge[1]
            UInt8((chal >>  16) & 0xFF), // Data[4] | challenge[2]
            UInt8((chal >>  24) & 0xFF), // Data[5] | challenge[3]
            UInt8((chal >>  32) & 0xFF), // Data[6] | challenge[4]
            UInt8((chal >>  40) & 0xFF), // Data[7] | challenge[5]
            UInt8((chal >>  48) & 0xFF), // Data[8] | challenge[6]
            UInt8((chal >>  56) & 0xFF), // Data[9] | challenge[7]
        ] as [UInt8])
        
        let codes = try await yubiTask { card in
            // Select program?
            let selectApp = try card.send(ins: 0xA4, p1: 0x04, p2: 0x00, data: app, le: 0)
            print(selectApp)
            
            guard selectApp.sw == APDUResult.success else {
                print("Failed to select OATH: \(selectApp.sw)")
                throw YubiError.notSupported
            }
            
            // TODO: respond to challenge if requested
            
            // Request codes
            let calculateAll = try card.send(ins: 0xA4, p1: 0x00, p2: 0x01, data: challenge, le: 0)
            print(calculateAll.sw, calculateAll.response)
            
            if calculateAll.sw >> 8 == APDUResult.moreData {
                print("TODO: More data to send...")
            }
            
            guard calculateAll.sw == APDUResult.success else {
                print("Calculate all failed: \(calculateAll.sw)")
                throw YubiError.notSupported
            }
            
            return [AuthCode](AuthCodeParser(data: calculateAll.response))
            
//            if statusCode == 0x77 {
//                print("TODO: HTOP response")
//            }
//            if statusCode == 0x7c {
//                print("TODO: Touch required")
//            }
            
        }
        
        return codes.sorted { a, b in
            return a.account < b.account
        }
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
        
//        let account = name.replacing(/:/, with: " - ")
        
        return (
            AuthCode(account: name, otp: otp, type: type),
            4 + nameLength + responseLength
        )
    }
}

struct AppMenu: View {
    @StateObject private var yubi = Yubi()
    
    let timer = Timer.publish(every: 60, on: .main, in: .default).autoconnect()
    
    init() {
        yubi.schedule()
    }
    
    var body: some View {
        Button("Fetch") {
            Task {
                await yubi.updateCodes()
            }
        }
        Text(yubi.message)
        Group {
            ForEach(yubi.codes) { code in
                Button("\(code.account)") {
                    copy(code: code)
                }
            }
        }
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
    
    func copy(code: AuthCode) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("\(code.otp)", forType: .string)
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
