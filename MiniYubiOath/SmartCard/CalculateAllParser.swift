//
//  CalculateAllParser.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 20/12/2022.
//

import Foundation

struct CalculateAllParser: Sequence, IteratorProtocol {
    typealias Element = OathCode
    
    var data: Data
    
    mutating func next() -> OathCode? {
        guard data.endIndex > data.startIndex else { return nil }
        guard let (code, length) = parseCode(data) else { return nil }
        data = data.subdata(in: data.startIndex + length ..< data.endIndex)
        return code
    }
    
    func parseCode(_ data: Data) -> (OathCode, Int)? {
        guard data[0] == 0x71 else { return nil }
        
        let nameLength = Int(data[1])
        guard let name = String(data: data[2 ..< (nameLength + 2)], encoding: .utf8) else { return nil }
        
        let responseTag = Int(data[nameLength + 2])
        let responseLength = Int(data[nameLength + 3])
        
        let otpDigits = data[4 + nameLength]
        let otpData = data[5 + nameLength ..< (4 + nameLength + responseLength)]
            .reduce(into: UInt()) { result, byte in result = (result << 8) | UInt(byte) }
        
        // ref: ykf_parseOATHOTPFromIndex
        let otp = String(format: "%0\(otpDigits)d", otpData)
        
        guard let type = OathCode.Tag(rawValue: responseTag) else {
            print("Unknown response: \(responseTag)")
            return nil
        }
        
        let parts = name.split(separator: /:/)
        let issuer = String(parts.first != nil ? String(parts.first!) : "Unknown")
        let account = parts.last != nil ? String(parts.last!) : ""
        
        return (
            OathCode(issuer: issuer, account: account, otp: otp, type: type),
            4 + nameLength + responseLength
        )
    }
}

//
// "Response" (repeats while the first byte is 0x71)
//
// nameTag                      | 0x71
// nameLength                   | (UInt8)
// name[nameLength]             | (utf8 string)
// responseTag                  | 0x77 for HOTP, 0x7C for touch, 0x75 for full response or 0x76 for truncated
// responseLength               | (UInt8) length of the response + 1 (for the digits)
// digits                       | (UInt8)
// response[responseLength-1]   | (Int)
// ...
//
