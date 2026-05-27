import Foundation
import os

enum NASAError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int, rawResponse: String?)
    case decoding(Error, rawResponse: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "NASA returned an invalid response."
        case let .httpError(code, raw):
            GalleryErrorText.http("NASA", code: code, raw: raw)
        case let .decoding(error, raw):
            GalleryErrorText.decoding("NASA", error: error, raw: raw)
        }
    }
}

/// NASA Image and Video Library client. No API key required.
///
/// Strategy: skip the per-item asset-manifest fetch. The previous
/// version ran ~20 parallel manifest requests after each search and
/// silently dropped every item when URL extraction missed — producing
/// empty grids in production. Instead we construct MP4 URLs directly
/// from `nasa_id` using NASA's documented file-naming convention:
///
///   https://images-assets.nasa.gov/video/{id}/{id}~small.mp4
///   https://images-assets.nasa.gov/video/{id}/{id}~medium.mp4
///   https://images-assets.nasa.gov/video/{id}/{id}~large.mp4
///
/// The thumbnail comes from the search response's `links` array
/// (~thumb.jpg). Some nasa_ids contain spaces, so path components are
/// percent-encoded with .urlPathAllowed. One request per search.
struct NASAClient {
    static let searchEndpoint = "https://images-api.nasa.gov/search"
    private static let assetBase = "https://images-assets.nasa.gov/video"

    func search(query: String) async throws -> [GalleryItem] {
        if let cached = GalleryCache.fetch(source: .nasa, query: query) {
            return cached
        }

        var components = URLComponents(string: Self.searchEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "media_type", value: "video"),
        ]
        guard let url = components.url else {
            throw NASAError.invalidResponse
        }

        Logger.gallery.info(
            "NASA search: query=\(query, privacy: .public) url=\(url.absoluteString, privacy: .public)"
        )

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw NASAError.invalidResponse
        }
        Logger.gallery.info(
            "NASA HTTP \(http.statusCode, privacy: .public) bytes=\(data.count, privacy: .public)"
        )
        guard http.statusCode == 200 else {
            let raw = GalleryErrorText.rawSnippet(data)
            Logger.gallery.error(
                "NASA HTTP \(http.statusCode, privacy: .public) raw=\(raw ?? "<none>", privacy: .public)"
            )
            throw NASAError.httpError(http.statusCode, rawResponse: raw)
        }

        let searchResult: NASASearchResponse
        do {
            searchResult = try JSONDecoder().decode(
                NASASearchResponse.self, from: data
            )
        } catch {
            let raw = GalleryErrorText.rawSnippet(data)
            Logger.gallery.error(
                "NASA decode failed: \(error.localizedDescription, privacy: .public) raw=\(raw ?? "<none>", privacy: .public)"
            )
            throw NASAError.decoding(error, rawResponse: raw)
        }

        let items = searchResult.collection.items
            .prefix(20)
            .compactMap { Self.makeItem(from: $0) }

        Logger.gallery.info(
            "NASA built \(items.count, privacy: .public) of \(searchResult.collection.items.count, privacy: .public) hits"
        )
        let result = Array(items)
        GalleryCache.store(result, source: .nasa, query: query)
        return result
    }

    /// Build a GalleryItem from a search entry by predicting its MP4
    /// URLs from nasa_id. Returns nil only if the id can't be encoded.
    private static func makeItem(
        from entry: NASACollectionItem
    ) -> GalleryItem? {
        guard let meta = entry.data.first else { return nil }
        let nasaID = meta.nasaID
        guard let encoded = nasaID.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) else { return nil }

        let folder = "\(assetBase)/\(encoded)"
        let smallMP4 = "\(folder)/\(encoded)~small.mp4"
        let mediumMP4 = "\(folder)/\(encoded)~medium.mp4"
        let largeMP4 = "\(folder)/\(encoded)~large.mp4"

        // Thumbnail: prefer the entry's links (~thumb/~preview image),
        // else the predicted ~thumb.jpg.
        let thumbFromLinks = entry.links?.first { link in
            let isImage = link.render == "image" || link.rel == "preview"
            let lower = link.href.lowercased()
            return isImage
                && (lower.contains("~thumb") || lower.contains("~preview"))
        }?.href
        let predictedThumb = "\(folder)/\(encoded)~thumb.jpg"

        guard let thumbnailURL = URL(
            string: thumbFromLinks ?? predictedThumb
        ),
            let previewURL = URL(string: smallMP4) ?? URL(string: mediumMP4),
            let downloadURL = URL(string: largeMP4) ?? URL(string: mediumMP4) else { return nil }

        let attribution = GalleryAttribution(
            creatorName: meta.secondaryCreator ?? meta.center ?? "NASA",
            creatorURL: URL(string: "https://www.nasa.gov/"),
            sourceName: "NASA",
            sourceURL: URL(string: "https://images.nasa.gov/")!
        )

        let page = URL(string: "https://images.nasa.gov/details/\(encoded)")
            ?? URL(string: "https://images.nasa.gov/")!

        return GalleryItem(
            id: "nasa-\(nasaID)",
            source: .nasa,
            title: meta.title ?? "NASA Video",
            tags: meta.keywords ?? [],
            thumbnailURL: thumbnailURL,
            previewVideoURL: previewURL,
            downloadVideoURL: downloadURL,
            width: 1920, // NASA doesn't expose dimensions reliably
            height: 1080,
            duration: 0, // not in search metadata
            attribution: attribution,
            pageURL: page
        )
    }
}

// MARK: - NASA JSON shape

private struct NASASearchResponse: Decodable {
    let collection: NASASearchCollection
}

private struct NASASearchCollection: Decodable {
    let items: [NASACollectionItem]
}

private struct NASACollectionItem: Decodable {
    let href: String
    let data: [NASAItemData]
    let links: [NASALink]?
}

private struct NASAItemData: Decodable {
    let nasaID: String
    let title: String?
    let description: String?
    let keywords: [String]?
    let mediaType: String?
    let center: String?
    let secondaryCreator: String?
    let dateCreated: String?

    private enum CodingKeys: String, CodingKey {
        case title, description, keywords, center
        case nasaID = "nasa_id"
        case mediaType = "media_type"
        case secondaryCreator = "secondary_creator"
        case dateCreated = "date_created"
    }
}

private struct NASALink: Decodable {
    let href: String
    let rel: String?
    let render: String?
}
