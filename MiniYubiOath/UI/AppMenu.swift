//
//  AppMenu.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 02/12/2022.
//

import SwiftUI

struct AppMenu: View {
    @EnvironmentObject private var yubi: Yubi
    @Environment(\.openWindow) private var openWindow
    
    let helpUrl = URL(string: "https://github.com/robb-j/MiniYubiOath/issues")
    let yubicoAuthenticatorUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.yubico.yubioath")
    
    var body: some View {
        if yubi.state != .success {
            Button("Retry") {
                Task { await yubi.update() }
            }
            Text(yubi.state.getMessage())
            Divider()
        }
        Group {
            ForEach(yubi.oathCodes.keys, id: \.self) { issuer in
                OathCodeItem(issuer: issuer, oathCodes: yubi.oathCodes[issuer]!)
            }
        }
        Divider()
        if yubicoAuthenticatorUrl != nil {
            Button("Open Yubico Authenticator") {
                NSWorkspace.shared.openApplication(at: yubicoAuthenticatorUrl!, configuration: NSWorkspace.OpenConfiguration())
            }
        }
        if helpUrl != nil {
            Button("Get help") {
                NSWorkspace.shared.open(helpUrl!)
            }
        }
        Button("About") {
            openWindow(id: "about")
        }
        Button("Quit") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}
