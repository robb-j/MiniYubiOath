//
//  MiniYubiOathApp.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 02/12/2022.
//

import SwiftUI

// TODO: the onChange doesn't get called, it seems SwiftUI doesn't trigger the scene stuff based on the menu itself
// https://stackoverflow.com/questions/74354717

@main
struct MiniYubiOathApp: App {
    @StateObject private var yubi = Yubi()
    
    var body: some Scene {
        MenuBarExtra("MiniYubiOATH", image: "StatusBarImage") {
            AppMenu()
                .environmentObject(yubi)
        }
    }
}
