//
//  MockYubi.swift
//  Yoath
//
//  Created by Rob Anderson on 21/12/2022.
//

import Foundation
import OrderedCollections

final class MockOathStore: OathStore {
    override init() {
        super.init()
        
        state = .success
        items = [
            "Apple": [
                OathCredential.mock(issuer: "Apple", account: "geoff@example.com")
            ],
            "Amazon": [
                OathCredential.mock(issuer: "Amazon", account: "geoff@example.com")
            ],
            "DigitalOcean": [
                OathCredential.mock(issuer: "DigitalOcean", account: "geoff@example.com")
            ],
            "Fathom Analytics": [
                OathCredential.mock(issuer: "Fathom Analytics", account: "geoff@example.com")
            ],
            "GitHub": [
                OathCredential.mock(issuer: "GitHub", account: "geoff@example.com")
            ],
            "Panic": [
                OathCredential.mock(issuer: "Panic", account: "geoff@example.com")
            ],
            "Twitter": [
                OathCredential.mock(issuer: "Twitter", account: "@robbb_j"),
                OathCredential.mock(issuer: "Twitter", account: "@g_testington")
            ],
            "Vercel": [
                OathCredential.mock(issuer: "Vercel", account: "geoff@example.com")
            ],
        ]
    }
    
    // override func updateList() async {}
    
    // override func getCode(credential: OathCredential) async -> String? { }
}
