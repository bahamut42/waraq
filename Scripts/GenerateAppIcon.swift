#!/usr/bin/swift
// Generates app icon PNGs for AppIcon.appiconset.
//
// Crumpled paper on dark slate. Waraq = paper (Arabic).
// The design references both the app name directly and the
// project's self-aware "janky solution" identity.
//
// Run from project root:
//   swift Scripts/GenerateAppIcon.swift
//
// IMPORTANT: uses NSBitmapImageRep with explicit pixel
// dimensions instead of NSImage.lockFocus, which would
// produce 2x-backed pixels on Retina Macs (a 512 request
// would actually yield 1024). Verified via sips after each
// write.

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

let paperTop = NSColor(srgbRed: 245 / 255.0, green: 236 / 255.0, blue: 214 / 255.0, alpha: 1.0)
let paperBottom = NSColor(srgbRed: 235 / 255.0, green: 223 / 255.0, blue: 192 / 255.0, alpha: 1.0)

let creaseColor = NSColor(srgbRed: 148 / 255.0, green: 138 / 255.0, blue: 115 / 255.0, alpha: 0.55)
let highlightColor = NSColor(srgbRed: 255 / 255.0, green: 251 / 255.0, blue: 239 / 255.0, alpha: 0.45)
let dropShadow = NSColor.black.withAlphaComponent(0.35)
let inkColor = NSColor(srgbRed: 31 / 255.0, green: 31 / 255.0, blue: 35 / 255.0, alpha: 0.6)

// MARK: - Paper geometry (normalized 0..1, y is from top)

/// Irregular polygon outlining a crumpled paper viewed roughly
/// top-down. Vertices clockwise starting top-left, with
/// asymmetric offsets to suggest hand-crumpled rather than
/// folded-geometrically.
let paperOutline: [(CGFloat, CGFloat)] = [
    (0.22, 0.24), // TL
    (0.36, 0.18), // T1 peak
    (0.50, 0.21), // TM slight valley
    (0.65, 0.17), // T2 peak
    (0.80, 0.23), // TR
    (0.85, 0.36), // R1 raised
    (0.82, 0.50), // RM valley
    (0.86, 0.63), // R2 raised
    (0.81, 0.76), // BR
    (0.66, 0.82), // B1 peak
    (0.50, 0.79), // BM
    (0.35, 0.83), // B2 peak
    (0.19, 0.78), // BL
    (0.16, 0.64), // L1 raised
    (0.20, 0.50), // LM valley
    (0.17, 0.36), // L2 raised
]

/// Internal crease lines (start, end) in normalized coords.
/// Six segments that suggest folds crisscrossing the surface.
let creases: [((CGFloat, CGFloat), (CGFloat, CGFloat))] = [
    ((0.22, 0.24), (0.62, 0.55)), // TL diagonal toward interior
    ((0.62, 0.55), (0.81, 0.76)), // interior to BR
    ((0.80, 0.23), (0.46, 0.55)), // TR diagonal toward interior
    ((0.46, 0.55), (0.19, 0.78)), // interior to BL
    ((0.36, 0.18), (0.44, 0.46)), // T1 short crease
    ((0.66, 0.82), (0.56, 0.60)), // B1 short crease
]

// MARK: - Drawing

func makeContext(size: Int) -> (NSBitmapImageRep, NSGraphicsContext)? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: size * 4,
        bitsPerPixel: 32
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

func drawIcon(size: Int) -> NSBitmapImageRep? {
    guard let (rep, ctx) = makeContext(size: size) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    let s = CGFloat(size)
    let cornerRadius = s * 0.22

    // 1. Rounded-rect clip + background gradient
    let bgRect = NSRect(x: 0, y: 0, width: s, height: s)
    let bgPath = NSBezierPath(
        roundedRect: bgRect,
        xRadius: cornerRadius,
        yRadius: cornerRadius
    )
    NSGraphicsContext.saveGraphicsState()
    bgPath.addClip()

    guard let bgGradient = NSGradient(starting: bgTop, ending: bgBottom) else {
        NSGraphicsContext.restoreGraphicsState()
        NSGraphicsContext.restoreGraphicsState()
        return nil
    }
    bgGradient.draw(in: bgRect, angle: -90)

    // 2. Paper polygon path
    let paperPath = NSBezierPath()
    paperPath.move(to: pt(paperOutline[0].0, paperOutline[0].1, size: s))
    for vertex in paperOutline.dropFirst() {
        paperPath.line(to: pt(vertex.0, vertex.1, size: s))
    }
    paperPath.close()

    // 3. Drop shadow under paper
    let shadow = NSShadow()
    shadow.shadowColor = dropShadow
    shadow.shadowBlurRadius = s * 0.025
    shadow.shadowOffset = NSSize(width: s * 0.012, height: -s * 0.018)
    shadow.set()

    // 4. Fill paper with gradient (shadow applies to fill)
    NSGraphicsContext.saveGraphicsState()
    paperPath.addClip()
    if let paperGradient = NSGradient(starting: paperTop, ending: paperBottom) {
        paperGradient.draw(in: paperPath.bounds, angle: -75)
    }
    NSGraphicsContext.restoreGraphicsState()

    // Clear shadow so subsequent strokes don't get shadowed
    let noShadow = NSShadow()
    noShadow.shadowColor = .clear
    noShadow.shadowOffset = .zero
    noShadow.shadowBlurRadius = 0
    noShadow.set()

    // 5. Crease lines (clipped to paper)
    NSGraphicsContext.saveGraphicsState()
    paperPath.addClip()

    // Shadow side of each crease
    creaseColor.setStroke()
    for crease in creases {
        let line = NSBezierPath()
        line.move(to: pt(crease.0.0, crease.0.1, size: s))
        line.line(to: pt(crease.1.0, crease.1.1, size: s))
        line.lineWidth = s * 0.008
        line.lineCapStyle = .round
        line.stroke()
    }

    // Highlight side of each crease (offset slightly toward upper-left
    // to simulate the raised edge where light catches the fold).
    highlightColor.setStroke()
    let off = s * 0.005
    for crease in creases {
        let line = NSBezierPath()
        line.move(to: NSPoint(
            x: crease.0.0 * s - off,
            y: (1 - crease.0.1) * s + off
        ))
        line.line(to: NSPoint(
            x: crease.1.0 * s - off,
            y: (1 - crease.1.1) * s + off
        ))
        line.lineWidth = s * 0.006
        line.lineCapStyle = .round
        line.stroke()
    }

    NSGraphicsContext.restoreGraphicsState()

    // 6. Ink scribble in upper-left of paper (only at 64+)
    if size >= 64 {
        NSGraphicsContext.saveGraphicsState()
        paperPath.addClip()
        inkColor.setStroke()
        let ink = NSBezierPath()
        ink.move(to: pt(0.30, 0.34, size: s))
        ink.curve(
            to: pt(0.40, 0.36, size: s),
            controlPoint1: pt(0.33, 0.31, size: s),
            controlPoint2: pt(0.37, 0.34, size: s)
        )
        ink.curve(
            to: pt(0.43, 0.41, size: s),
            controlPoint1: pt(0.42, 0.37, size: s),
            controlPoint2: pt(0.43, 0.39, size: s)
        )
        ink.lineWidth = s * 0.011
        ink.lineCapStyle = .round
        ink.lineJoinStyle = .round
        ink.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }

    NSGraphicsContext.restoreGraphicsState() // bg clip
    NSGraphicsContext.restoreGraphicsState() // saveGraphicsState top

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
