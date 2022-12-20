//
//  AppMenu.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 02/12/2022.
//

import SwiftUI

struct AppMenu: View {
    @EnvironmentObject private var yubi: Yubi
    
    var body: some View {
        Button("Fetch") {
            Task {
                await yubi.update()
            }
        }
        Text(yubi.state.getMessage())
        Divider()
        Group {
            ForEach(yubi.oathCodes.keys, id: \.self) { issuer in
                OathCodeItem(issuer: issuer, oathCodes: yubi.oathCodes[issuer]!)
            }
        }
        Divider()
        Button("Quit") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}
