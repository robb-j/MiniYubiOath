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
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        MenuBarExtra("MiniYubiOATH", image: "StatusBarImage") {
            AppMenu()
        }.onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("Became active")
            } else if newPhase == .background {
                print("Entered background")
            } else if newPhase == .inactive {
                print("Became inactive")
            }
        }
    }
}
