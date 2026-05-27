import AppKit
import SwiftUI

enum ProceduralThumbnailError: Error, LocalizedError {
    case noProceduralViewForKind
    case renderingFailed
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .noProceduralViewForKind:
            "No procedural view exists for this wallpaper."
        case .renderingFailed:
            "ImageRenderer produced no image."
        case .encodingFailed:
            "Could not encode the procedural thumbnail as JPG."
        }
    }
}

/// Captures a still frame of a procedural wallpaper's SwiftUI view via
/// ImageRenderer (macOS 14+) and saves it as a JPG in the same
/// Thumbnails/ folder used for video/GIF thumbnails. The procedurals
/// animate off absolute time, so a single snapshot already shows
/// fully-developed content — no fixed-time injection needed.
@MainActor
enum ProceduralThumbnailGenerator {
    /// Matches the dimensions ThumbnailGenerator uses for video/GIF.
    static let thumbnailSize = CGSize(width: 480, height: 300)

    /// Generate a thumbnail for a procedural wallpaper. Returns the URL
    /// of the saved JPG (Thumbnails/{wallpaper.id}.jpg).
    @discardableResult
    static func generateThumbnail(
        for wallpaper: Wallpaper,
        in libraryFolder: URL
    ) throws -> URL {
        guard let key = wallpaper.proceduralKey,
              let content = ProceduralFactory.swiftUIView(for: key) else
        {
            throw ProceduralThumbnailError.noProceduralViewForKind
        }

        let view = content
            .frame(width: thumbnailSize.width, height: thumbnailSize.height)
            .background(Color.black)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0 // retina

        guard let nsImage = renderer.nsImage else {
            throw ProceduralThumbnailError.renderingFailed
        }

        guard let tiff = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let jpgData = bitmap.representation(
                  using: .jpeg, properties: [.compressionFactor: 0.85]
              ) else
        {
            throw ProceduralThumbnailError.encodingFailed
        }

        let thumbsDir = libraryFolder.appendingPathComponent("Thumbnails")
        try FileManager.default.createDirectory(
            at: thumbsDir, withIntermediateDirectories: true
        )
        let dest = thumbsDir.appendingPathComponent("\(wallpaper.id).jpg")
        try jpgData.write(to: dest, options: .atomic)
        return dest
    }
}
