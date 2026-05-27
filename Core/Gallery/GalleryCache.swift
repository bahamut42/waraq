import CryptoKit
import Foundation

struct CachedGalleryResults: Codable {
    let timestamp: Date
    let items: [GalleryItem]
}

/// 24h on-disk JSON cache for gallery search results, keyed by
/// source + query. Required by Pixabay's terms (results must
/// not be refetched aggressively). Files live in
/// ~/Library/Caches/Waraq/gallery/.
enum GalleryCache {
    private static let maxAge: TimeInterval = 24 * 60 * 60 // 24h

    private static var cacheDirectory: URL? {
        let fm = FileManager.default
        guard let caches = fm.urls(
            for: .cachesDirectory, in: .userDomainMask
        ).first else { return nil }
        let dir = caches
            .appendingPathComponent("Waraq")
            .appendingPathComponent("gallery")
        try? fm.createDirectory(
            at: dir, withIntermediateDirectories: true
        )
        return dir
    }

    static func fetch(
        source: GallerySource, query: String
    ) -> [GalleryItem]? {
        guard let url = cacheFileURL(source: source, query: query),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let cached = try? decoder.decode(
            CachedGalleryResults.self, from: data
        ) else { return nil }
        guard Date().timeIntervalSince(cached.timestamp) < maxAge else {
            return nil
        }
        return cached.items
    }

    static func store(
        _ items: [GalleryItem],
        source: GallerySource,
        query: String
    ) {
        guard let url = cacheFileURL(source: source, query: query) else {
            return
        }
        let cached = CachedGalleryResults(
            timestamp: Date(), items: items
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        guard let data = try? encoder.encode(cached) else { return }
        try? data.write(to: url)
    }

    private static func cacheFileURL(
        source: GallerySource, query: String
    ) -> URL? {
        guard let dir = cacheDirectory else { return nil }
        let normalized = query.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let hashInput = "\(source.rawValue):\(normalized)"
        let hash = Insecure.MD5.hash(
            data: hashInput.data(using: .utf8) ?? Data()
        )
        let hashString = hash.map {
            String(format: "%02hhx", $0)
        }.joined()
        return dir.appendingPathComponent(
            "\(source.rawValue)-\(hashString).json"
        )
    }
}
