//  Waraq - A native macOS animated wallpaper app.
//  Copyright (C) 2026 Omar A. Othman
//
//  This program is free software: you can redistribute it
//  and/or modify it under the terms of the GNU General
//  Public License as published by the Free Software
//  Foundation, either version 3 of the License, or (at
//  your option) any later version.
//
//  This program is distributed in the hope that it will
//  be useful, but WITHOUT ANY WARRANTY; without even the
//  implied warranty of MERCHANTABILITY or FITNESS FOR A
//  PARTICULAR PURPOSE. See the GNU General Public License
//  for more details.
//
//  You should have received a copy of the GNU General
//  Public License along with this program. If not, see
//  <https://www.gnu.org/licenses/>.
//

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

    func testVideoEngineTileModeSurvivesZeroBounds() {
        // Regression: .tile computed cols/rows as Int(ceil(bounds /
        // tileSize)). At launch the layer bounds are .zero and the
        // video size hasn't loaded, so that was Int(NaN) and trapped,
        // crashing the app on launch whenever a tiled display had a
        // video wallpaper. Construction must not crash.
        let url = URL(fileURLWithPath: "/tmp/does-not-exist.mp4")
        let engine = VideoEngine(videoURL: url, fitMode: .tile)
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

    @MainActor
    func testResourceMonitorReportsValues() {
        _ = ResourceMonitor()
        let mem = ResourceMonitor.residentMemoryMB()
        XCTAssertGreaterThan(mem, 0, "Memory reading should be positive")
        // CPU may be 0 in test environment, just verify it does not throw
        _ = ResourceMonitor.processCPUPercent()
    }

    @MainActor
    func testPerformanceGovernorInitializes() {
        let gov = PerformanceGovernor()
        XCTAssertNotNil(gov)
        // isPortable can be either; just check the property exists
        _ = gov.isPortable
        // perDisplayState should have an entry per current screen
        XCTAssertEqual(
            gov.perDisplayState.count,
            NSScreen.screens.compactMap {
                $0.deviceDescription[
                    NSDeviceDescriptionKey("NSScreenNumber")
                ] as? CGDirectDisplayID
            }.count
        )
    }

    @MainActor
    func testPerformanceGovernorThermalLabel() {
        let gov = PerformanceGovernor()
        let validLabels = [
            "Nominal",
            "Fair",
            "Serious",
            "Critical",
            "Unknown",
        ]
        XCTAssertTrue(validLabels.contains(gov.thermalStateLabel))
    }

    @MainActor
    func testWallpaperLibraryHasBuiltIn() {
        let library = WallpaperLibrary()
        XCTAssertFalse(library.wallpapers.isEmpty)
        let builtIn = library.wallpapers.first {
            $0.kind == .builtInGradient
        }
        XCTAssertNotNil(
            builtIn,
            "Library should always include built-in gradient"
        )
        XCTAssertEqual(
            builtIn?.id,
            WallpaperLibrary.builtInGradient.id
        )
    }

    @MainActor
    func testWallpaperLibraryRejectsUnsupportedFormat() {
        let library = WallpaperLibrary()
        let url = URL(fileURLWithPath: "/tmp/fake.txt")
        XCTAssertThrowsError(try library.importFile(at: url)) { error in
            guard let importError = error as? WallpaperImportError else {
                XCTFail("Expected WallpaperImportError, got \(error)")
                return
            }
            switch importError {
            case .unsupportedFormat: break
            default: XCTFail("Expected unsupportedFormat, got \(importError)")
            }
        }
    }

    @MainActor
    func testWallpaperLibraryCannotRemoveBuiltIn() {
        let library = WallpaperLibrary()
        let before = library.wallpapers.count
        library.remove(WallpaperLibrary.builtInGradient)
        XCTAssertEqual(
            library.wallpapers.count,
            before,
            "Built-in should be unaffected by remove"
        )
    }

    func testWallpaperEncodesAndDecodes() throws {
        let wallpaper = Wallpaper(
            id: "test-id",
            name: "Test",
            kind: .video,
            addedDate: Date(timeIntervalSince1970: 1000),
            relativePath: "test.mp4",
            fileSizeBytes: 1024
        )
        let data = try JSONEncoder().encode(wallpaper)
        let decoded = try JSONDecoder().decode(
            Wallpaper.self, from: data
        )
        XCTAssertEqual(decoded.id, wallpaper.id)
        XCTAssertEqual(decoded.kind, .video)
        XCTAssertEqual(decoded.fileSizeBytes, 1024)
    }

    @MainActor
    func testProceduralFactoryAllKeys() throws {
        for builtIn in ProceduralFactory.allBuiltIns {
            XCTAssertEqual(builtIn.kind, .procedural)
            XCTAssertNotNil(builtIn.proceduralKey)
            let view = try ProceduralFactory.makeView(
                for: XCTUnwrap(builtIn.proceduralKey)
            )
            XCTAssertNotNil(view, "ProceduralFactory should produce view for \(builtIn.name)")
        }
    }

    @MainActor
    func testLibrarySeedsBuiltIns() {
        let library = WallpaperLibrary()
        let procedural = library.wallpapers.filter {
            $0.kind == .procedural
        }
        XCTAssertEqual(
            procedural.count,
            5,
            "Should seed 5 procedural built-ins"
        )
    }

    @MainActor
    func testWallpaperLibraryImportsGifURL() throws {
        let library = WallpaperLibrary()
        let initial = library.wallpapers.count
        let wallpaper = try library.importGifURL(
            "https://media.giphy.com/test.gif",
            name: "Test"
        )
        XCTAssertEqual(wallpaper.kind, .gifURL)
        XCTAssertEqual(library.wallpapers.count, initial + 1)
        library.remove(wallpaper)
    }

    @MainActor
    func testWallpaperLibraryRejectsNonGifURL() {
        let library = WallpaperLibrary()
        XCTAssertThrowsError(
            try library.importGifURL(
                "https://example.com/page.html",
                name: "Test"
            )
        )
    }

    @MainActor
    func testGifKindInFileExtensions() {
        XCTAssertTrue(
            WallpaperLibrary.supportedAllExtensions.contains("gif")
        )
        XCTAssertTrue(
            WallpaperLibrary.supportedAllExtensions.contains("mp4")
        )
    }

    @MainActor
    func testThumbnailURLDeterministic() {
        let library = WallpaperLibrary()
        let w = WallpaperLibrary.builtInGradient
        let url1 = library.thumbnailURL(for: w)
        let url2 = library.thumbnailURL(for: w)
        XCTAssertEqual(url1, url2)
        XCTAssertTrue(url1.path.hasSuffix("\(w.id).jpg"))
    }

    @MainActor
    func testDisplaySettingsRoundtrip() {
        let settings = DisplaySettings(
            enabled: false, fitMode: .fit,
            volume: 0.5, muted: false, loop: false
        )
        DisplaySettingsStore.save(settings, for: 999_998)
        let loaded = DisplaySettingsStore.settings(for: 999_998)
        XCTAssertEqual(loaded, settings)
    }

    @MainActor
    func testVideoEngineFitMode() {
        let url = URL(fileURLWithPath: "/tmp/nope.mp4")
        let engine = VideoEngine(videoURL: url, fitMode: .fit)
        XCTAssertEqual(engine.playerLayer.videoGravity, .resizeAspect)
        engine.fitMode = .stretch
        XCTAssertEqual(engine.playerLayer.videoGravity, .resize)
    }

    @MainActor
    func testFitModeFiveCases() {
        let all = DisplaySettings.FitMode.allCases
        XCTAssertEqual(all.count, 5)
        XCTAssertEqual(
            Set(all.map(\.rawValue)),
            ["fill", "fit", "stretch", "center", "tile"]
        )
    }

    @MainActor
    func testDisplayHardwareIDKeyFormat() {
        let id = DisplayHardwareID(vendor: 0x1, model: 0x2, serial: 0x3)
        XCTAssertEqual(id.key, "1-2-3")
    }

    @MainActor
    func testDisplayProfileRoundtrip() {
        let hwID = DisplayHardwareID(vendor: 100, model: 200, serial: 300)
        let profile = DisplayProfile(
            hardwareID: hwID,
            lastKnownName: "Studio Display",
            wallpaperID: "test-id",
            settings: DisplaySettings(),
            lastSeen: Date()
        )
        DisplayProfileStore.save(profile)
        let loaded = DisplayProfileStore.profile(for: hwID)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.lastKnownName, "Studio Display")
        XCTAssertEqual(loaded?.wallpaperID, "test-id")
        DisplayProfileStore.delete(hardwareID: hwID)
        XCTAssertNil(DisplayProfileStore.profile(for: hwID))
    }

    @MainActor
    func testDisplayHardwareIDValueInit() {
        // The value-based init always succeeds (used for synthetic
        // profiles in tests); the displayID-based init is the one
        // that returns nil for all-zero hardware IDs.
        let id = DisplayHardwareID(vendor: 0, model: 0, serial: 0)
        XCTAssertEqual(id.key, "0-0-0")
    }

    @MainActor
    func testDisplaySettingsDefaultReadsUserDefaults() {
        UserDefaults.standard.set("fit", forKey: "defaultFitMode")
        UserDefaults.standard.set(false, forKey: "defaultMuted")
        UserDefaults.standard.set(false, forKey: "defaultLoop")
        defer {
            UserDefaults.standard.removeObject(forKey: "defaultFitMode")
            UserDefaults.standard.removeObject(forKey: "defaultMuted")
            UserDefaults.standard.removeObject(forKey: "defaultLoop")
        }
        let d = DisplaySettings.default
        XCTAssertEqual(d.fitMode, .fit)
        XCTAssertFalse(d.muted)
        XCTAssertFalse(d.loop)
    }

    @MainActor
    func testCustomThumbnailPathDistinct() {
        let library = WallpaperLibrary()
        let w = WallpaperLibrary.builtInGradient
        let auto = library.thumbnailURL(for: w)
        let custom = library.customThumbnailURL(for: w)
        XCTAssertNotEqual(auto, custom)
        XCTAssertTrue(custom.path.contains(".custom.jpg"))
        XCTAssertFalse(library.hasCustomThumbnail(for: w))
    }

    @MainActor
    func testWallpaperEngineImporterRejectsUnsupportedType() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "waraq-we-test-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let projectJSON = """
        { "title": "Test", "type": "scene", "file": "scene.pkg" }
        """
        let projectURL = tempDir.appendingPathComponent("project.json")
        try Data(projectJSON.utf8).write(to: projectURL)

        let archiveURL = tempDir
            .deletingLastPathComponent()
            .appendingPathComponent("test-\(UUID().uuidString).we")
        let zip = Process()
        zip.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        zip.arguments = ["-j", archiveURL.path, projectURL.path]
        try zip.run()
        zip.waitUntilExit()
        defer { try? FileManager.default.removeItem(at: archiveURL) }

        XCTAssertThrowsError(
            try WallpaperEngineImporter.importArchive(at: archiveURL)
        ) { error in
            guard case WallpaperEngineImporter.ImportError.unsupportedType =
                error else
            {
                XCTFail("Expected unsupportedType, got \(error)")
                return
            }
        }
    }

    @MainActor
    func testOnboardingStepNavigation() {
        let vm = OnboardingViewModel(displayManager: DisplayManager.shared)
        XCTAssertEqual(vm.currentStep, .welcome)
        XCTAssertFalse(vm.canGoBack)
        XCTAssertTrue(vm.canGoForward)
        XCTAssertFalse(vm.isLastStep)

        vm.next()
        XCTAssertEqual(vm.currentStep, .displays)
        XCTAssertTrue(vm.canGoBack)

        vm.next() // wallpaper
        vm.next() // performance
        vm.next() // finish
        XCTAssertEqual(vm.currentStep, .finish)
        XCTAssertFalse(vm.canGoForward)
        XCTAssertTrue(vm.isLastStep)

        vm.back()
        XCTAssertEqual(vm.currentStep, .performance)

        // next() at last step is a no-op
        vm.currentStep = .finish
        vm.next()
        XCTAssertEqual(vm.currentStep, .finish)

        // back() at first step is a no-op
        vm.currentStep = .welcome
        vm.back()
        XCTAssertEqual(vm.currentStep, .welcome)
    }

    @MainActor
    func testOnboardingCompletionFlag() {
        let key = OnboardingViewModel.completionKey
        UserDefaults.standard.removeObject(forKey: key)
        defer {
            UserDefaults.standard.removeObject(forKey: key)
        }

        XCTAssertFalse(
            OnboardingViewModel.hasCompletedOnboarding,
            "Should default to not completed"
        )

        let vm = OnboardingViewModel(displayManager: DisplayManager.shared)
        vm.skip()

        XCTAssertTrue(
            OnboardingViewModel.hasCompletedOnboarding,
            "Skip should set completion flag"
        )
    }

    @MainActor
    func testDisableDisplayPersistsToProfile() {
        // Reproduces the Phase 9.5 bug: toggling enabled off via
        // updateDisplaySettings must update both the displayID-
        // keyed store AND the hardware-ID-keyed profile.
        // Without that, a display sync respawns the window.
        let hwID = DisplayHardwareID(
            vendor: 0xABCD, model: 0x1234, serial: 0x5678
        )
        let initialSettings = DisplaySettings(
            enabled: true, fitMode: .fill,
            volume: 0, muted: true, loop: true
        )
        let profile = DisplayProfile(
            hardwareID: hwID,
            lastKnownName: "Test Monitor",
            wallpaperID: WallpaperLibrary.builtInGradient.id,
            settings: initialSettings,
            lastSeen: Date()
        )
        DisplayProfileStore.save(profile)
        defer { DisplayProfileStore.delete(hardwareID: hwID) }

        XCTAssertEqual(
            DisplayProfileStore.profile(for: hwID)?.settings.enabled,
            true,
            "Initial profile should be enabled"
        )

        var updated = initialSettings
        updated.enabled = false
        let newProfile = DisplayProfile(
            hardwareID: hwID,
            lastKnownName: "Test Monitor",
            wallpaperID: WallpaperLibrary.builtInGradient.id,
            settings: updated,
            lastSeen: Date()
        )
        DisplayProfileStore.save(newProfile)

        XCTAssertEqual(
            DisplayProfileStore.profile(for: hwID)?.settings.enabled,
            false,
            "Profile must persist enabled=false. If this fails, the bug from Phase 9.5 has regressed: subsequent display syncs will resurrect the wallpaper from the stale profile."
        )
    }
}
