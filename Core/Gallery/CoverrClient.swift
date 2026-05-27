import Foundation

enum CoverrError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Coverr API key is missing."
        case .invalidResponse:
            "Coverr returned an invalid response."
        case let .httpError(code):
            "Coverr returned HTTP \(code)."
        case let .decoding(error):
            "Coverr response decoding failed: \(error.localizedDescription)"
        }
    }
}

/// Async wrapper around the Coverr Videos API. Sibling to
/// PixabayClient/PexelsClient — same interface, same 24h
/// GalleryCache, which covers Coverr's free tier comfortably.
struct CoverrClient {
    static let endpoint = "https://api.coverr.co/videos"

    func search(query: String) async throws -> [GalleryItem] {
        if let cached = GalleryCache.fetch(
            source: .coverr, query: query
        ) {
            return cached
        }
        guard let key = APIKeyStore.key(for: .coverr) else {
            throw CoverrError.missingAPIKey
        }

        var components = URLComponents(string: Self.endpoint)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page_size", value: "20"),
        ]
        guard let url = components.url else {
            throw CoverrError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Bearer \(key)", forHTTPHeaderField: "Authorization"
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CoverrError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw CoverrError.httpError(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(
                CoverrResponse.self, from: data
            )
            let items = decoded.hits.compactMap { $0.toGalleryItem() }
            GalleryCache.store(
                items, source: .coverr, query: query
            )
            return items
        } catch {
            throw CoverrError.decoding(error)
        }
    }
}

// MARK: - Coverr JSON shape (per api.coverr.co/docs)

private struct CoverrResponse: Decodable {
    let hits: [CoverrHit]
}

private struct CoverrHit: Decodable {
    let id: String
    let title: String?
    let tags: [String]?
    let maxWidth: Int?
    let maxHeight: Int?
    let thumbnail: String
    let urls: CoverrURLs
    let duration: Int?
    let creator: CoverrCreator?

    private enum CodingKeys: String, CodingKey {
        case id, title, tags, thumbnail, urls, duration, creator
        case maxWidth = "max_width"
        case maxHeight = "max_height"
    }

    func toGalleryItem() -> GalleryItem? {
        // mp4 is the baseline; preview/download fall back to it.
        guard let baseURL = URL(string: urls.mp4),
              let thumb = URL(string: thumbnail) else { return nil }

        let preview = urls.mp4Preview.flatMap { URL(string: $0) } ?? baseURL
        let download = urls.mp4Download.flatMap { URL(string: $0) } ?? baseURL

        let attribution = GalleryAttribution(
            creatorName: creator?.name ?? "Coverr",
            creatorURL: creator?.url.flatMap { URL(string: $0) },
            sourceName: "Coverr",
            sourceURL: URL(string: "https://coverr.co/")!
        )

        let page = URL(string: "https://coverr.co/videos/\(id)")
            ?? URL(string: "https://coverr.co/")!

        return GalleryItem(
            id: "coverr-\(id)",
            source: .coverr,
            title: title ?? "Coverr Video",
            tags: tags ?? [],
            thumbnailURL: thumb,
            previewVideoURL: preview,
            downloadVideoURL: download,
            width: maxWidth ?? 1920,
            height: maxHeight ?? 1080,
            duration: duration ?? 0,
            attribution: attribution,
            pageURL: page
        )
    }
}

private struct CoverrURLs: Decodable {
    let mp4: String
    let mp4Preview: String?
    let mp4Download: String?

    private enum CodingKeys: String, CodingKey {
        case mp4
        case mp4Preview = "mp4_preview"
        case mp4Download = "mp4_download"
    }
}

private struct CoverrCreator: Decodable {
    let name: String
    let url: String?
}
