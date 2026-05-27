import Foundation

enum NASAError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "NASA returned an invalid response."
        case let .httpError(code):
            "NASA returned HTTP \(code)."
        case let .decoding(error):
            "NASA response decoding failed: \(error.localizedDescription)"
        }
    }
}

/// NASA Image and Video Library client. No API key required for
/// low-volume use. The search endpoint returns metadata only, so we
/// batch-fetch each hit's asset manifest in parallel (TaskGroup) to
/// resolve playable MP4 URLs. The fully resolved items are cached for
/// 24h so repeat searches don't re-run all the manifest fetches.
struct NASAClient {
    static let searchEndpoint = "https://images-api.nasa.gov/search"

    func search(query: String) async throws -> [GalleryItem] {
        if let cached = GalleryCache.fetch(source: .nasa, query: query) {
            return cached
        }

        // Step 1: search for video metadata.
        var components = URLComponents(string: Self.searchEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "media_type", value: "video"),
        ]
        guard let url = components.url else {
            throw NASAError.invalidResponse
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw NASAError.invalidResponse
        }
        guard http.statusCode == 200 else {
            throw NASAError.httpError(http.statusCode)
        }

        let searchResult: NASASearchResponse
        do {
            searchResult = try JSONDecoder().decode(
                NASASearchResponse.self, from: data
            )
        } catch {
            throw NASAError.decoding(error)
        }

        // First 20 to match the other sources' page size.
        let metadata = Array(searchResult.collection.items.prefix(20))

        // Step 2: resolve asset URLs in parallel. Items that can't be
        // resolved (non-standard naming, no MP4) are dropped silently.
        let items = await withTaskGroup(of: GalleryItem?.self) { group in
            for entry in metadata {
                group.addTask { await Self.resolveAsset(entry: entry) }
            }
            var resolved: [GalleryItem] = []
            for await item in group {
                if let item { resolved.append(item) }
            }
            return resolved
        }

        GalleryCache.store(items, source: .nasa, query: query)
        return items
    }

    /// Resolve one search hit into a GalleryItem by fetching its asset
    /// manifest. Returns nil if the asset has no usable MP4 URLs.
    private static func resolveAsset(
        entry: NASACollectionItem
    ) async -> GalleryItem? {
        guard let meta = entry.data.first,
              let manifestURL = URL(string: entry.href) else { return nil }

        guard let (manifestData, _) = try? await URLSession.shared
            .data(from: manifestURL),
            let manifest = try? JSONDecoder().decode(
                NASAAssetManifest.self, from: manifestData
            ) else { return nil }

        let allURLs = manifest.collection.items
            .compactMap(\.href)
            .compactMap { URL(string: $0) }
        let mp4URLs = allURLs.filter {
            $0.pathExtension.lowercased() == "mp4"
        }
        let imageURLs = allURLs.filter {
            ["jpg", "jpeg", "png"].contains($0.pathExtension.lowercased())
        }

        func mp4(_ marker: String) -> URL? {
            mp4URLs.first { $0.lastPathComponent.contains(marker) }
        }

        // Never use ~orig (can be hundreds of MB to multiple GB).
        let small = mp4("~small") ?? mp4("~medium")
        let large = mp4("~large") ?? mp4("~medium") ?? small
        guard let preview = small ?? large,
              let download = large ?? small else { return nil }

        let thumbnail = imageURLs.first {
            let name = $0.lastPathComponent
            return name.contains("~thumb") || name.contains("~preview")
        } ?? imageURLs.first ?? preview

        let attribution = GalleryAttribution(
            creatorName: meta.photographer ?? "NASA",
            creatorURL: URL(string: "https://www.nasa.gov/"),
            sourceName: "NASA",
            sourceURL: URL(string: "https://images.nasa.gov/")!
        )

        let page = URL(
            string: "https://images.nasa.gov/details/\(meta.nasaID)"
        ) ?? URL(string: "https://images.nasa.gov/")!

        return GalleryItem(
            id: "nasa-\(meta.nasaID)",
            source: .nasa,
            title: meta.title ?? "NASA Video",
            tags: meta.keywords ?? [],
            thumbnailURL: thumbnail,
            previewVideoURL: preview,
            downloadVideoURL: download,
            width: 1920, // NASA doesn't reliably expose dimensions
            height: 1080,
            duration: 0, // not in NASA metadata
            attribution: attribution,
            pageURL: page
        )
    }
}

// MARK: - NASA JSON shapes

private struct NASASearchResponse: Decodable {
    let collection: NASASearchCollection
}

private struct NASASearchCollection: Decodable {
    let items: [NASACollectionItem]
}

private struct NASACollectionItem: Decodable {
    let href: String
    let data: [NASAItemData]
}

private struct NASAItemData: Decodable {
    let nasaID: String
    let title: String?
    let description: String?
    let keywords: [String]?
    let photographer: String?
    let mediaType: String?

    private enum CodingKeys: String, CodingKey {
        case title, description, keywords, photographer
        case nasaID = "nasa_id"
        case mediaType = "media_type"
    }
}

private struct NASAAssetManifest: Decodable {
    let collection: NASAAssetCollection
}

private struct NASAAssetCollection: Decodable {
    let items: [NASAAssetItem]
}

private struct NASAAssetItem: Decodable {
    let href: String?
}
