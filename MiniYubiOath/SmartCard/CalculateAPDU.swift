//
//  CalculateAPDU.swift
//  Yoath
//
//  Created by Rob Anderson on 21/02/2023.
//

import Foundation

//
// Calculate Data
//
// nameTag              0x71
// nameLen              (UInt8)
// nameData[nameLen]    (String)
// chalTag              0x74
// chalLen              (UInt8)
// chalData[chalLen]    (String)
//

class CalculateAPDU: APDU {
    let ins = UInt8(0xA2)
    let p1 = UInt8(0x00)
    let p2: UInt8
    let data: Data?
    
    init(truncated: Bool, timestamp: TimeInterval, credential: OathCredential) {
        p2 = truncated ? 0x01 : 0x00
        data = Self.calculateData(timestamp: timestamp, credential: credential)
    }
    
    static func calculateData(timestamp: TimeInterval, credential: OathCredential) -> Data {
        let chal = timestamp.apduData()
        let name = credential.id.data(using: .utf8)!
        
        // TODO: error if chal.count > UInt8?
        // TODO: error if name.count > UInt8?
        // TODO: error if no string data
        
        return Data([
                UInt8(0x71),
                UInt8(name.count)
            ])
            + name
            + Data([
                UInt8(0x74),
                UInt8(chal.count)
            ])
            + chal
    }
}


