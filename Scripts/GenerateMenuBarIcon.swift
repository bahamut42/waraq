#!/usr/bin/swift
import AppKit
import Foundation

let outputDir = "Resources/Assets.xcassets/MenuBarIcon.imageset"
let sizes: [(filename: String, pixels: Int)] = [
    ("menubar.png", 22),
    ("menubar@2x.png", 44),
]

/// Crumpled silhouette - 14 vertices, irregular polygon reading
/// as crumpled paper at 22px. Normalized 0..1, y from top.
let outline: [(CGFloat, CGFloat)] = [
    (0.18, 0.30),
    (0.32, 0.10),
    (0.50, 0.16),
    (0.66, 0.08),
    (0.84, 0.22),
    (0.90, 0.42),
    (0.82, 0.56),
    (0.92, 0.72),
    (0.78, 0.90),
    (0.56, 0.86),
    (0.40, 0.92),
    (0.20, 0.86),
    (0.10, 0.66),
    (0.16, 0.48),
]

/// One internal crease line, only drawn at 44px where it's visible
let crease: ((CGFloat, CGFloat), (CGFloat, CGFloat)) =
    ((0.30, 0.28), (0.72, 0.66))

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

func pt(_ x: CGFloat, _ y: CGFloat, size s: CGFloat) -> NSPoint {
    NSPoint(x: x * s, y: (1 - y) * s)
}

func drawIcon(size: Int) -> NSBitmapImageRep? {
    guard let (rep, ctx) = makeContext(size: size) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    let s = CGFloat(size)

    // Solid black template
    NSColor.black.setFill()

    let path = NSBezierPath()
    path.move(to: pt(outline[0].0, outline[0].1, size: s))
    for vertex in outline.dropFirst() {
        path.line(to: pt(vertex.0, vertex.1, size: s))
    }
    path.close()
    path.fill()

    // At 44px, knock out a thin crease line to suggest fold
    if size >= 44 {
        // Punch a thin transparent crease through the filled
        // silhouette via destination-out so the tinted template
        // shows a fold line.
        ctx.cgContext.setBlendMode(.destinationOut)
        let creasePath = NSBezierPath()
        creasePath.move(to: pt(crease.0.0, crease.0.1, size: s))
        creasePath.line(to: pt(crease.1.0, crease.1.1, size: s))
        creasePath.lineWidth = s * 0.04
        creasePath.lineCapStyle = .round
        NSColor.black.setStroke()
        creasePath.stroke()
        ctx.cgContext.setBlendMode(.normal)
    }

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
