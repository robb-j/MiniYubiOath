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
    private(set) var slotObservation: NSKeyValueObservation?
    
    
    // MARK: - public interface
    override func updateList() async {
        state = .loading
        items = [:]
        do {
            items = try await readYubiKey()
            state = .success
        } catch let error as OathError {
            state = .error(error)
        } catch {
            print(error)
            state = .error(.unknown)
        }
    }
    
    override func getCode(credential: OathCredential) async -> String? {
        do {
            return try await readCode(credential: credential)
        } catch {
            print("\(error)")
        }
        
        return nil
    }
    
    func setup() -> Self {
        guard let manager = TKSmartCardSlotManager.default, slotObservation == nil else { return self }
        
        // Initially fetch data
        Task { await updateList() }
        
        // Listen for new/removed cards
        slotObservation = manager.observe(\.slotNames) { manager, slotNames in
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                await self.updateList()
            }
        }
        
        return self
    }
    
    // MARK: - Internals
    
    func readYubiKey() async throws -> OrderedDictionary<String, [OathCredential]> {
        
        let listData = try await runTask { try await list(card: $0) }
        
        var output: OrderedDictionary<String, [OathCredential]> = [:]
        
        for cred in ListCredentialsParser(data: listData) {
            if let existing = output[cred.issuer] {
                output[cred.issuer] = existing + [cred]
            } else {
                output[cred.issuer] = [cred]
            }
        }
        
        output.sort { a, b in
            a.key.localizedStandardCompare(b.key).rawValue < 0
        }
        
        return output
    }
    
    // MARK: Card access
    
    func readCode(credential: OathCredential) async throws -> String? {
        let codeData = try await runTask { try await calculate(card: $0, credential: credential) }
        
        guard let code = CalculateParser.parse(codeData) else {
            return nil
        }
        
        return code.code
    }
    
    func list(card: TKSmartCard) async throws -> Data {
        let list = try ListAPDU().sendTo(card: card)
        
        if list.sw >> 8 == APDUResult.moreData {
            print("TODO: More data to send...")
        }
        
        guard list.sw == APDUResult.success else {
            print("list failed: \(list.sw)")
            throw OathError.notSupported
        }
        
        return list.response
    }
    
    func calculate(card: TKSmartCard, credential: OathCredential) async throws -> Data {
        let calculate = try CalculateAPDU(
            truncated: true,
            timestamp: Date().timeIntervalSince1970,
            credential: credential
        ).sendTo(card: card)
        
        if calculate.sw >> 8 == APDUResult.moreData {
            print("TODO: More data to send...")
        }
        
        guard calculate.sw == APDUResult.success else {
            print("Calculate failed: \(calculate.sw)")
            throw OathError.notSupported
        }
        
        return calculate.response
    }
    
    func calculateAll(card: TKSmartCard) async throws -> Data {
        
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
    
    // MARK: Utilities
    
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
        
        // Select the OATH application on the smart card
        let selectApp = try SelectApplicationAPDU(application: .oath).sendTo(card: card)
        
        guard selectApp.sw == APDUResult.success else {
            print("Failed to select OATH: \(selectApp.sw)")
            throw OathError.notSupported
        }

        return try await block(card)
    }
}
