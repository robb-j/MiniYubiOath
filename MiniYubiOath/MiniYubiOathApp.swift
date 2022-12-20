//
//  MiniYubiOathApp.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 02/12/2022.
//

import SwiftUI

// TODO: lock SmartCard access with a semaphore?

// TODO: the onChange doesn't get called, it seems SwiftUI doesn't trigger the scene stuff based on the menu itself
// https://stackoverflow.com/questions/74354717
// https://developer.apple.com/forums/thread/721627?login=true

@main
struct MiniYubiOathApp: App {
    @StateObject private var yubi = Yubi().schedule()
    
    var body: some Scene {
        MenuBarExtra("Yoath", image: "StatusBarImage") {
            AppMenu()
                .environmentObject(yubi)
        }
        
        Window("About", id: "about") {
            About()
        }
    }
}
