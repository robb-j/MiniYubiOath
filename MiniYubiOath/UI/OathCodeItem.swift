//
//  OathCodeItem.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 20/12/2022.
//

import Foundation
import SwiftUI

struct OathCodeItem: View {
    @EnvironmentObject private var yubi: OathStore
    
    let issuer: String
    let oathCodes: [OathCode]
    
    var body: some View {
        if oathCodes.count == 1 {
            Button(issuer) {
                chosen(code: oathCodes.first!)
            }
        } else {
            Menu {
                ForEach(oathCodes) { code in
                    Button(code.account) {
                        chosen(code: code)
                    }
                }
            } label: {
                Text(issuer)
            }
        }
    }
    
    func chosen(code: OathCode) {
        Task {
            guard let code = await yubi.getCode(account: oathCodes.first!.account) else {
                print("Cannot calculate code...")
                return
            }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(code, forType: .string)
        }
    }
}

struct OathCodeItem_Previews: PreviewProvider {
    static var previews: some View {
        OathCodeItem(issuer: "Duck", oathCodes: [
            OathCode(issuer: "Duck", account: "geoff-t", otp: "123456", type: .truncated),
            OathCode(issuer: "Duck", account: "jess-s", otp: "123456", type: .truncated)
        ])
        OathCodeItem(issuer: "GitHub", oathCodes: [
            OathCode(issuer: "GitHub", account: "geoff-t", otp: "123456", type: .truncated)
        ])
    }
}
