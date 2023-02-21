//
//  CredentialView.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 20/12/2022.
//

import Foundation
import SwiftUI

struct CredentialView: View {
    @EnvironmentObject private var yubi: OathStore
    
    let issuer: String
    let credentials: [OathCredential]
    
    var body: some View {
        if credentials.count == 1 {
            Button(issuer) {
                chosen(credentials.first!)
            }
        } else {
            Menu {
                ForEach(credentials) { code in
                    Button(code.account) {
                        chosen(code)
                    }
                }
            } label: {
                Text(issuer)
            }
        }
    }
    
    func chosen(_ credential: OathCredential) {
        Task {
            guard let code = await yubi.getCode(credential: credential) else {
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
        CredentialView(issuer: "Duck", credentials: [
            OathCredential.mock(issuer: "Duck", account: "geoff-t"),
            OathCredential.mock(issuer: "Duck", account: "jess-s")
        ])
        CredentialView(issuer: "GitHub", credentials: [
            OathCredential.mock(issuer: "GitHub", account: "geoff-t")
        ])
    }
}
