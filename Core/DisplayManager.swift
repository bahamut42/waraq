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
        resourceMonitor = ResourceMonitor()

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
            case .paused, .throttled:
                // Phase 4 simplification: throttled treated as
                // paused. Future phases will halve FPS instead.
                videoEngines[id]?.pause()
                gradients[id]?.setPaused(true)
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
        let window = WallpaperWindow(for: screen)

        let wallpaper = wallpaperToSpawn(for: id)

        switch wallpaper.kind {
        case .builtInGradient:
            let gradient = GradientWallpaper()
            window.install(layer: gradient.layer)
            gradients[id] = gradient
            if isPaused {
                gradient.setPaused(true)
            }

        case .video:
            if let videoURL = library.fileURL(for: wallpaper) {
                let engine = VideoEngine(videoURL: videoURL)
                engine.isMuted = isMuted
                window.install(layer: engine.layer)
                if !isPaused {
                    engine.play()
                }
                videoEngines[id] = engine
            } else {
                // File missing; fall back to gradient.
                let gradient = GradientWallpaper()
                window.install(layer: gradient.layer)
                gradients[id] = gradient
            }

        case .image:
            // Phase 7 - for now, use gradient as fallback.
            let gradient = GradientWallpaper()
            window.install(layer: gradient.layer)
            gradients[id] = gradient
        }

        window.orderFront(nil)
        windows[id] = window
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
        var assignments = UserDefaults.standard.dictionary(
            forKey: "displayWallpaperAssignments"
        ) as? [String: String] ?? [:]
        assignments[String(displayID)] = wallpaperID
        UserDefaults.standard.set(
            assignments, forKey: "displayWallpaperAssignments"
        )

        // Tear down the old window for this display.
        if let window = windows[displayID] {
            window.orderOut(nil)
        }
        windows.removeValue(forKey: displayID)
        videoEngines.removeValue(forKey: displayID)
        gradients.removeValue(forKey: displayID)

        // Re-spawn.
        if let screen = NSScreen.screens.first(where: {
            $0.displayID == displayID
        }) {
            spawnWindow(for: screen, id: displayID)
        }
    }

    // Playback control

    func togglePause() {
        isPaused.toggle()
        for engine in videoEngines.values {
            if isPaused {
                engine.pause()
            } else {
                engine.play()
            }
        }
        for gradient in gradients.values {
            gradient.setPaused(isPaused)
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
