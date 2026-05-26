import AppKit
import AVFoundation
import XCTest
@testable import Waraq

final class WaraqTests: XCTestCase {
    func testPhase0Placeholder() {
        XCTAssertTrue(true, "Phase 0 scaffold test.")
    }

    func testWallpaperManifestDecodes() throws {
        let json = Data("""
        {
          "schema": 1,
          "id": "com.example.test",
          "name": "Test",
          "type": "video",
          "entry": "content/scene.mp4"
        }
        """.utf8)

        let manifest = try JSONDecoder().decode(
            WallpaperManifest.self, from: json
        )
        XCTAssertEqual(manifest.id, "com.example.test")
        XCTAssertEqual(manifest.type, .video)
    }

    @MainActor
    func testWallpaperWindowConfiguration() throws {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            throw XCTSkip("No screen available")
        }

        let window = WallpaperWindow(for: screen)

        XCTAssertTrue(window.ignoresMouseEvents)
        XCTAssertFalse(window.canBecomeKey)
        XCTAssertFalse(window.canBecomeMain)
        XCTAssertFalse(window.hasShadow)
        XCTAssertTrue(
            window.collectionBehavior.contains(.canJoinAllSpaces)
        )
        XCTAssertTrue(
            window.collectionBehavior.contains(.stationary)
        )

        let desktopLevel = Int(CGWindowLevelForKey(.desktopIconWindow))
        XCTAssertEqual(window.level.rawValue, desktopLevel - 1)
    }

    @MainActor
    func testGradientWallpaperInitializes() {
        let gradient = GradientWallpaper()
        XCTAssertNotNil(gradient.layer)
        XCTAssertEqual(gradient.layer.colors?.count, 3)
        XCTAssertNotNil(gradient.layer.animation(forKey: "wave"))
    }

    @MainActor
    func testGradientWallpaperPauseAndResume() {
        let gradient = GradientWallpaper()
        gradient.setPaused(true)
        XCTAssertEqual(
            gradient.layer.speed,
            0,
            "Layer speed should be 0 when paused"
        )
        gradient.setPaused(false)
        XCTAssertEqual(
            gradient.layer.speed,
            1,
            "Layer speed should be 1 when resumed"
        )
    }

    func testVideoEngineHandlesNonexistentURL() {
        let url = URL(fileURLWithPath: "/tmp/does-not-exist.mp4")
        let engine = VideoEngine(videoURL: url)
        XCTAssertNotNil(engine.layer)
    }

    func testVideoEngineMuteToggle() {
        let url = URL(fileURLWithPath: "/tmp/does-not-exist.mp4")
        let engine = VideoEngine(videoURL: url)
        XCTAssertTrue(engine.isMuted, "Should start muted")
        engine.isMuted = false
        XCTAssertFalse(engine.isMuted)
        engine.isMuted = true
        XCTAssertTrue(engine.isMuted)
    }

    @MainActor
    func testDisplayManagerObservesScreens() {
        let manager = DisplayManager()
        // At least one display exists in any normal environment.
        XCTAssertFalse(
            manager.displays.isEmpty,
            "Should detect at least one display"
        )
        XCTAssertEqual(
            manager.displays.count,
            NSScreen.screens.count,
            "Display count should match NSScreen.screens"
        )
    }

    @MainActor
    func testDisplayManagerTogglePause() {
        let manager = DisplayManager()
        XCTAssertFalse(manager.isPaused)
        manager.togglePause()
        XCTAssertTrue(manager.isPaused)
        manager.togglePause()
        XCTAssertFalse(manager.isPaused)
    }

    @MainActor
    func testDisplayManagerToggleMute() {
        let manager = DisplayManager()
        XCTAssertTrue(manager.isMuted, "Should default to muted")
        manager.toggleMute()
        XCTAssertFalse(manager.isMuted)
        manager.toggleMute()
        XCTAssertTrue(manager.isMuted)
    }

    @MainActor
    func testSelectedPaneDefaultsToGeneral() {
        UserDefaults.standard.removeObject(forKey: "selectedPane")
        let raw = UserDefaults.standard.string(forKey: "selectedPane")
            ?? "general"
        XCTAssertEqual(raw, "general")
    }

    @MainActor
    func testAdvancedModeDefaultsOff() {
        UserDefaults.standard.removeObject(forKey: "isAdvancedMode")
        let value = UserDefaults.standard.object(
            forKey: "isAdvancedMode"
        ) as? Bool ?? false
        XCTAssertFalse(value, "Advanced mode should default to off")
    }

    func testPaneIDDiagnosticsVisibilityRespectsAdvanced() {
        XCTAssertFalse(PaneID.diagnostics.isVisible(advanced: false))
        XCTAssertTrue(PaneID.diagnostics.isVisible(advanced: true))
        XCTAssertTrue(PaneID.general.isVisible(advanced: false))
        XCTAssertTrue(PaneID.general.isVisible(advanced: true))
    }
}
