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
}
