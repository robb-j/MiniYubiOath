//
//  SmartCardOathStore.swift
//  Yoath
//
//  Created by Rob Anderson on 21/12/2022.
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

final class SmartCardYubi: OathStore {
    private(set) var timer: Timer?
    private(set) var slotObservation: NSKeyValueObservation?
    
    override func update() async {
        state = .loading
        oathCodes = [:]
        do {
            oathCodes = try await readYubiKey()
            state = .success
        } catch let error as OathError {
            state = .error(error)
        } catch {
            print(error)
            state = .error(.unknown)
        }
    }
    
    func setup() -> Self {
        guard let manager = TKSmartCardSlotManager.default, timer == nil, slotObservation == nil else { return self }
        
        // Initially fetch data
        Task { await update() }
        
        // Setup timers
        let startDate = Date(timeIntervalSince1970: ceil(Date().timeIntervalSince1970 / 30) * 30)
        timer = Timer(fire: startDate, interval: 30, repeats: true) { timer in
            Task { await self.update() }
        }
        RunLoop.current.add(timer!, forMode: .default)
        
        // Listen for new/removed cards
        slotObservation = manager.observe(\.slotNames) { manager, slotNames in
            Task { await self.update() }
        }
        
        return self
    }
    
    func readYubiKey() async throws -> OrderedDictionary<String, [OathCode]> {
        let oathCodesData = try await runTask { card in
            
            // Select the OATH application on the smart card
            let selectApp = try SelectApplicationAPDU(application: .oath).sendTo(card: card)
            
            guard selectApp.sw == APDUResult.success else {
                print("Failed to select OATH: \(selectApp.sw)")
                throw OathError.notSupported
            }
            
            // Calculate all OATH codes
            let calculateAll = try CalculateAllAPDU(truncated: true, timestamp: Date().timeIntervalSince1970).sendTo(card: card)
            
            if calculateAll.sw >> 8 == APDUResult.moreData {
                print("TODO: More data to send...")
            }
            
            guard calculateAll.sw == APDUResult.success else {
                print("Calculate all failed: \(calculateAll.sw)")
                throw OathError.notSupported
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
        
        output.sort { a, b in
            a.key.localizedStandardCompare(b.key).rawValue < 0
        }
        
        return output
    }
    
    func runTask<T>(block: (TKSmartCard) async throws -> T) async throws -> T {
        guard let manager = TKSmartCardSlotManager.default else {
            throw OathError.notSupported
        }
        guard let yubi = manager.slotNames.first(where: { $0.contains("YubiKey") }) else {
            throw OathError.notConnected
        }
        
        guard let slot = manager.slotNamed(yubi) else { throw OathError.notConnected }
        guard let card = slot.makeSmartCard() else { throw OathError.notConnected }
        
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
            break
        @unknown default:
            print("Unknown")
        }
        
//        card.useExtendedLength = false
//        card.useCommandChaining = false
        
        let connected = try await card.beginSession()
        if !connected { throw OathError.cannotStart }
        
        defer {
            card.endSession()
        }

        return try await block(card)
    }
}
