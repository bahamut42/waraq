#!/usr/bin/swift
import AppKit
import Foundation

// MARK: - Configuration

let outputDir = "Resources/Assets.xcassets/AppIcon.appiconset"
let sizes: [(filename: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

// MARK: - Colors

let bgTop = NSColor(srgbRed: 31 / 255.0, green: 35 / 255.0, blue: 38 / 255.0, alpha: 1.0)
let bgBottom = NSColor(srgbRed: 20 / 255.0, green: 23 / 255.0, blue: 26 / 255.0, alpha: 1.0)
let cream = NSColor(srgbRed: 245 / 255.0, green: 236 / 255.0, blue: 214 / 255.0, alpha: 1.0)

// MARK: - Drawing helpers

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

/// Convert normalized point to canvas coords. macOS NSBezierPath
/// y-axis is bottom-up, so we flip y.
func pt(_ x: CGFloat, _ y: CGFloat, size s: CGFloat) -> NSPoint {
    NSPoint(x: x * s, y: (1 - y) * s)
}

/// Draw a horizontal zigzag (chevron) at center y, with peaks
/// alternating above and below the center.
func drawChevron(
    centerY: CGFloat,
    fromX: CGFloat, toX: CGFloat,
    peaks: Int,
    amplitude: CGFloat,
    size s: CGFloat,
    lineWidth: CGFloat
) {
    let path = NSBezierPath()
    let step = (toX - fromX) / CGFloat(peaks * 2)
    var x = fromX
    var goingUp = true
    path.move(to: pt(x, centerY, size: s))
    for _ in 0..<(peaks * 2) {
        x += step
        let y = goingUp ? (centerY - amplitude) : (centerY + amplitude)
        path.line(to: pt(x, y, size: s))
        goingUp.toggle()
    }
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
}

func drawIcon(size: Int) -> NSBitmapImageRep? {
    guard let (rep, ctx) = makeContext(size: size) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    let s = CGFloat(size)
    let cornerRadius = s * 0.22

    // 1. Background gradient with rounded-rect clip
    let bgRect = NSRect(x: 0, y: 0, width: s, height: s)
    let bgPath = NSBezierPath(
        roundedRect: bgRect,
        xRadius: cornerRadius, yRadius: cornerRadius
    )
    NSGraphicsContext.saveGraphicsState()
    bgPath.addClip()
    if let bgGradient = NSGradient(starting: bgTop, ending: bgBottom) {
        bgGradient.draw(in: bgRect, angle: -90)
    }

    // 2. Paper sheet outline (stroked rounded rect)
    cream.setStroke()
    let lineWidth = s * 0.04
    let paperRect = NSRect(
        x: 0.18 * s,
        y: (1 - 0.68) * s,
        width: 0.64 * s,
        height: 0.52 * s
    )
    let paperPath = NSBezierPath(
        roundedRect: paperRect,
        xRadius: s * 0.04, yRadius: s * 0.04
    )
    paperPath.lineWidth = lineWidth
    paperPath.lineJoinStyle = .round
    paperPath.stroke()

    // 3. Chevron pattern (5 rows in upper portion of paper)
    let chevronLineWidth = s * 0.025
    let chevronAmplitude = s * 0.02
    let chevronYs: [CGFloat] = [0.24, 0.32, 0.40, 0.48, 0.56]
    let chevronFromX: CGFloat = 0.22
    let chevronToX: CGFloat = 0.78
    for y in chevronYs {
        drawChevron(
            centerY: y,
            fromX: chevronFromX, toX: chevronToX,
            peaks: 5, amplitude: chevronAmplitude,
            size: s, lineWidth: chevronLineWidth
        )
    }

    // 4. Rolled section at bottom of paper
    // Outer oval representing the rolled cylinder side profile
    let rollRect = NSRect(
        x: 0.18 * s,
        y: (1 - 0.84) * s,
        width: 0.64 * s,
        height: 0.18 * s
    )
    let rollPath = NSBezierPath(
        roundedRect: rollRect,
        xRadius: s * 0.09, yRadius: s * 0.09
    )
    rollPath.lineWidth = lineWidth
    rollPath.lineJoinStyle = .round
    rollPath.stroke()

    // Inner curl: a small shape on the right end showing the
    // inside of the rolled paper
    let curlRect = NSRect(
        x: 0.62 * s,
        y: (1 - 0.80) * s,
        width: 0.14 * s,
        height: 0.10 * s
    )
    let curlPath = NSBezierPath(
        roundedRect: curlRect,
        xRadius: s * 0.05, yRadius: s * 0.05
    )
    curlPath.lineWidth = chevronLineWidth
    curlPath.stroke()

    NSGraphicsContext.restoreGraphicsState() // bg clip
    NSGraphicsContext.restoreGraphicsState() // outer save

    return rep
}

// MARK: - Save

func savePNG(rep: NSBitmapImageRep, to path: String) throws {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(
            domain: "GenerateAppIcon", code: 1,
            userInfo: [NSLocalizedDescriptionKey: "PNG encode failed"]
        )
    }
    try data.write(to: URL(fileURLWithPath: path))
}

// MARK: - Main

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
    do {
        try savePNG(rep: rep, to: path)
        print("Wrote \(path) (\(pixels)x\(pixels), \(rep.pixelsWide)x\(rep.pixelsHigh) actual)")
    } catch {
        print("FAILED to write \(path): \(error)")
        exit(1)
    }
}

print("Done")
