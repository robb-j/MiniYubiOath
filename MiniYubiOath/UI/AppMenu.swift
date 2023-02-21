//
//  AppMenu.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 02/12/2022.
//

import SwiftUI

struct AppMenu: View {
    @EnvironmentObject private var yubi: OathStore
    @Environment(\.openWindow) private var openWindow
    
    let helpUrl = URL(string: "https://github.com/robb-j/MiniYubiOath/issues")
    let yubicoAuthenticatorUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.yubico.yubioath")
    
    var body: some View {
        if yubi.state != .success {
            Button("Retry") {
                Task { await yubi.updateList() }
            }
            Text(yubi.state.getMessage())
            Divider()
        }
        Group {
            ForEach(yubi.items.keys, id: \.self) { issuer in
                CredentialView(issuer: issuer, credentials: yubi.items[issuer]!)
                    .environmentObject(yubi)
            }
        }
        Divider()
        if yubi.state == .success {
            Button("Refresh list") {
                Task { await yubi.updateList() }
            }
        }
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
