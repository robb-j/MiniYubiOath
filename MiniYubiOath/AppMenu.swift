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
}

// TODO: update every 30s on-the-30
// TODO: catch errors in Yubi#updateCodes
// TODO: parse responses
// TODO: run USB commands in a serial queue?
// TODO: lock USB with a semaphore?

@MainActor
class Yubi: ObservableObject {
    @Published private(set) var codes: [AuthCode] = []
    @Published private(set) var message = "Loading…"
    
    func updateCodes() async {
        codes = []
        
        do {
            codes = try await readYubiKey()
            message = "Connected"
        } catch {
            message = "Failed"
        }
    }
    
    func readYubiKey() async throws -> [AuthCode] {
        guard let manager = TKSmartCardSlotManager.default else {
            throw YubiError.notSupported
        }
        guard let firstYubi = manager.slotNames.first(where: { $0.contains("YubiKey") }) else {
            throw YubiError.notConnected
        }
        
        guard let slot = manager.slotNamed(firstYubi) else { throw YubiError.notConnected }
        print(slot)
        
        guard let card = slot.makeSmartCard() else { throw YubiError.notConnected }
        print(card)
        
        let date = Date()
        let chal = UInt64(date.timeIntervalSince1970 / 30)
        
        let request = Data([
            0x00, // cla
            0xa4, // ins
            0x00, // p1
            0x00, // p2 (0x01 for truncated)
            0x0a, // lc
            0x74, // data[0] / tag
            0x08, // data[1] / length of challenge
            
            UInt8((chal >>   0) & 0xFF), // data[2] / challenge[0]
            UInt8((chal >>   8) & 0xFF), // data[3] / challenge[1]
            UInt8((chal >>  16) & 0xFF), // data[4] / challenge[2]
            UInt8((chal >>  24) & 0xFF), // data[5] / challenge[3]
            UInt8((chal >>  32) & 0xFF), // data[6] / challenge[4]
            UInt8((chal >>  40) & 0xFF), // data[7] / challenge[5]
            UInt8((chal >>  48) & 0xFF), // data[8] / challenge[6]
            UInt8((chal >>  56) & 0xFF), // data[9] / challenge[7]
        ] as [UInt8])
        
        let connected = try await card.beginSession()
        if !connected { throw YubiError.cannotStart }
        
        // Wait a little bit?
        try await Task.sleep(for: .seconds(0.2))
        
        let response = try await card.transmit(request)
        
        print(response)
        
//        let b1 = response[0]
//        let b2 = response[1]
//        var key = UInt16()
//        response.copyBytes(to: &key, from: Range(start: 0, end: 1))
        
        // 109      — 0
        // 01101101 - 00000000
        
        // 0110110100000000
        
        // TODO: parse response
        
        return []
    }
}

// YKFAPDUErrorCodeMoreData                 = 0x61


// ...

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

