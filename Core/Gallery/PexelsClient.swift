import Foundation

enum PexelsError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(Int)
    case decoding(Error)
    case noPlayableFile

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Pexels API key is missing."
        case .invalidResponse:
            "Pexels returned an invalid response."
        case let .httpError(code):
            "Pexels returned HTTP \(code)."
        case let .decoding(error):
            "Pexels response decoding failed: \(error.localizedDescription)"
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

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PexelsError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw PexelsError.httpError(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(
                PexelsResponse.self, from: data
            )
            let items = decoded.videos.compactMap { $0.toGalleryItem() }
            GalleryCache.store(
                items, source: .pexels, query: query
            )
            return items
        } catch {
            throw PexelsError.decoding(error)
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
        // MP4 files only; pick SD for preview, HD (not UHD) for download.
        let mp4Files = videoFiles.filter { $0.fileType == "video/mp4" }
        guard !mp4Files.isEmpty,
              let thumb = URL(string: image),
              let page = URL(string: url) else { return nil }

        let preview = mp4Files.first { $0.quality == "sd" } ?? mp4Files[0]

        // Prefer HD (~1080p); fall back to the widest non-UHD, then any.
        let hd = mp4Files.first { $0.quality == "hd" }
        let widestNonUHD = mp4Files
            .filter { $0.quality != "uhd" }
            .max { $0.width < $1.width }
        let download = hd ?? widestNonUHD ?? mp4Files[0]

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
    let quality: String
    let fileType: String
    let width: Int
    let height: Int
    let link: String

    private enum CodingKeys: String, CodingKey {
        case id, quality, width, height, link
        case fileType = "file_type"
    }
}
