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
        oathCodes = [
            "Apple": [
                OathCode(issuer: "Apple", account: "geoff@example.com", otp: "123456", type: .truncated)
            ],
            "Amazon": [
                OathCode(issuer: "Amazon", account: "geoff@example.com", otp: "123456", type: .truncated)
            ],
            "DigitalOcean": [
                OathCode(issuer: "DigitalOcean", account: "geoff@example.com", otp: "123456", type: .truncated)
            ],
            "Fathom Analytics": [
                OathCode(issuer: "Fathom Analytics", account: "geoff@example.com", otp: "123456", type: .truncated)
            ],
            "GitHub": [
                OathCode(issuer: "GitHub", account: "geoff@example.com", otp: "123456", type: .truncated)
            ],
            "Panic": [
                OathCode(issuer: "Panic", account: "geoff@example.com", otp: "123456", type: .truncated)
            ],
            "Twitter": [
                OathCode(issuer: "Twitter", account: "@robbb_j", otp: "123456", type: .truncated),
                OathCode(issuer: "Twitter", account: "@g_testington", otp: "123456", type: .truncated)
            ],
            "Vercel": [
                OathCode(issuer: "Vercel", account: "geoff@example.com", otp: "123456", type: .truncated)
            ],
        ]
    }
    
    // override func updateList() async {}
    
    // override func getCode(account: String) async -> String? { }
}
