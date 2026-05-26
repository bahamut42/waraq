import AppKit
import AVFoundation
import CoreImage

/// Generates JPG thumbnails for video and GIF files.
/// Phase 7 implementation.
enum ThumbnailGenerator {
    /// Generate a thumbnail and save to outputURL. Designed for
    /// background-task use (does its own file IO). No-op if
    /// generation fails.
    static func generate(
        fileURL: URL,
        isGif: Bool,
        outputURL: URL
    ) async {
        do {
            let nsImage: NSImage? = if isGif {
                gifFirstFrame(at: fileURL)
            } else {
                try await videoFirstFrame(at: fileURL)
            }
            guard let image = nsImage else { return }
            try save(image: image, to: outputURL)
        } catch {
            // Silent; thumbnails are nice-to-have.
        }
    }

    private static func videoFirstFrame(at url: URL) async throws -> NSImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 300)

        // Try a small offset rather than .zero (some videos have
        // black or near-black first frames).
        let cmTime = CMTime(seconds: 0.5, preferredTimescale: 600)
        let result = try await generator.image(at: cmTime)
        return NSImage(
            cgImage: result.image,
            size: NSSize(
                width: result.image.width,
                height: result.image.height
            )
        )
    }

    private static func gifFirstFrame(at url: URL) -> NSImage? {
        // NSImage initialized from a GIF file holds all frames.
        // We want only frame 0 as a static image.
        guard let data = try? Data(contentsOf: url),
              let rep = NSBitmapImageRep(data: data) else
        {
            return nil
        }
        rep.setProperty(.currentFrame, withValue: 0)
        let size = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        let image = NSImage(size: size)
        image.addRepresentation(rep)
        return image
    }

    private static func save(image: NSImage, to outputURL: URL) throws {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let jpegData = rep.representation(
                  using: .jpeg, properties: [
                      .compressionFactor: 0.85,
                  ]
              ) else { return }
        try jpegData.write(to: outputURL, options: .atomic)
    }
}
