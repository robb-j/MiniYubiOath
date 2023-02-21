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

extension APDU {
    func sendTo(card: TKSmartCard) throws -> (sw: UInt16, response: Data) {
        return try card.send(ins: ins, p1: p1, p2: p2, data: data, le: 0)
    }
}
