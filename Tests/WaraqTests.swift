import XCTest
@testable import Waraq

final class WaraqTests: XCTestCase {
    func testPhase0Placeholder() {
        XCTAssertTrue(true, "Phase 0 scaffold test.")
    }

    func testWallpaperManifestDecodes() throws {
        let json = """
        {
          "schema": 1,
          "id": "com.example.test",
          "name": "Test",
          "type": "video",
          "entry": "content/scene.mp4"
        }
        """.data(using: .utf8)!

        let manifest = try JSONDecoder().decode(
            WallpaperManifest.self, from: json
        )
        XCTAssertEqual(manifest.id, "com.example.test")
        XCTAssertEqual(manifest.type, .video)
    }
}
