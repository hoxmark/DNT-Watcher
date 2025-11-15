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

func generateIcon(size: CGFloat, scale: CGFloat) -> NSBitmapImageRep? {
    let pixelSize = Int(size * scale)

    // Create bitmap directly with exact pixel dimensions
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: pixelSize * 4,
        bitsPerPixel: 32
    ) else {
        return nil
    }

    // Draw into the bitmap context
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current = context

    let rect = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)

    // Background gradient (blue to cyan)
    let gradient = NSGradient(
        colors: [
            NSColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0),
            NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0)
        ]
    )
    gradient?.draw(in: rect, angle: 135)

    // Draw mountain symbol
    let symbolSize = CGFloat(pixelSize) * 0.6
    let config = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .bold)

    if let symbolImage = NSImage(systemSymbolName: "mountain.2.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {

        // Tint white
        symbolImage.lockFocus()
        NSColor.white.set()
        let symbolBounds = NSRect(origin: .zero, size: symbolImage.size)
        symbolBounds.fill(using: .sourceAtop)
        symbolImage.unlockFocus()

        // Center the symbol
        let symbolRect = NSRect(
            x: (CGFloat(pixelSize) - symbolImage.size.width) / 2,
            y: (CGFloat(pixelSize) - symbolImage.size.height) / 2,
            width: symbolImage.size.width,
            height: symbolImage.size.height
        )

        symbolImage.draw(in: symbolRect)
    }

    NSGraphicsContext.restoreGraphicsState()

    return bitmap
}

func saveIcon(bitmap: NSBitmapImageRep, name: String, directory: URL) {
    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to generate PNG for \(name)")
        return
    }

    let fileURL = directory.appendingPathComponent("\(name).png")
    do {
        try pngData.write(to: fileURL)
        print("Generated: \(name).png (\(bitmap.pixelsWide)x\(bitmap.pixelsHigh))")
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
    if let bitmap = generateIcon(size: iconSpec.size, scale: iconSpec.scale) {
        saveIcon(bitmap: bitmap, name: iconSpec.name, directory: iconSetPath)
    }
}

print("Icon generation complete!")
