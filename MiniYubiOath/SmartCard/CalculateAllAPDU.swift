//
//  CalculateAllAPDU.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 20/12/2022.
//

import Foundation

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
        let chal = CFSwapInt64HostToBig(UInt64(timestamp / 30));
        
        return Data([
            0x74, // Data[0] / tag
            0x08, // Data[1] / length of challenge
            
            UInt8((chal >>   0) & 0xFF), // Data[2] | challenge[0]
            UInt8((chal >>   8) & 0xFF), // Data[3] | challenge[1]
            UInt8((chal >>  16) & 0xFF), // Data[4] | challenge[2]
            UInt8((chal >>  24) & 0xFF), // Data[5] | challenge[3]
            UInt8((chal >>  32) & 0xFF), // Data[6] | challenge[4]
            UInt8((chal >>  40) & 0xFF), // Data[7] | challenge[5]
            UInt8((chal >>  48) & 0xFF), // Data[8] | challenge[6]
            UInt8((chal >>  56) & 0xFF), // Data[9] | challenge[7]
        ] as [UInt8])
    }
}
