#!/usr/bin/env swift

import AppKit
import Foundation

func drawMenuBarIcon(size: CGFloat) -> NSBitmapImageRep {
    let pixels = Int(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    NSColor.black.setFill()
    let scale = size / 22.0 // design at 22pt

    // Body
    let body = NSBezierPath()
    body.move(to: CGPoint(x: 8 * scale, y: 9 * scale))
    body.curve(
        to: CGPoint(x: 17 * scale, y: 9 * scale),
        controlPoint1: CGPoint(x: 10 * scale, y: 5 * scale),
        controlPoint2: CGPoint(x: 16 * scale, y: 5 * scale)
    )
    body.curve(
        to: CGPoint(x: 18 * scale, y: 11 * scale),
        controlPoint1: CGPoint(x: 18 * scale, y: 10 * scale),
        controlPoint2: CGPoint(x: 18.5 * scale, y: 10.5 * scale)
    )
    body.curve(
        to: CGPoint(x: 8 * scale, y: 9 * scale),
        controlPoint1: CGPoint(x: 15 * scale, y: 13 * scale),
        controlPoint2: CGPoint(x: 10 * scale, y: 11 * scale)
    )
    body.close()
    body.fill()

    // Head
    let headR = 3.0 * scale
    let headCenter = CGPoint(x: 9 * scale, y: 12 * scale)
    NSBezierPath(ovalIn: NSRect(
        x: headCenter.x - headR,
        y: headCenter.y - headR,
        width: headR * 2,
        height: headR * 2
    )).fill()

    // Beak
    let beak = NSBezierPath()
    beak.move(to: CGPoint(x: 4 * scale, y: 12 * scale))
    beak.line(to: CGPoint(x: 7 * scale, y: 13 * scale))
    beak.line(to: CGPoint(x: 7 * scale, y: 11 * scale))
    beak.close()
    beak.fill()

    // Legs
    let legWidth = 0.8 * scale
    for legX in [10.0, 14.0] {
        let leg = NSBezierPath(
            roundedRect: NSRect(
                x: legX * scale - legWidth / 2,
                y: 5 * scale,
                width: legWidth,
                height: 3.5 * scale
            ),
            xRadius: legWidth / 2,
            yRadius: legWidth / 2
        )
        leg.fill()
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func savePNG(rep: NSBitmapImageRep, to url: URL) {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        return
    }
    try? data.write(to: url)
}

let outputDir = FileManager.default.currentDirectoryPath
    + "/Resources/Assets.xcassets/MenuBarIcon.imageset"
try? FileManager.default.createDirectory(
    atPath: outputDir,
    withIntermediateDirectories: true
)

savePNG(
    rep: drawMenuBarIcon(size: 22),
    to: URL(fileURLWithPath: outputDir + "/menubar.png")
)
savePNG(
    rep: drawMenuBarIcon(size: 44),
    to: URL(fileURLWithPath: outputDir + "/menubar@2x.png")
)

let contentsJSON = """
{
  "images" : [
    { "idiom" : "mac", "filename" : "menubar.png", "scale" : "1x" },
    { "idiom" : "mac", "filename" : "menubar@2x.png", "scale" : "2x" }
  ],
  "info" : { "version" : 1, "author" : "xcode" },
  "properties" : { "template-rendering-intent" : "template" }
}
"""
try? contentsJSON.write(
    to: URL(fileURLWithPath: outputDir + "/Contents.json"),
    atomically: true, encoding: .utf8
)
print("Generated menu bar icon: \(outputDir)")
