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

struct Wallpaper: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let kind: Kind
    let addedDate: Date
    let relativePath: String?
    let urlString: String?
    let proceduralKey: String?
    var fileSizeBytes: Int64?

    enum Kind: String, Codable {
        case builtInGradient
        case procedural
        case video
        case gif
        case gifURL
        case image
        case url // DEPRECATED: filtered on load, never spawned

        /// True for SwiftUI-rendered procedural built-ins, whose
        /// thumbnails are captured offscreen rather than from a file.
        var isProcedural: Bool {
            self == .procedural
        }
    }

    init(
        id: String,
        name: String,
        kind: Kind,
        addedDate: Date,
        relativePath: String? = nil,
        urlString: String? = nil,
        proceduralKey: String? = nil,
        fileSizeBytes: Int64? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.addedDate = addedDate
        self.relativePath = relativePath
        self.urlString = urlString
        self.proceduralKey = proceduralKey
        self.fileSizeBytes = fileSizeBytes
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, kind, addedDate, relativePath, urlString,
             proceduralKey, fileSizeBytes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        kind = try c.decode(Kind.self, forKey: .kind)
        addedDate = try c.decode(Date.self, forKey: .addedDate)
        relativePath = try c.decodeIfPresent(String.self, forKey: .relativePath)
        urlString = try c.decodeIfPresent(String.self, forKey: .urlString)
        proceduralKey = try c.decodeIfPresent(String.self, forKey: .proceduralKey)
        fileSizeBytes = try c.decodeIfPresent(Int64.self, forKey: .fileSizeBytes)
    }

    var fileSizeString: String? {
        guard let bytes = fileSizeBytes else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    var urlHost: String? {
        guard let urlString,
              let url = URL(string: urlString),
              let host = url.host else { return nil }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}

enum WallpaperImportError: LocalizedError {
    case unsupportedFormat(String)
    case copyFailed(Error)
    case libraryUnavailable
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
        case let .unsupportedFormat(ext):
            "Unsupported file format: .\(ext). Try MP4, MOV, or M4V."
        case let .copyFailed(underlying):
            "Could not copy file to library: \(underlying.localizedDescription)"
        case .libraryUnavailable:
            "Library directory is not available."
        case let .invalidURL(str):
            "Not a valid URL: \(str)"
        }
    }
}
