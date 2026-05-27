import XCTest
@testable import Waraq

/// Phase 9.8a — Gallery cache + API key store.
/// Kept in its own file so WaraqTests stays under the
/// type_body_length limit.
final class GalleryTests: XCTestCase {
    func testGalleryCacheRoundTrip() throws {
        let attribution = try GalleryAttribution(
            creatorName: "TestUser",
            creatorURL: URL(string: "https://example.com/user"),
            sourceName: "Pixabay",
            sourceURL: XCTUnwrap(URL(string: "https://pixabay.com"))
        )
        let item = try GalleryItem(
            id: "pixabay-test-\(UUID().uuidString)",
            source: .pixabay,
            title: "Aurora",
            tags: ["aurora", "lights"],
            thumbnailURL: XCTUnwrap(URL(string: "https://cdn.example.com/thumb.jpg")),
            previewVideoURL: XCTUnwrap(URL(string: "https://cdn.example.com/medium.mp4")),
            downloadVideoURL: XCTUnwrap(URL(string: "https://cdn.example.com/large.mp4")),
            width: 1920, height: 1080, duration: 30,
            attribution: attribution,
            pageURL: XCTUnwrap(URL(string: "https://pixabay.com/videos/aurora"))
        )

        // Unique query so we don't collide with other test runs.
        let query = "test-aurora-\(UUID().uuidString)"

        GalleryCache.store([item], source: .pixabay, query: query)
        let fetched = GalleryCache.fetch(source: .pixabay, query: query)

        XCTAssertNotNil(fetched, "Cache should return stored items")
        XCTAssertEqual(fetched?.count, 1)
        XCTAssertEqual(fetched?.first?.id, item.id)
        XCTAssertEqual(fetched?.first?.title, "Aurora")
    }

    func testAPIKeyStoreRoundTrip() {
        // Preserve any real key Omar may have configured, and
        // restore it afterwards so the test never clobbers it.
        let existing = APIKeyStore.key(for: .pixabay)
        defer { APIKeyStore.setKey(existing, for: .pixabay) }

        let testKey = "test-key-\(UUID().uuidString)"
        APIKeyStore.setKey(testKey, for: .pixabay)
        XCTAssertEqual(APIKeyStore.key(for: .pixabay), testKey)
        XCTAssertTrue(APIKeyStore.hasKey(for: .pixabay))

        APIKeyStore.setKey(nil, for: .pixabay)
        XCTAssertNil(APIKeyStore.key(for: .pixabay))
        XCTAssertFalse(APIKeyStore.hasKey(for: .pixabay))

        // Whitespace-only input is treated as no key.
        APIKeyStore.setKey("   ", for: .pixabay)
        XCTAssertNil(APIKeyStore.key(for: .pixabay))
    }

    // MARK: Phase 9.8b — multi-source

    func testGalleryCacheSeparatesByCacheKey() {
        // Storing the same query under different sources should
        // produce independent cache entries.
        let pixabayItem = makeTestItem(source: .pixabay, idSuffix: "px")
        let pexelsItem = makeTestItem(source: .pexels, idSuffix: "px")
        let query = "test-cache-isolation-\(UUID().uuidString)"

        GalleryCache.store([pixabayItem], source: .pixabay, query: query)
        GalleryCache.store([pexelsItem], source: .pexels, query: query)

        let pixabayFetched = GalleryCache.fetch(source: .pixabay, query: query)
        let pexelsFetched = GalleryCache.fetch(source: .pexels, query: query)

        XCTAssertEqual(pixabayFetched?.first?.source, .pixabay)
        XCTAssertEqual(pexelsFetched?.first?.source, .pexels)
        XCTAssertNotEqual(
            pixabayFetched?.first?.id, pexelsFetched?.first?.id
        )
    }

    func testGallerySourceImplementedFlag() {
        XCTAssertTrue(GallerySource.pixabay.isImplemented)
        XCTAssertTrue(GallerySource.pexels.isImplemented)
        XCTAssertTrue(GallerySource.nasa.isImplemented)
    }

    func testGallerySourceHasNoCoverr() {
        // Coverr was removed in Phase 9.10; three sources remain.
        XCTAssertEqual(GallerySource.allCases.count, 3)
        XCTAssertEqual(
            Set(GallerySource.allCases.map(\.rawValue)),
            ["pixabay", "pexels", "nasa"]
        )
    }

    func testNASARequiresNoAPIKey() {
        // NASA's apiKeySignupURL is nil and it doesn't require a key.
        XCTAssertNil(GallerySource.nasa.apiKeySignupURL)
        XCTAssertFalse(GallerySource.nasa.requiresAPIKey)
        XCTAssertTrue(GallerySource.pixabay.requiresAPIKey)
    }

    func testNASAIDPercentEncodingEscapesSpaces() {
        // nasa_ids with spaces must encode for path use, or the
        // constructed MP4 URLs are invalid.
        let testID = "Seeing Earth as Only NASA Can"
        let encoded = testID.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        )
        XCTAssertEqual(encoded, "Seeing%20Earth%20as%20Only%20NASA%20Can")
    }

    func testPexelsDecodesNullQuality() throws {
        // Real Pexels responses return quality: null for every file.
        // Decoding must not throw on that.
        let json = """
        {
          "videos": [
            {
              "id": 25961000, "width": 2160, "height": 3840,
              "duration": 2, "tags": [],
              "url": "https://www.pexels.com/video/test-25961000/",
              "image": "https://images.pexels.com/videos/25961000/test.jpeg",
              "user": {
                "id": 1, "name": "Nisasu",
                "url": "https://www.pexels.com/@nisasu"
              },
              "video_files": [
                {
                  "id": 1, "quality": null, "file_type": "video/mp4",
                  "width": 720, "height": 1280, "fps": 60.0,
                  "link": "https://videos.pexels.com/test-720.mp4",
                  "size": 100
                }
              ]
            }
          ]
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        XCTAssertNoThrow(
            try JSONDecoder().decode(PexelsProbe.self, from: data),
            "Pexels payload with null quality must decode"
        )
    }

    private func makeTestItem(
        source: GallerySource, idSuffix: String
    ) -> GalleryItem {
        let attribution = GalleryAttribution(
            creatorName: "Test",
            creatorURL: URL(string: "https://example.com"),
            sourceName: source.displayName,
            sourceURL: source.websiteURL
        )
        return GalleryItem(
            id: "\(source.rawValue)-\(idSuffix)",
            source: source,
            title: "Test", tags: [],
            thumbnailURL: URL(string: "https://example.com/t.jpg")!,
            previewVideoURL: URL(string: "https://example.com/p.mp4")!,
            downloadVideoURL: URL(string: "https://example.com/d.mp4")!,
            width: 1920, height: 1080, duration: 10,
            attribution: attribution,
            pageURL: URL(string: "https://example.com/page")!
        )
    }
}

// MARK: - Pexels schema contract

/// Mirrors PexelsClient's private response shape (which can't be
/// reached from tests) to guard the field optionality that the live
/// API requires — chiefly `quality` being null on every file. If the
/// real structs drift from this, the client breaks; this catches it.
private struct PexelsProbe: Decodable {
    let videos: [Video]

    struct Video: Decodable {
        let id: Int
        let width: Int
        let height: Int
        let duration: Int
        let image: String
        let url: String
        let videoFiles: [File]

        private enum CodingKeys: String, CodingKey {
            case id, width, height, duration, image, url
            case videoFiles = "video_files"
        }
    }

    struct File: Decodable {
        let id: Int
        let quality: String?
        let fileType: String?
        let width: Int
        let height: Int
        let fps: Double?
        let link: String
        let size: Int?

        private enum CodingKeys: String, CodingKey {
            case id, quality, width, height, fps, link, size
            case fileType = "file_type"
        }
    }
}
