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

import Foundation

struct GalleryItem: Identifiable, Codable, Hashable {
    let id: String // "pixabay-125"
    let source: GallerySource
    let title: String
    let tags: [String]
    let thumbnailURL: URL
    let previewVideoURL: URL // medium quality for preview
    let downloadVideoURL: URL // large quality for permanent
    let width: Int
    let height: Int
    let duration: Int // seconds
    let attribution: GalleryAttribution
    let pageURL: URL // link back to the original on the source

    var aspectRatio: CGFloat {
        guard height > 0 else { return 16.0 / 9.0 }
        return CGFloat(width) / CGFloat(height)
    }

    var durationString: String {
        if duration < 60 { return "\(duration)s" }
        let minutes = duration / 60
        let seconds = duration % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    var resolutionString: String {
        "\(width)x\(height)"
    }
}
