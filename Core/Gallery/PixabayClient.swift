import Foundation

enum PixabayError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Pixabay API key is missing."
        case .invalidResponse:
            "Pixabay returned an invalid response."
        case let .httpError(code):
            "Pixabay returned HTTP \(code)."
        case let .decoding(error):
            "Pixabay response decoding failed: \(error.localizedDescription)"
        }
    }
}

/// Stateless wrapper around the Pixabay Videos API.
/// Uses GalleryCache for 24h response caching per Pixabay's
/// terms.
struct PixabayClient {
    static let host = "https://pixabay.com/api/videos/"

    /// Search Pixabay videos. Checks cache first, falls
    /// back to network if cache miss.
    func search(query: String) async throws -> [GalleryItem] {
        if let cached = GalleryCache.fetch(
            source: .pixabay, query: query
        ) {
            return cached
        }
        guard let key = APIKeyStore.key(for: .pixabay) else {
            throw PixabayError.missingAPIKey
        }

        var components = URLComponents(string: Self.host)!
        components.queryItems = [
            URLQueryItem(name: "key", value: key),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "per_page", value: "20"),
            URLQueryItem(name: "safesearch", value: "true"),
            URLQueryItem(name: "video_type", value: "film"),
        ]

        guard let url = components.url else {
            throw PixabayError.invalidResponse
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw PixabayError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw PixabayError.httpError(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(
                PixabayResponse.self, from: data
            )
            let items = decoded.hits.compactMap { $0.toGalleryItem() }
            GalleryCache.store(
                items, source: .pixabay, query: query
            )
            return items
        } catch {
            throw PixabayError.decoding(error)
        }
    }
}

// MARK: - Pixabay JSON shape

private struct PixabayResponse: Decodable {
    let hits: [PixabayHit]
}

private struct PixabayHit: Decodable {
    let id: Int
    let pageURL: String
    let tags: String
    let duration: Int
    let videos: PixabayVideos
    let user: String
    let userID: Int

    private enum CodingKeys: String, CodingKey {
        case id, pageURL, tags, duration, videos, user
        case userID = "user_id"
    }

    var attributionPageURL: URL? {
        URL(string: "https://pixabay.com/users/\(user)-\(userID)/")
    }

    func toGalleryItem() -> GalleryItem? {
        guard let previewURL = URL(string: videos.medium.url),
              let downloadURL = URL(string: videos.large.url),
              let page = URL(string: pageURL) else { return nil }

        let thumbURL = URL(string: videos.large.thumbnail) ?? previewURL

        let attribution = GalleryAttribution(
            creatorName: user,
            creatorURL: attributionPageURL,
            sourceName: "Pixabay",
            sourceURL: URL(string: "https://pixabay.com/")!
        )
        return GalleryItem(
            id: "pixabay-\(id)",
            source: .pixabay,
            title: tagsAsTitle(),
            tags: tags.components(separatedBy: ", "),
            thumbnailURL: thumbURL,
            previewVideoURL: previewURL,
            downloadVideoURL: downloadURL,
            width: videos.large.width,
            height: videos.large.height,
            duration: duration,
            attribution: attribution,
            pageURL: page
        )
    }

    private func tagsAsTitle() -> String {
        let words = tags.components(separatedBy: ", ")
            .prefix(3)
            .joined(separator: " · ")
        return words.isEmpty ? "Pixabay Video" : words.capitalized
    }
}

private struct PixabayVideos: Decodable {
    let large: PixabayVariant
    let medium: PixabayVariant
}

private struct PixabayVariant: Decodable {
    let url: String
    let width: Int
    let height: Int
    let thumbnail: String
}
