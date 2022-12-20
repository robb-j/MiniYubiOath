//
//  OathCodeItem.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 20/12/2022.
//

import Foundation
import SwiftUI

struct OathCodeItem: View {
    let issuer: String
    let oathCodes: [OathCode]
    
    var body: some View {
        if oathCodes.count == 1 {
            Button(issuer) {
                copy(text: oathCodes.first!.otp)
            }
        } else {
            Menu {
                ForEach(oathCodes) { code in
                    Button(code.account) {
                        copy(text: code.otp)
                    }
                }
            } label: {
                Text(issuer)
            }
        }
    }
    
    func copy(text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

