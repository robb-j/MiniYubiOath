//
//  APDU.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 20/12/2022.
//

import Foundation
import CryptoTokenKit

/// "Application Protocol Data Unit"
protocol APDU {
    var ins: UInt8 { get }
    var p1: UInt8 { get }
    var p2: UInt8 { get }
    var data: Data? { get }
}

extension TKSmartCard {
    func send(apdu: APDU) throws -> (sw: UInt16, response: Data) {
        return try send(ins: apdu.ins, p1: apdu.p1, p2: apdu.p2, data: apdu.data, le: 0)
    }
}
