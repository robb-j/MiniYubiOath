//
//  CalculateParser.swift
//  Yoath
//
//  Created by Rob Anderson on 21/02/2023.
//

import Foundation

//
// Response Syntax
//
// responseTag          | 0x75 for full response, 0x76 for truncated
// responseLength + 1   | (UInt8)
// digits               | High 4 bits is type, low 4 bits is algorithm
// responseData         | (utf8 string)
//

struct OathShortCode {
    let digits: UInt8
    let code: String
}

// It seems "truncated" only sends the minimum bytes,
// I'm not sure whats in the extra bytes

struct CalculateParser {
    static func parse(_ data: Data) -> OathShortCode? {
        guard data[0] == 0x76 else { return nil }
        
        let responseLength = data[1]
        let digits = data[2]
        let rawCode = data[3 ..< (3 + responseLength - 1)].reduce(into: UInt()) { result, byte in
            result = (result << 8) | UInt(byte)
        }
        let code = String(format: "%0\(digits)d", rawCode)
        
        return OathShortCode(digits: digits, code: code)
    }
}

