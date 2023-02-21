//
//  OathCredential.swift
//  Yoath
//
//  Created by Rob Anderson on 21/02/2023.
//

import Foundation

struct OathCredential: Identifiable {
    let algorithm: Int
    let issuer: String
    let account: String
    let id: String
    
    init(algorithm: Int, name: String) {
        let parts = name.split(separator: ":", maxSplits: 1)
        self.init(algorithm: algorithm, issuer: String(parts[0]), account: String(parts[1]))
    }
    
    init(algorithm: Int, issuer: String, account: String) {
        self.algorithm = algorithm
        self.issuer = issuer
        self.account = account
        self.id = "\(issuer):\(account)"
    }
    
    static func mock(issuer: String, account: String) -> OathCredential {
        return OathCredential(algorithm: 0, issuer: issuer, account: account)
    }
}
