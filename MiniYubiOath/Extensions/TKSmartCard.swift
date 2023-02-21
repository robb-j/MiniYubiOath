//
//  TKSmartCard.swift
//  Yoath
//
//  Created by Rob Anderson on 21/02/2023.
//

import CryptoTokenKit

extension TKSmartCard {
    func send(apdu: APDU) throws -> (sw: UInt16, response: Data) {
        return try send(ins: apdu.ins, p1: apdu.p1, p2: apdu.p2, data: apdu.data, le: 0)
    }
}
