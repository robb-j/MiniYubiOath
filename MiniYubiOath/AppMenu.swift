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
    let username: String
    let otp: Int
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
    
    let connected = try await card.beginSession()
    if !connected { throw YubiError.cannotStart }
    
    // Wait a little bit?
    try await Task.sleep(for: .milliseconds(200))
    
    guard card.isValid else { throw YubiError.lostConnection }
    
    let result = try await block(card)
    
    card.endSession()
    
    return result
}

@MainActor
class Yubi: ObservableObject {
    @Published private(set) var codes: [AuthCode] = []
    @Published private(set) var message = "Loading…"
    
//    init() {
//        Task {
//            await updateCodes()
//        }
//        // TODO: Plus schedule a timer for every 30s
//    }
    
    func updateCodes() async {
        codes = []
        
        do {
            codes = try await readYubiKey()
            message = "Connected"
        } catch {
            message = "Not connected"
        }
    }
    
    func readYubiKey() async throws -> [AuthCode] {
        let date = Date()
        let chal = UInt64(date.timeIntervalSince1970 / 30)
        
        let request = [
            0x00, // APDU CLA
            0xA4, // APDU INS
            0x00, // APDU P1
            0x01, // APDU P2 (0x01 for truncated)
            0x0A, // LenLc
            
            0x74, // Data[0] / tag
            0x08, // Data[1] / length of challenge
            
            UInt8((chal >>   0) & 0xFF), // Data[2] / challenge[0]
            UInt8((chal >>   8) & 0xFF), // Data[3] / challenge[1]
            UInt8((chal >>  16) & 0xFF), // Data[4] / challenge[2]
            UInt8((chal >>  24) & 0xFF), // Data[5] / challenge[3]
            UInt8((chal >>  32) & 0xFF), // Data[6] / challenge[4]
            UInt8((chal >>  40) & 0xFF), // Data[7] / challenge[5]
            UInt8((chal >>  48) & 0xFF), // Data[8] / challenge[6]
            UInt8((chal >>  56) & 0xFF), // Data[9] / challenge[7]
        ] as [UInt8]
        
        let codes = try await yubiTask { card in
            let response = try await card.transmit(Data(request))
            
            let statusCode = response
                .subdata(in: 0..<2)
                .reduce(into: UInt()) { result, byte in
                    result = (result << 8) | UInt(byte)
                }
            
//            let code = UInt16(response[0]) << 8 + UInt16(response[1])
            
            print(response, statusCode)
            
            guard statusCode != APDUResult.insNotSupported else {
                print("YKError.insNotSupported")
                throw YubiError.notSupported
            }
            
            if statusCode == 0x77 {
                print("TODO: HTOP response")
            }
            if statusCode == 0x7c {
                print("TODO: Touch required")
            }
            
            return []
        }
        
        print(codes)
        
        return []
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
            ForEach(yubi.codes) { code in
                Button("\(code.account) — \(code.username)") {
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

