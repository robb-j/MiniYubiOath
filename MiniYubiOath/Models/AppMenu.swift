//
//  AppMenu.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 02/12/2022.
//

import SwiftUI

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
// TODO: run USB commands in a serial queue?
// TODO: lock USB with a semaphore?



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
                OathCodeItem(issuer: issuer, oathCodes: yubi.oathCodes[issuer]!)
            }
        }
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}
