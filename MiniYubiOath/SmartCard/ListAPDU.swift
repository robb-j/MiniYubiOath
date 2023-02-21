//
//  ListAPDU.swift
//  Yoath
//
//  Created by Rob Anderson on 21/02/2023.
//

import Foundation

class ListAPDU: APDU {
    let ins = UInt8(0xA1)
    let p1 = UInt8(0x00)
    let p2 = UInt8(0x00)
    let data: Data? = nil
}
