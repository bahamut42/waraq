import AppKit
import AVFoundation
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

    @MainActor
    func testWallpaperWindowConfiguration() throws {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            throw XCTSkip("No screen available in CI environment")
        }

        let window = WallpaperWindow(for: screen)

        XCTAssertTrue(
            window.ignoresMouseEvents,
            "Window must be click-through"
        )
        XCTAssertFalse(
            window.canBecomeKey,
            "Wallpaper window must never become key"
        )
        XCTAssertFalse(
            window.canBecomeMain,
            "Wallpaper window must never become main"
        )
        XCTAssertFalse(
            window.hasShadow,
            "Wallpaper window must not cast a shadow"
        )
        XCTAssertTrue(
            window.collectionBehavior.contains(.canJoinAllSpaces),
            "Must be visible across all Spaces"
        )
        XCTAssertTrue(
            window.collectionBehavior.contains(.stationary),
            "Must not move with Mission Control"
        )

        let desktopLevel = Int(CGWindowLevelForKey(.desktopIconWindow))
        XCTAssertEqual(
            window.level.rawValue,
            desktopLevel - 1,
            "Must sit just below the desktop icon layer"
        )
    }

    @MainActor
    func testGradientWallpaperInitializes() {
        let gradient = GradientWallpaper()
        XCTAssertNotNil(gradient.layer)
        XCTAssertEqual(
            gradient.layer.colors?.count,
            3,
            "Gradient should have three color stops"
        )
        XCTAssertNotNil(
            gradient.layer.animation(forKey: "wave"),
            "Gradient should have an active wave animation"
        )
    }

    func testVideoEngineHandlesNonexistentURL() {
        // AVPlayer accepts any URL at init and surfaces errors later.
        // Just verify init does not crash.
        let url = URL(fileURLWithPath: "/tmp/does-not-exist.mp4")
        let engine = VideoEngine(videoURL: url)
        XCTAssertNotNil(engine.layer)
    }
}
