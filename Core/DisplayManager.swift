import AppKit
import Combine

/// Central manager for wallpaper rendering across all connected
/// displays. Observes screen connect/disconnect and keeps one
/// WallpaperWindow + engine alive per NSScreen.
///
/// Phase 2 implementation. Per-display profiles and per-display
/// configuration arrive in Phase 3, see
/// docs/design/settings-displays.md.
@MainActor
final class DisplayManager: ObservableObject {
    static let shared = DisplayManager()

    @Published private(set) var displays: [DisplayInfo] = []
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var isMuted: Bool = true

    let library: WallpaperLibrary
    let governor: PerformanceGovernor
    let resourceMonitor: ResourceMonitor

    private var windows: [CGDirectDisplayID: WallpaperWindow] = [:]
    private var videoEngines: [CGDirectDisplayID: VideoEngine] = [:]
    private var gradients: [CGDirectDisplayID: GradientWallpaper] = [:]
    private var gifEngines: [CGDirectDisplayID: GifEngine] = [:]
    private var proceduralViews: [CGDirectDisplayID: NSView] = [:]

    private var screenObserver: NSObjectProtocol?
    private var governorCancellable: AnyCancellable?

    struct DisplayInfo: Identifiable, Equatable {
        let id: CGDirectDisplayID
        let name: String
        let width: Int
        let height: Int
        let isMain: Bool
    }

    init() {
        library = WallpaperLibrary.shared
        governor = PerformanceGovernor()
        resourceMonitor = ResourceMonitor.shared

        syncDisplays()

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.syncDisplays()
                self?.governor.refreshState()
            }
        }

        // React to governor state changes by play/pause/throttle.
        governorCancellable = governor.$perDisplayState
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                Task { @MainActor in
                    self?.applyGovernorState(newState)
                }
            }

        resourceMonitor.start()
    }

    private func applyGovernorState(
        _ state: [CGDirectDisplayID: PerformanceGovernor.PlaybackState]
    ) {
        // Don't override manual pause from menu bar.
        guard !isPaused else { return }

        for (id, target) in state {
            switch target {
            case .playing:
                videoEngines[id]?.play()
                gradients[id]?.setPaused(false)
                gifEngines[id]?.play()
            case .paused, .throttled:
                // Phase 4 simplification: throttled treated as
                // paused. Future phases will halve FPS instead.
                videoEngines[id]?.pause()
                gradients[id]?.setPaused(true)
                gifEngines[id]?.pause()
            }
        }
    }

    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Reconcile our window map with the currently-attached screens.
    func syncDisplays() {
        let currentScreens = NSScreen.screens
        let currentIDs = Set(currentScreens.compactMap(\.displayID))

        // Remove windows for displays that disappeared.
        for (id, window) in windows where !currentIDs.contains(id) {
            window.orderOut(nil)
            windows.removeValue(forKey: id)
            videoEngines.removeValue(forKey: id)
            gradients.removeValue(forKey: id)
            gifEngines.removeValue(forKey: id)
            proceduralViews.removeValue(forKey: id)
        }

        // Spawn windows for displays that appeared.
        for screen in currentScreens {
            guard let id = screen.displayID else { continue }
            if windows[id] == nil {
                spawnWindow(for: screen, id: id)
            }
        }

        // Update published info.
        displays = currentScreens.compactMap { screen in
            guard let id = screen.displayID else { return nil }
            let main = screen == NSScreen.main
            let name = screen.localizedName
            return DisplayInfo(
                id: id,
                name: name,
                width: Int(screen.frame.width),
                height: Int(screen.frame.height),
                isMain: main
            )
        }
    }

    private func spawnWindow(for screen: NSScreen, id: CGDirectDisplayID) {
        // Resolve which wallpaper and settings to use, honoring
        // profile-based restoration for known displays.
        let settings: DisplaySettings
        let wallpaper: Wallpaper

        if let hardwareID = DisplayHardwareID(displayID: id) {
            if let profile = DisplayProfileStore.profile(for: hardwareID) {
                // Known display: apply saved according to user
                // preference. "askEachTime" treated as "applyDefault"
                // in Phase 8 (dialog deferred to Phase 9).
                let policy = UserDefaults.standard.string(
                    forKey: "onKnownDisplay"
                ) ?? "applySaved"

                switch policy {
                case "applySaved":
                    settings = profile.settings
                    if let w = library.wallpaper(forID: profile.wallpaperID) {
                        wallpaper = w
                    } else {
                        wallpaper = library.wallpapers.first
                            ?? WallpaperLibrary.builtInGradient
                    }
                    // Sync into displayID-keyed cache for live updates.
                    DisplaySettingsStore.save(settings, for: id)
                    cacheAssignment(wallpaperID: wallpaper.id, displayID: id)
                default: // applyDefault
                    settings = DisplaySettingsStore.settings(for: id)
                    wallpaper = wallpaperToSpawn(for: id)
                }
            } else {
                // New (never-seen) display.
                let policy = UserDefaults.standard.string(
                    forKey: "onNewDisplay"
                ) ?? "applyDefault"
                _ = policy // Same fallback for both options currently.
                settings = DisplaySettingsStore.settings(for: id)
                wallpaper = wallpaperToSpawn(for: id)
            }
        } else {
            // Display has no hardware ID. Fall back to legacy
            // displayID-keyed storage entirely.
            settings = DisplaySettingsStore.settings(for: id)
            wallpaper = wallpaperToSpawn(for: id)
        }

        // Honor per-display enabled flag.
        guard settings.enabled else { return }

        let window = WallpaperWindow(for: screen)

        switch wallpaper.kind {
        case .builtInGradient:
            let gradient = GradientWallpaper()
            window.install(layer: gradient.layer)
            gradients[id] = gradient
            if isPaused { gradient.setPaused(true) }

        case .procedural:
            if let key = wallpaper.proceduralKey,
               let view = ProceduralFactory.makeView(for: key)
            {
                window.install(view: view)
                proceduralViews[id] = view
            } else {
                let gradient = GradientWallpaper()
                window.install(layer: gradient.layer)
                gradients[id] = gradient
            }

        case .video:
            if let videoURL = library.fileURL(for: wallpaper) {
                let engine = VideoEngine(
                    videoURL: videoURL,
                    fitMode: settings.fitMode
                )
                engine.isMuted = settings.muted || isMuted
                engine.volume = Float(settings.volume)
                engine.loop = settings.loop
                window.install(layer: engine.layer)
                if !isPaused { engine.play() }
                videoEngines[id] = engine
            } else {
                let gradient = GradientWallpaper()
                window.install(layer: gradient.layer)
                gradients[id] = gradient
            }

        case .gif:
            if let fileURL = library.fileURL(for: wallpaper) {
                let engine = GifEngine(
                    source: .localFile(fileURL),
                    fitMode: settings.fitMode
                )
                window.install(view: engine.view)
                if !isPaused { engine.play() }
                gifEngines[id] = engine
            } else {
                let gradient = GradientWallpaper()
                window.install(layer: gradient.layer)
                gradients[id] = gradient
            }

        case .gifURL:
            if let str = wallpaper.urlString,
               let url = URL(string: str)
            {
                let engine = GifEngine(
                    source: .remoteURL(url),
                    fitMode: settings.fitMode
                )
                window.install(view: engine.view)
                if !isPaused { engine.play() }
                gifEngines[id] = engine
            } else {
                let gradient = GradientWallpaper()
                window.install(layer: gradient.layer)
                gradients[id] = gradient
            }

        case .image, .url:
            // .url is deprecated and filtered on library load,
            // but handle gracefully as fallback.
            let gradient = GradientWallpaper()
            window.install(layer: gradient.layer)
            gradients[id] = gradient
        }

        window.orderFront(nil)
        windows[id] = window

        // Persist a profile snapshot after spawn (so reconnects
        // restore the last-applied state).
        saveProfile(
            displayID: id,
            screen: screen,
            wallpaperID: wallpaper.id,
            settings: settings
        )
    }

    private func cacheAssignment(
        wallpaperID: String, displayID: CGDirectDisplayID
    ) {
        var assignments = UserDefaults.standard.dictionary(
            forKey: "displayWallpaperAssignments"
        ) as? [String: String] ?? [:]
        assignments[String(displayID)] = wallpaperID
        UserDefaults.standard.set(
            assignments, forKey: "displayWallpaperAssignments"
        )
    }

    private func saveProfile(
        displayID: CGDirectDisplayID,
        screen: NSScreen,
        wallpaperID: String,
        settings: DisplaySettings
    ) {
        guard let hardwareID = DisplayHardwareID(displayID: displayID) else {
            return
        }
        let profile = DisplayProfile(
            hardwareID: hardwareID,
            lastKnownName: screen.localizedName,
            wallpaperID: wallpaperID,
            settings: settings,
            lastSeen: Date()
        )
        DisplayProfileStore.save(profile)
    }

    /// Returns the wallpaper to use for a given display, falling back
    /// to the built-in gradient if no assignment exists or the assigned
    /// wallpaper is no longer in the library.
    private func wallpaperToSpawn(
        for displayID: CGDirectDisplayID
    ) -> Wallpaper {
        let assignments = UserDefaults.standard.dictionary(
            forKey: "displayWallpaperAssignments"
        ) as? [String: String] ?? [:]

        if let assignedID = assignments[String(displayID)],
           let assigned = library.wallpaper(forID: assignedID)
        {
            return assigned
        }
        return WallpaperLibrary.builtInGradient
    }

    /// Save a wallpaper assignment for a display and respawn its
    /// window so the new wallpaper is visible immediately.
    func reassignWallpaper(
        displayID: CGDirectDisplayID,
        wallpaperID: String
    ) {
        cacheAssignment(wallpaperID: wallpaperID, displayID: displayID)

        // Update the saved profile so the "applySaved" restore policy
        // reflects the user's new choice rather than reverting to the
        // previously-saved wallpaper.
        if let hardwareID = DisplayHardwareID(displayID: displayID),
           var profile = DisplayProfileStore.profile(for: hardwareID)
        {
            profile.wallpaperID = wallpaperID
            profile.lastSeen = Date()
            DisplayProfileStore.save(profile)
        }

        teardownWindow(for: displayID)

        // Re-spawn (spawnWindow re-saves the profile snapshot).
        if let screen = NSScreen.screens.first(where: {
            $0.displayID == displayID
        }) {
            spawnWindow(for: screen, id: displayID)
        }
    }

    private func teardownWindow(for displayID: CGDirectDisplayID) {
        if let window = windows[displayID] {
            window.orderOut(nil)
        }
        windows.removeValue(forKey: displayID)
        videoEngines.removeValue(forKey: displayID)
        gradients.removeValue(forKey: displayID)
        gifEngines.removeValue(forKey: displayID)
        proceduralViews.removeValue(forKey: displayID)
    }

    func setDisplayEnabled(displayID: CGDirectDisplayID, enabled: Bool) {
        var settings = DisplaySettingsStore.settings(for: displayID)
        settings.enabled = enabled
        DisplaySettingsStore.save(settings, for: displayID)

        if enabled {
            if let screen = NSScreen.screens.first(
                where: { $0.displayID == displayID }
            ), windows[displayID] == nil {
                spawnWindow(for: screen, id: displayID)
            }
        } else {
            teardownWindow(for: displayID)
        }

        // Refresh published list so UI updates.
        syncDisplays()
    }

    func updateDisplaySettings(
        displayID: CGDirectDisplayID,
        settings: DisplaySettings
    ) {
        let previous = DisplaySettingsStore.settings(for: displayID)
        DisplaySettingsStore.save(settings, for: displayID)

        // If enabled flag toggled, respawn or teardown.
        if previous.enabled != settings.enabled {
            setDisplayEnabled(displayID: displayID, enabled: settings.enabled)
            return
        }

        // Live updates for video engines.
        if let engine = videoEngines[displayID] {
            engine.fitMode = settings.fitMode
            engine.isMuted = settings.muted || isMuted
            engine.volume = Float(settings.volume)
            engine.loop = settings.loop
        }
        if let engine = gifEngines[displayID] {
            engine.updateFitMode(settings.fitMode)
        }

        // Update profile snapshot.
        if let screen = NSScreen.screens.first(
            where: { $0.displayID == displayID }
        ) {
            let assignments = UserDefaults.standard.dictionary(
                forKey: "displayWallpaperAssignments"
            ) as? [String: String] ?? [:]
            let wallpaperID = assignments[String(displayID)]
                ?? WallpaperLibrary.builtInGradient.id
            saveProfile(
                displayID: displayID, screen: screen,
                wallpaperID: wallpaperID, settings: settings
            )
        }
    }

    // Playback control

    func togglePause() {
        isPaused.toggle()
        for engine in videoEngines.values {
            isPaused ? engine.pause() : engine.play()
        }
        for gradient in gradients.values {
            gradient.setPaused(isPaused)
        }
        for gif in gifEngines.values {
            isPaused ? gif.pause() : gif.play()
        }
    }

    func toggleMute() {
        isMuted.toggle()
        for engine in videoEngines.values {
            engine.isMuted = isMuted
        }
    }

    func quitApplication() {
        NSApp.terminate(nil)
    }
}

private extension NSScreen {
    /// The CGDirectDisplayID for this screen, if available.
    var displayID: CGDirectDisplayID? {
        deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")
        ] as? CGDirectDisplayID
    }
}
