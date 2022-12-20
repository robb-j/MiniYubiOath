//
//  AboutYoath.swift
//  Yoath
//
//  Created by Rob Anderson on 20/12/2022.
//

import Foundation
import SwiftUI

enum InfoKey: String {
    case appName = "CFBundleDisplayName"
    case version = "CFBundleShortVersionString"
    case build = "CFBundleVersion"
}

struct About: View {
    func getInfo(_ key: InfoKey) -> String {
        guard let version = Bundle.main.infoDictionary?[key.rawValue] as? String else {
            return "Unknown"
        }
        return version
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image("ExtraIcon")
            Text(getInfo(.appName))
                .font(.title)
            Text("Version \(getInfo(.version)) (\(getInfo(.build)))")
                .monospaced()
            Text("Made by [Rob Anderson](https://www.r0b.io)")
        }
        .padding(.all, 16)
        .fixedSize()
    }
}

struct About_Previews: PreviewProvider {
    static var previews: some View {
        About()
    }
}
