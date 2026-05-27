//  Waraq - A native macOS animated wallpaper app.
//  Copyright (C) 2026 Omar A. Othman
//
//  This program is free software: you can redistribute it
//  and/or modify it under the terms of the GNU General
//  Public License as published by the Free Software
//  Foundation, either version 3 of the License, or (at
//  your option) any later version.
//
//  This program is distributed in the hope that it will
//  be useful, but WITHOUT ANY WARRANTY; without even the
//  implied warranty of MERCHANTABILITY or FITNESS FOR A
//  PARTICULAR PURPOSE. See the GNU General Public License
//  for more details.
//
//  You should have received a copy of the GNU General
//  Public License along with this program. If not, see
//  <https://www.gnu.org/licenses/>.
//

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
