#!/usr/bin/env swift

import AppKit
import Foundation

// MARK: - Drawing helpers

/// Draws the icon into an explicit-pixel bitmap so the output PNG is
/// exactly `size` x `size` pixels regardless of the host display's
/// backing scale (NSImage.lockFocus would otherwise produce 2x pixels
/// on a Retina Mac and break the asset catalog).
func drawIcon(size: CGFloat) -> NSBitmapImageRep {
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

    let scale = size / 1024.0

    // 1) Background: rounded square with radial gradient (crimson)
    let bgRect = NSRect(x: 0, y: 0, width: size, height: size)
    let bgRadius = size * 0.22
    let bgPath = NSBezierPath(
        roundedRect: bgRect,
        xRadius: bgRadius, yRadius: bgRadius
    )
    bgPath.addClip()

    let bgGradient = NSGradient(colors: [
        NSColor(srgbRed: 0.23, green: 0.06, blue: 0.06, alpha: 1.0),
        NSColor(srgbRed: 0.08, green: 0.02, blue: 0.02, alpha: 1.0),
    ])
    bgGradient?.draw(
        in: bgRect,
        relativeCenterPosition: NSPoint(x: 0, y: 0.2)
    )

    // 2) Moon (upper right): cream circle.
    let cream = NSColor(srgbRed: 0.96, green: 0.92, blue: 0.83, alpha: 1.0)
    let moonRadius = 70 * scale
    let moonCenter = CGPoint(x: 760 * scale, y: 760 * scale)
    cream.withAlphaComponent(0.95).setFill()
    NSBezierPath(ovalIn: NSRect(
        x: moonCenter.x - moonRadius,
        y: moonCenter.y - moonRadius,
        width: moonRadius * 2,
        height: moonRadius * 2
    )).fill()

    // 3) Stars (3 small dots, upper half)
    let starPositions: [(CGFloat, CGFloat, CGFloat)] = [
        (180, 820, 6),
        (320, 880, 4),
        (520, 850, 5),
    ]
    cream.setFill()
    for (sx, sy, sr) in starPositions {
        let r = sr * scale
        NSBezierPath(ovalIn: NSRect(
            x: sx * scale - r,
            y: sy * scale - r,
            width: r * 2, height: r * 2
        )).fill()
    }

    // 4) Crow silhouette in cream.
    cream.setFill()
    drawCrow(scale: scale)

    // 5) Eye (crimson circle).
    let eyeColor = NSColor(srgbRed: 0.78, green: 0.23, blue: 0.29, alpha: 1.0)
    eyeColor.setFill()
    let eyeR = 12 * scale
    let eyeCenter = CGPoint(x: 360 * scale, y: 530 * scale)
    NSBezierPath(ovalIn: NSRect(
        x: eyeCenter.x - eyeR,
        y: eyeCenter.y - eyeR,
        width: eyeR * 2, height: eyeR * 2
    )).fill()

    NSColor(srgbRed: 0.15, green: 0.03, blue: 0.05, alpha: 1.0).setFill()
    let pupilR = 4 * scale
    NSBezierPath(ovalIn: NSRect(
        x: eyeCenter.x - pupilR,
        y: eyeCenter.y - pupilR,
        width: pupilR * 2, height: pupilR * 2
    )).fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func drawCrow(scale: CGFloat) {
    // Body
    let body = NSBezierPath()
    body.move(to: CGPoint(x: 350 * scale, y: 400 * scale))
    body.curve(
        to: CGPoint(x: 750 * scale, y: 400 * scale),
        controlPoint1: CGPoint(x: 450 * scale, y: 280 * scale),
        controlPoint2: CGPoint(x: 650 * scale, y: 280 * scale)
    )
    body.curve(
        to: CGPoint(x: 800 * scale, y: 500 * scale),
        controlPoint1: CGPoint(x: 800 * scale, y: 420 * scale),
        controlPoint2: CGPoint(x: 820 * scale, y: 470 * scale)
    )
    body.curve(
        to: CGPoint(x: 350 * scale, y: 400 * scale),
        controlPoint1: CGPoint(x: 700 * scale, y: 580 * scale),
        controlPoint2: CGPoint(x: 450 * scale, y: 540 * scale)
    )
    body.close()
    body.fill()

    // Head
    let headR = 100 * scale
    let headCenter = CGPoint(x: 400 * scale, y: 530 * scale)
    NSBezierPath(ovalIn: NSRect(
        x: headCenter.x - headR,
        y: headCenter.y - headR,
        width: headR * 2,
        height: headR * 2
    )).fill()

    // Beak
    let beak = NSBezierPath()
    beak.move(to: CGPoint(x: 200 * scale, y: 520 * scale))
    beak.line(to: CGPoint(x: 320 * scale, y: 540 * scale))
    beak.line(to: CGPoint(x: 320 * scale, y: 510 * scale))
    beak.close()
    beak.fill()

    // Tail feathers
    let tail = NSBezierPath()
    tail.move(to: CGPoint(x: 780 * scale, y: 440 * scale))
    tail.line(to: CGPoint(x: 900 * scale, y: 480 * scale))
    tail.line(to: CGPoint(x: 880 * scale, y: 450 * scale))
    tail.line(to: CGPoint(x: 920 * scale, y: 430 * scale))
    tail.line(to: CGPoint(x: 870 * scale, y: 410 * scale))
    tail.line(to: CGPoint(x: 900 * scale, y: 380 * scale))
    tail.line(to: CGPoint(x: 780 * scale, y: 420 * scale))
    tail.close()
    tail.fill()

    // Legs
    let legWidth = 10 * scale
    let legHeight = 120 * scale
    for legX in [500.0, 580.0] {
        let leg = NSBezierPath(
            roundedRect: NSRect(
                x: legX * scale - legWidth / 2,
                y: 200 * scale,
                width: legWidth,
                height: legHeight
            ),
            xRadius: legWidth / 2,
            yRadius: legWidth / 2
        )
        leg.fill()
    }

    // Feet
    for legX in [500.0, 580.0] {
        let foot = NSBezierPath(
            roundedRect: NSRect(
                x: legX * scale - 30 * scale,
                y: 190 * scale,
                width: 60 * scale,
                height: 12 * scale
            ),
            xRadius: 6 * scale,
            yRadius: 6 * scale
        )
        foot.fill()
    }
}

func savePNG(rep: NSBitmapImageRep, to url: URL) {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(
            "Failed to encode PNG\n".data(using: .utf8)!
        )
        return
    }
    try? data.write(to: url)
}

// MARK: - Main

let outputDir = FileManager.default.currentDirectoryPath
    + "/Resources/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(
    atPath: outputDir,
    withIntermediateDirectories: true
)

struct IconSpec {
    let size: CGFloat
    let scale: Int
    let filename: String
    var pixelSize: CGFloat {
        size * CGFloat(scale)
    }
}

let specs: [IconSpec] = [
    IconSpec(size: 16, scale: 1, filename: "icon_16x16.png"),
    IconSpec(size: 16, scale: 2, filename: "icon_16x16@2x.png"),
    IconSpec(size: 32, scale: 1, filename: "icon_32x32.png"),
    IconSpec(size: 32, scale: 2, filename: "icon_32x32@2x.png"),
    IconSpec(size: 128, scale: 1, filename: "icon_128x128.png"),
    IconSpec(size: 128, scale: 2, filename: "icon_128x128@2x.png"),
    IconSpec(size: 256, scale: 1, filename: "icon_256x256.png"),
    IconSpec(size: 256, scale: 2, filename: "icon_256x256@2x.png"),
    IconSpec(size: 512, scale: 1, filename: "icon_512x512.png"),
    IconSpec(size: 512, scale: 2, filename: "icon_512x512@2x.png"),
]

print("Generating app icon...")
for spec in specs {
    let rep = drawIcon(size: spec.pixelSize)
    let url = URL(fileURLWithPath: outputDir + "/" + spec.filename)
    savePNG(rep: rep, to: url)
    print("  \(spec.filename) (\(Int(spec.pixelSize))px)")
}

let contentsJSON = """
{
  "images" : [
    { "size" : "16x16", "idiom" : "mac", "filename" : "icon_16x16.png", "scale" : "1x" },
    { "size" : "16x16", "idiom" : "mac", "filename" : "icon_16x16@2x.png", "scale" : "2x" },
    { "size" : "32x32", "idiom" : "mac", "filename" : "icon_32x32.png", "scale" : "1x" },
    { "size" : "32x32", "idiom" : "mac", "filename" : "icon_32x32@2x.png", "scale" : "2x" },
    { "size" : "128x128", "idiom" : "mac", "filename" : "icon_128x128.png", "scale" : "1x" },
    { "size" : "128x128", "idiom" : "mac", "filename" : "icon_128x128@2x.png", "scale" : "2x" },
    { "size" : "256x256", "idiom" : "mac", "filename" : "icon_256x256.png", "scale" : "1x" },
    { "size" : "256x256", "idiom" : "mac", "filename" : "icon_256x256@2x.png", "scale" : "2x" },
    { "size" : "512x512", "idiom" : "mac", "filename" : "icon_512x512.png", "scale" : "1x" },
    { "size" : "512x512", "idiom" : "mac", "filename" : "icon_512x512@2x.png", "scale" : "2x" }
  ],
  "info" : { "version" : 1, "author" : "xcode" }
}
"""
let contentsURL = URL(fileURLWithPath: outputDir + "/Contents.json")
try? contentsJSON.write(to: contentsURL, atomically: true, encoding: .utf8)
print("Wrote Contents.json")
print("Done.")
