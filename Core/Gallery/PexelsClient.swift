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
import os

enum PexelsError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(Int, rawResponse: String?)
    case decoding(Error, rawResponse: String?)
    case noPlayableFile

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Pexels API key is missing."
        case .invalidResponse:
            "Pexels returned an invalid response."
        case let .httpError(code, raw):
            GalleryErrorText.http("Pexels", code: code, raw: raw)
        case let .decoding(error, raw):
            GalleryErrorText.decoding("Pexels", error: error, raw: raw)
        case .noPlayableFile:
            "Pexels returned a video with no MP4 file."
        }
    }
}

/// Async wrapper around the Pexels Videos API. Sibling to
/// PixabayClient — same interface, same 24h GalleryCache, which keeps
/// us well under Pexels' free-tier limit (200 req/hr).
struct PexelsClient {
    static let endpoint = "https://api.pexels.com/videos/search"

    func search(query: String) async throws -> [GalleryItem] {
        if let cached = GalleryCache.fetch(
            source: .pexels, query: query
        ) {
            return cached
        }
        guard let key = APIKeyStore.key(for: .pexels) else {
            throw PexelsError.missingAPIKey
        }

        var components = URLComponents(string: Self.endpoint)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "20"),
        ]

        guard let url = components.url else {
            throw PexelsError.invalidResponse
        }

        var request = URLRequest(url: url)
        // Pexels uses the Authorization header with the raw key
        // (no "Bearer" prefix — unusual, but per Pexels docs).
        request.setValue(key, forHTTPHeaderField: "Authorization")

        Logger.gallery.info(
            "Pexels search: query=\(query, privacy: .public) url=\(url.absoluteString, privacy: .public)"
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PexelsError.invalidResponse
        }
        Logger.gallery.info(
            "Pexels HTTP \(http.statusCode, privacy: .public) bytes=\(data.count, privacy: .public)"
        )
        guard http.statusCode == 200 else {
            let raw = GalleryErrorText.rawSnippet(data)
            Logger.gallery.error(
                "Pexels HTTP \(http.statusCode, privacy: .public) raw=\(raw ?? "<none>", privacy: .public)"
            )
            throw PexelsError.httpError(http.statusCode, rawResponse: raw)
        }

        do {
            let decoded = try JSONDecoder().decode(
                PexelsResponse.self, from: data
            )
            let items = decoded.videos.compactMap { $0.toGalleryItem() }
            Logger.gallery.info(
                "Pexels decoded \(items.count, privacy: .public) items"
            )
            GalleryCache.store(
                items, source: .pexels, query: query
            )
            return items
        } catch {
            let raw = GalleryErrorText.rawSnippet(data)
            Logger.gallery.error(
                "Pexels decode failed: \(error.localizedDescription, privacy: .public) raw=\(raw ?? "<none>", privacy: .public)"
            )
            throw PexelsError.decoding(error, rawResponse: raw)
        }
    }
}

// MARK: - Pexels JSON shape

private struct PexelsResponse: Decodable {
    let videos: [PexelsVideo]
}

private struct PexelsVideo: Decodable {
    let id: Int
    let width: Int
    let height: Int
    let duration: Int
    let image: String
    let user: PexelsUser
    let videoFiles: [PexelsVideoFile]
    let url: String

    private enum CodingKeys: String, CodingKey {
        case id, width, height, duration, image, user, url
        case videoFiles = "video_files"
    }

    func toGalleryItem() -> GalleryItem? {
        // `quality` is null for every entry in current Pexels responses,
        // so selection is width-based. MP4 files: accept file_type
        // containing "mp4", or a nil file_type whose link ends in .mp4.
        let mp4Files = videoFiles.filter { file in
            if let type = file.fileType, type.contains("mp4") { return true }
            return file.link.lowercased().hasSuffix(".mp4")
        }
        guard !mp4Files.isEmpty,
              let thumb = URL(string: image),
              let page = URL(string: url) else { return nil }

        let sorted = mp4Files.sorted { $0.width < $1.width }

        // Preview: smallest at/above 540px wide (skip tiny mobile
        // sizes); fall back to the smallest available.
        let preview = sorted.first { $0.width >= 540 } ?? sorted[0]

        // Download: largest at/below 1920px (FHD), avoiding 4K to keep
        // file sizes sane; fall back to widest below 2160, then widest.
        let download = sorted.last { $0.width <= 1920 }
            ?? sorted.last { $0.width < 2160 }
            ?? sorted[sorted.count - 1]

        guard let previewURL = URL(string: preview.link),
              let downloadURL = URL(string: download.link) else { return nil }

        let attribution = GalleryAttribution(
            creatorName: user.name,
            creatorURL: URL(string: user.url),
            sourceName: "Pexels",
            sourceURL: URL(string: "https://www.pexels.com/")!
        )

        return GalleryItem(
            id: "pexels-\(id)",
            source: .pexels,
            title: titleFromURL(url),
            tags: [], // Pexels doesn't return tags
            thumbnailURL: thumb,
            previewVideoURL: previewURL,
            downloadVideoURL: downloadURL,
            width: download.width,
            height: download.height,
            duration: duration,
            attribution: attribution,
            pageURL: page
        )
    }

    private func titleFromURL(_ raw: String) -> String {
        // Pexels URLs look like:
        // https://www.pexels.com/video/aurora-over-mountains-1234567/
        // Extract the slug, drop the trailing id, humanize.
        guard let url = URL(string: raw) else { return "Pexels Video" }
        let parts = url.pathComponents.filter { !$0.isEmpty }
        guard let slug = parts.last else { return "Pexels Video" }
        let cleaned = slug
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: CharacterSet.decimalDigits)
            .first ?? slug
        let trimmed = cleaned.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Pexels Video" : trimmed.capitalized
    }
}

private struct PexelsUser: Decodable {
    let id: Int
    let name: String
    let url: String
}

private struct PexelsVideoFile: Decodable {
    let id: Int
    let quality: String? // null for every entry in current API responses
    let fileType: String? // defensively optional
    let width: Int
    let height: Int
    let fps: Double? // present in current responses
    let link: String
    let size: Int? // present in current responses

    private enum CodingKeys: String, CodingKey {
        case id, quality, width, height, fps, link, size
        case fileType = "file_type"
    }
}
