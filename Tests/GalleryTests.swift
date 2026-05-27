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
        XCTAssertTrue(GallerySource.coverr.isImplemented)
        XCTAssertFalse(GallerySource.nasa.isImplemented)
    }

    func testCoverrSourceMarkedImplemented() {
        XCTAssertTrue(GallerySource.coverr.isImplemented)
    }

    func testCoverrCacheRoundTrip() throws {
        let item = try GalleryItem(
            id: "coverr-test-\(UUID().uuidString)",
            source: .coverr,
            title: "Test",
            tags: ["nature"],
            thumbnailURL: XCTUnwrap(URL(string: "https://example.com/t.jpg")),
            previewVideoURL: XCTUnwrap(URL(string: "https://example.com/p.mp4")),
            downloadVideoURL: XCTUnwrap(URL(string: "https://example.com/d.mp4")),
            width: 1920, height: 1080, duration: 15,
            attribution: GalleryAttribution(
                creatorName: "Test",
                creatorURL: nil,
                sourceName: "Coverr",
                sourceURL: XCTUnwrap(URL(string: "https://coverr.co/"))
            ),
            pageURL: XCTUnwrap(URL(string: "https://coverr.co/videos/abc"))
        )
        let query = "test-coverr-\(UUID().uuidString)"
        GalleryCache.store([item], source: .coverr, query: query)
        let fetched = GalleryCache.fetch(source: .coverr, query: query)
        XCTAssertEqual(fetched?.first?.source, .coverr)
        XCTAssertEqual(fetched?.first?.id, item.id)
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
