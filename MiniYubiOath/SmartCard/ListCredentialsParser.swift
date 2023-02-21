//
//  ListCredentialsParser.swift
//  Yoath
//
//  Created by Rob Anderson on 21/02/2023.
//

import Foundation

let nameListTag = 0x72

//
// Response Syntax (repeats while the first byte is 0x72)
//
// nameTag              | 0x72
// nameLength + 1       | (UInt8)
// algorithm            | High 4 bits is type, low 4 bits is algorithm
// name[nameLength]     | (utf8 string)
//

struct ListCredentialsParser: Sequence, IteratorProtocol {
    typealias Element = OathCredential
    
    var data: Data
    
    mutating func next() -> OathCredential? {
        guard data.endIndex > data.startIndex else { return nil }
        guard let (code, length) = parse(data) else { return nil }
        data = data.subdata(in: data.startIndex + length ..< data.endIndex)
        return code
    }
    
    func parse(_ data: Data) -> (OathCredential, Int)? {
        guard data[0] == nameListTag else { return nil }
        
        let nameLength = Int(data[1])
        let algorithm = Int(data[2])
        guard let name = String(data: data[3 ..< (nameLength + 2)], encoding: .utf8) else { return nil }
        
        return (
            OathCredential(algorithm: algorithm, name: name),
            nameLength + 2
        )
    }
}

