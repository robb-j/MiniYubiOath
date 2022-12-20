//
//  SelectApplicationAPDU.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 20/12/2022.
//

import Foundation

enum APDUApplication {
    case oath
    
    func makeData() -> Data {
        switch self {
        case .oath: return Data([0xA0, 0x00, 0x00, 0x05, 0x27, 0x21, 0x01] as [UInt8])
        }
    }
}

class SelectApplicationAPDU: APDU {
    let ins = UInt8(0xA4)
    let p1 = UInt8(0x04)
    let p2 = UInt8(0x00)
    let data: Data?
    
    init(application: APDUApplication) {
        data = application.makeData()
    }
}
