//
//  OathCode.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 20/12/2022.
//

import Foundation

class OathCode : Identifiable {
    var id: String { account }
    
    let issuer: String
    let account: String
    let otp: String
    let type: Tag
    
    enum Tag: Int {
        case htop = 0x77
        case touch = 0x7c
        case truncated = 0x75
        case full = 0x76
    }
    
    init(issuer: String, account: String, otp: String, type: Tag) {
        self.issuer = issuer
        self.account = account
        self.otp = otp
        self.type = type
    }
}
