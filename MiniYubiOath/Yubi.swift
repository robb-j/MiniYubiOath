//
//  Yubi.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 20/12/2022.
//

import Foundation
import CryptoTokenKit
import OrderedCollections

/// https://github.com/Yubico/yubikit-ios/blob/a9c57323fa7ecddaed2d38ddc360fb94ff03503c/YubiKit/YubiKit/Connections/Shared/Errors/YKFAPDUError.h
struct APDUResult {
    static let success = 0x9000
    static let insNotSupported = 0x6D00
    static let moreData = 0x61 // 0x61XX
}


struct APDUTag {
    static let name = 0x71
}


@MainActor
class Yubi: ObservableObject {
    @Published private(set) var oathCodes: OrderedDictionary<String, [OathCode]> = [:]
    @Published private(set) var state = State.loading
    
    enum SmartCardError: Error {
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
    enum State {
        case loading
        case success
        case error(SmartCardError)
        
        func getMessage() -> String {
            switch self {
            case .loading: return "Loading…"
            case .success: return "Connected"
            case .error(let error): return error.getMessage()
            }
        }
    }
    
    func update() async {
        state = .loading
        oathCodes = [:]
        do {
            oathCodes = try await readYubiKey()
            state = .success
        } catch let error as SmartCardError {
            state = .error(error)
        } catch {
            print(error)
            state = .error(.unknown)
        }
    }
    
    //    var timer: Timer?
    
//    func schedule() {
//        let startDate = Date(timeIntervalSince1970: ceil(Date().timeIntervalSince1970 / 60) * 60)
//
//        let timer = Timer(fire: startDate, interval: 15, repeats: true) { timer in
//            Task { await self.updateCodes() }
//        }
//        RunLoop.current.add(timer, forMode: .default)
//        self.timer = timer
//    }
//
    func readYubiKey() async throws -> OrderedDictionary<String, [OathCode]> {
        let oathCodesData = try await runTask { card in
            
            // Select the OATH application on the smart card
            let selectApp = try SelectApplicationAPDU(application: .oath).sendTo(card: card)
            
            guard selectApp.sw == APDUResult.success else {
                print("Failed to select OATH: \(selectApp.sw)")
                throw SmartCardError.notSupported
            }
            
            // TODO: respond to challenge if requested ?
            
            // Calculate all OATH codes
            let calculateAll = try CalculateAllAPDU(truncated: true, timestamp: Date().timeIntervalSince1970).sendTo(card: card)
            
            if calculateAll.sw >> 8 == APDUResult.moreData {
                print("TODO: More data to send...")
            }
            
            guard calculateAll.sw == APDUResult.success else {
                print("Calculate all failed: \(calculateAll.sw)")
                throw SmartCardError.notSupported
            }
            
            return calculateAll.response
        }
        
        var output: OrderedDictionary<String, [OathCode]> = [:]
        
        for code in AuthCodeParser(data: oathCodesData) {
            if let existing = output[code.issuer] {
                output[code.issuer] = existing + [code]
            } else {
                output[code.issuer] = [code]
            }
        }
        
        output.sort()
        
        return output
    }
    
    func runTask<T>(block: (TKSmartCard) async throws -> T) async throws -> T {
        guard let manager = TKSmartCardSlotManager.default else {
            throw SmartCardError.notSupported
        }
        guard let yubi = manager.slotNames.first(where: { $0.contains("YubiKey") }) else {
            throw SmartCardError.notConnected
        }
        
        guard let slot = manager.slotNamed(yubi) else { throw SmartCardError.notConnected }
        guard let card = slot.makeSmartCard() else { throw SmartCardError.notConnected }
        
        switch slot.state {
        case .missing:
            print("Missing")
        case .empty:
            print("Empty")
        case .probing:
            print("Probing")
        case .muteCard:
            print("Muted card")
        case .validCard:
            print("Valid card")
        @unknown default:
            print("Unknown")
        }
        
//        card.useExtendedLength = false
//        card.useCommandChaining = false
        
        let connected = try await card.beginSession()
        if !connected { throw SmartCardError.cannotStart }
        
        defer {
            card.endSession()
        }

        return try await block(card)
    }
}
