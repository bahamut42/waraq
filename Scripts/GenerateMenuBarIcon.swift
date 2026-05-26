#!/usr/bin/swift
import AppKit
import Foundation

let outputDir = "Resources/Assets.xcassets/MenuBarIcon.imageset"
let sizes: [(filename: String, pixels: Int)] = [
    ("menubar.png", 22),
    ("menubar@2x.png", 44),
]

func makeContext(size: Int) -> (NSBitmapImageRep, NSGraphicsContext)? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: size * 4, bitsPerPixel: 32
    ) else { return nil }
    rep.size = NSSize(width: size, height: size)
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        return nil
    }
    return (rep, ctx)
}

func drawIcon(size: Int) -> NSBitmapImageRep? {
    guard let (rep, ctx) = makeContext(size: size) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    let s = CGFloat(size)
    NSColor.black.setFill()

    // Combined filled silhouette: paper sheet (rounded rect)
    // + rolled cylinder at bottom (rounded rect with larger
    // corner radius for the curved roll look). The shapes
    // overlap so they read as one connected silhouette.

    let sheetRect = NSRect(
        x: 0.20 * s,
        y: (1 - 0.68) * s,
        width: 0.60 * s,
        height: 0.50 * s
    )
    let sheetPath = NSBezierPath(
        roundedRect: sheetRect,
        xRadius: s * 0.04, yRadius: s * 0.04
    )
    sheetPath.fill()

    let rollRect = NSRect(
        x: 0.16 * s,
        y: (1 - 0.88) * s,
        width: 0.68 * s,
        height: 0.20 * s
    )
    let rollPath = NSBezierPath(
        roundedRect: rollRect,
        xRadius: s * 0.10, yRadius: s * 0.10
    )
    rollPath.fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func savePNG(rep: NSBitmapImageRep, to path: String) throws {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "GenerateMenuBarIcon", code: 1)
    }
    try data.write(to: URL(fileURLWithPath: path))
}

let fm = FileManager.default
try? fm.createDirectory(
    atPath: outputDir, withIntermediateDirectories: true
)

for (filename, pixels) in sizes {
    guard let rep = drawIcon(size: pixels) else {
        print("FAILED: \(filename)")
        exit(1)
    }
    let path = "\(outputDir)/\(filename)"
    try savePNG(rep: rep, to: path)
    print("Wrote \(path) (\(pixels)x\(pixels), \(rep.pixelsWide)x\(rep.pixelsHigh) actual)")
}

print("Done")
