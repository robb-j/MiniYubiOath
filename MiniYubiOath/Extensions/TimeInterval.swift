//
//  TimeInterval.swift
//  Yoath
//
//  Created by Rob Anderson on 21/02/2023.
//

import Foundation

extension TimeInterval {
    func apduData() -> Data {
        let chal = CFSwapInt64HostToBig(UInt64(self / 30));
        
        return Data([
            UInt8((chal >>   0) & 0xFF), // challenge[0]
            UInt8((chal >>   8) & 0xFF), // challenge[1]
            UInt8((chal >>  16) & 0xFF), // challenge[2]
            UInt8((chal >>  24) & 0xFF), // challenge[3]
            UInt8((chal >>  32) & 0xFF), // challenge[4]
            UInt8((chal >>  40) & 0xFF), // challenge[5]
            UInt8((chal >>  48) & 0xFF), // challenge[6]
            UInt8((chal >>  56) & 0xFF), // challenge[7]
        ])
    }
}
