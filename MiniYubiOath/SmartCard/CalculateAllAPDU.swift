//
//  CalculateAllAPDU.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 20/12/2022.
//

import Foundation

// Calculate All Data
//
// chalTag              0x74
// chalLen              (UInt8)
// chalData[chalLen]    (Challenge data)

class CalculateAllAPDU: APDU {
    let ins = UInt8(0xA4)
    let p1 = UInt8(0x00)
    let p2: UInt8
    let data: Data?
    
    init(truncated: Bool, timestamp: TimeInterval) {
        p2 = truncated ? 0x01 : 0x00
        data = Self.calculateData(timestamp: timestamp)
    }
    
    static func calculateData(timestamp: TimeInterval) -> Data {
        let chal = timestamp.apduData()
        
        return Data([UInt8(0x74), UInt8(chal.count)]) + chal
    }
}
