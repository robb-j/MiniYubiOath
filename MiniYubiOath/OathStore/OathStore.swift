//
//  Yubi.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 20/12/2022.
//

import Foundation
import OrderedCollections

struct APDUTag {
    static let name = 0x71
}

// SwiftUI doesn't support protocols with @EnvironmentObject,
// so we're using inheritence to mock-out smart cards for testing and demos


@MainActor
class OathStore: ObservableObject {
    @Published var oathCodes: OrderedDictionary<String, [OathCode]> = [:]
    @Published var state = State.loading
    
    enum OathError: Error {
        case notSupported
        case notConnected
        case cannotStart
        case unknown
        
        func getMessage() -> String {
            switch self {
            case .notSupported: return "Unsupported YubiKey"
            case .notConnected: return "Not connected"
            case .cannotStart: return "Failed to connect"
            case .unknown: return "Something went wrong"
            }
        }
    }
    enum State: Equatable {
        case loading
        case success
        case error(OathError)
        
        func getMessage() -> String {
            switch self {
            case .loading: return "Loading…"
            case .success: return "Connected"
            case .error(let error): return error.getMessage()
            }
        }
    }
    
    func updateList() async {}
    
    func getCode(account: String) async -> String? {
        return nil
    }
}



