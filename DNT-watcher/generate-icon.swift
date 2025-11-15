#!/usr/bin/env swift

import AppKit
import Foundation

// Icon sizes for iOS (in points)
let iconSizes: [(size: CGFloat, scale: CGFloat, name: String)] = [
    (20, 2, "Icon-20@2x"),
    (20, 3, "Icon-20@3x"),
    (29, 2, "Icon-29@2x"),
    (29, 3, "Icon-29@3x"),
    (40, 2, "Icon-40@2x"),
    (40, 3, "Icon-40@3x"),
    (60, 2, "Icon-60@2x"),
    (60, 3, "Icon-60@3x"),
    (1024, 1, "Icon-1024")
]

func generateIcon(size: CGFloat, scale: CGFloat) -> NSImage? {
    let pixelSize = size * scale
    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))

    image.lockFocus()

    // Background gradient (blue to cyan)
    let gradient = NSGradient(
        colors: [
            NSColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0),
            NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0)
        ]
    )
    gradient?.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize), angle: 135)

    // Draw mountain symbol
    let config = NSImage.SymbolConfiguration(pointSize: pixelSize * 0.6, weight: .bold)
    if let symbolImage = NSImage(systemSymbolName: "mountain.2.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {

        // Draw white mountain
        let symbolRect = NSRect(
            x: (pixelSize - symbolImage.size.width) / 2,
            y: (pixelSize - symbolImage.size.height) / 2,
            width: symbolImage.size.width,
            height: symbolImage.size.height
        )

        symbolImage.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    image.unlockFocus()

    return image
}

func saveIcon(image: NSImage, name: String, directory: URL) {
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        print("Failed to generate PNG for \(name)")
        return
    }

    let fileURL = directory.appendingPathComponent("\(name).png")
    do {
        try pngData.write(to: fileURL)
        print("Generated: \(name).png")
    } catch {
        print("Failed to write \(name).png: \(error)")
    }
}

// Main execution
let currentDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconSetPath = currentDir
    .appendingPathComponent("DNT-watcher")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")

print("Generating app icons...")
print("Output directory: \(iconSetPath.path)")

for iconSpec in iconSizes {
    if let icon = generateIcon(size: iconSpec.size, scale: iconSpec.scale) {
        saveIcon(image: icon, name: iconSpec.name, directory: iconSetPath)
    }
}

print("Icon generation complete!")
