//
//  AppMenu.swift
//  MiniYubiOath
//
//  Created by Rob Anderson on 02/12/2022.
//

import SwiftUI
import RegexBuilder
import CryptoTokenKit

struct AuthCode : Identifiable {
    var id: String { account }
    
    let account: String
    let username: String
    let otp: Int
}

struct ProcessResult {
    let exitCode: Int32
    let output: String
    let error: String
}

/// https://www.hackingwithswift.com/example-code/system/how-to-run-an-external-program-using-process
func exec(_ binary: String, args: [String]) throws -> ProcessResult {
    let task = Process()
    task.executableURL = URL(filePath: binary)
    task.arguments = args
    
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    
    task.standardOutput = outputPipe
    task.standardError = errorPipe
    
    try task.run()
    task.waitUntilExit()
    
    let outputData = (try? outputPipe.fileHandleForReading.readToEnd()) ?? Data()
    let errorData = (try? errorPipe.fileHandleForReading.readToEnd()) ?? Data()
    
    return ProcessResult(
        exitCode: task.terminationStatus,
        output: String(data: outputData, encoding: .utf8) ?? "",
        error: String(data: errorData, encoding: .utf8) ?? ""
    )
}

enum MiniYubiError: Error {
    case ykmanNotInstalled
    case badRead
}

func findYkman() throws -> String {
    let result = try exec("/usr/bin/env", args: ["which", "ykman"])
    
    guard result.exitCode == 0 else {
        throw MiniYubiError.ykmanNotInstalled
    }
    return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
}

struct YKInfo {
    let codes: [AuthCode]?
    let error: String?
    
    static func codes(_ codes: [AuthCode]) -> YKInfo {
        return YKInfo(codes: codes, error: nil)
    }
    static func error(_ error: String) -> YKInfo {
        return YKInfo(codes: nil, error: error)
    }
}

func getInfo() -> YKInfo {
    getInfo2()
    
    do {
        let ykman = try findYkman()
        print("ykman=" + ykman)
        
        let result = try exec(ykman, args: ["oath", "accounts", "code"])
        
        
        guard result.exitCode == 0 else {
            print("Failed to read OATH codes")
            print(result.output)
            throw MiniYubiError.badRead
        }
        
        
        let regex = Regex {
            Anchor.startOfLine
            Capture {
                OneOrMore(.anyNonNewline, .reluctant)
            }
            ":"
            Capture {
                OneOrMore(.anyNonNewline, .reluctant)
            }
            OneOrMore(.whitespace)
            Capture {
                Repeat(count: 6) {
                    One(.digit)
                }
            }
            Anchor.endOfLine
        }
        
        let codes = result.output.matches(of: regex).map { match in
            AuthCode(account: String(match.output.1), username: String(match.output.2), otp: Int(match.output.3)!)
        }
        return YKInfo.codes(codes)
        
    } catch MiniYubiError.ykmanNotInstalled {
        return YKInfo.error("ykman not installed")
    }
    catch {
        return YKInfo.error("YubiKey not connected")
    }
}

//let YK_CHALLENGE_ALL_TAG =

/// https://developers.yubico.com/OATH/YKOATH_Protocol.html#_calculate_all_instruction
struct APDU {
    let cla: Int32
    let ins: Int32
    let p1: Int32
    let p2: Int32
}
struct Instructions {
    static let calcAll = APDU(cla: 0x00, ins: 0xa4, p1: 0x00, p2: 0x00)
}
struct CalcAllChallenge {
    var tag: UInt8 = 0x74
    var value: UInt64
    init(date: Date) {
        value = UInt64(date.timeIntervalSinceNow / 30)
    }
    mutating func append(data: inout Data) {
        var binEnd = CFSwapInt64HostToBig(value)
        var valueSize = UInt8(MemoryLayout.size(ofValue: binEnd))
        
        data.append(&tag, count: 1)
        data.append(&valueSize, count: 1)
        data.append(&binEnd, count: Int(valueSize))
    }
}

func appendByte(_ data: inout Data, byte: inout UInt8) {
    data.append(&byte, count: 1)
}

func getInfo2() {
    guard let manager = TKSmartCardSlotManager.default else { return }
    
//    guard let firstYubi = manager.slotNames.first(where: { $1.contains("YubiKey") }) else {
//        return
//    }
    guard let firstYubi = manager.slotNames.first(where: { $0.contains("YubiKey") }) else { return }
    
    guard let slot = manager.slotNamed(firstYubi) else { return }
    print(slot)
    
    guard let card = slot.makeSmartCard() else { return }
    print(card)
    
    var challenge = CalcAllChallenge(date: Date())
    
    var data = Data()
//    var some = MemoryLayout.size(ofValue: )
//    appendByte(&data, byte: &challenge.tag)
    
    
//    data.append(&challenge.tag, count: 1)
//    data.append(sizeof(Int), count: 1)
//    data.append(byt)
    
    
    // https://developers.yubico.com/OATH/YKOATH_Protocol.html#_calculate_all_instruction
//    let cla = 0x00
//    let ins = 0xa4
//    let p1 = 0x00
//    let p2 = 0x00 // 0x1 for truncated
//    let Lc = 0x00 // length of data
//    let data = 0x00 // Calculate all data
    
//    let now = Date().timeIntervalSince1970
//    let challengeTime = now / 30
    
//    card.beginSession { success, error in
//        if let error = error
//    }
}

//func getCodes() -> [AuthCode] {
//    let cmd = ["/opt/homebrew/bin/ykman", "oath", "accounts", "code"]
//
//    var data: [AuthCode] = []
//    let process = Subprocess(cmd)
//
//    try? process.launch() { (process, outputData, errorData) in
//        if process.exitCode == 0 {
//            let str = String(data: outputData, encoding: .utf8)
//            print(str)
//        } else {
//            print(String(data: errorData, encoding: .utf8))
//        }
//    }
//
//    process.waitForTermination()
//
//    return data
//}

// TODO: load the data in properly
// TODO: handle multiple states / async
// TODO: update every 30s on-the-30
// TODO: get it working in the sandbox
// TODO: bundle ykman in there somehow
//       or communicate natively
//       or try the c library
// TODO: handle not-connected error

struct AppMenu: View {
    var info = getInfo()
    
    var body: some View {
        if info.error != nil {
            Text(info.error ?? "Something went wrong")
            Button("Install ykman") {
                guard let url = URL(string: "https://formulae.brew.sh/formula/ykman#default") else {
                    fatalError("Invalid homebrew URL")
                }
                NSWorkspace.shared.open(url)
            }
        }
        
        ForEach(info.codes ?? []) { code in
            Button("\(code.account) — \(code.username)") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("\(code.otp)", forType: .string)
            }
        }

        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}

