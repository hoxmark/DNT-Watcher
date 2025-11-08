#!/usr/bin/env swift

import Foundation

// Test 1: Check current directory
print("=== Test 1: Current Directory ===")
let currentPath = FileManager.default.currentDirectoryPath
print("Current directory: \(currentPath)")

// Test 2: Look for config file
print("\n=== Test 2: Config File Search ===")
var configPath: String?
var testPath = currentPath

for i in 0..<5 {
    let candidatePath = (testPath as NSString).appendingPathComponent("dnt_hytter.yaml")
    print("Checking: \(candidatePath)")

    if FileManager.default.fileExists(atPath: candidatePath) {
        configPath = candidatePath
        print("✓ Found config at: \(candidatePath)")
        break
    }
    testPath = (testPath as NSString).deletingLastPathComponent
}

if configPath == nil {
    print("✗ Config file not found")
}

// Test 3: Check history directory
print("\n=== Test 3: History Directory ===")
testPath = currentPath
var historyPath: String?

for i in 0..<5 {
    let candidatePath = (testPath as NSString).appendingPathComponent("history")
    var isDirectory: ObjCBool = false

    if FileManager.default.fileExists(atPath: candidatePath, isDirectory: &isDirectory), isDirectory.boolValue {
        historyPath = candidatePath
        print("✓ Found history at: \(candidatePath)")
        break
    }
    testPath = (testPath as NSString).deletingLastPathComponent
}

if historyPath == nil {
    print("✗ History directory not found")

    // Try to create it in the right place
    testPath = currentPath
    for _ in 0..<3 {
        testPath = (testPath as NSString).deletingLastPathComponent
        let configCheck = (testPath as NSString).appendingPathComponent("dnt_hytter.yaml")

        if FileManager.default.fileExists(atPath: configCheck) {
            let newHistoryPath = (testPath as NSString).appendingPathComponent("history")
            print("Creating history directory at: \(newHistoryPath)")
            try? FileManager.default.createDirectory(atPath: newHistoryPath, withIntermediateDirectories: true)
            break
        }
    }
}

print("\n=== Summary ===")
print("Config: \(configPath ?? "NOT FOUND")")
print("History: \(historyPath ?? "NOT FOUND")")
