//
//  MiniYubiOathApp.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 02/12/2022.
//

import SwiftUI

// TODO: update every 30s on-the-30
// TODO: lock SmartCard access with a semaphore?

// TODO: the onChange doesn't get called, it seems SwiftUI doesn't trigger the scene stuff based on the menu itself
// https://stackoverflow.com/questions/74354717

@main
struct MiniYubiOathApp: App {
    @StateObject private var yubi = Yubi().schedule()
    
    var body: some Scene {
        MenuBarExtra("MiniYubiOATH", image: "StatusBarImage") {
            AppMenu()
                .environmentObject(yubi)
        }
    }
}
