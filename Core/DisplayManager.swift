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
    @Published private(set) var displays: [DisplayInfo] = []
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var isMuted: Bool = true

    private var windows: [CGDirectDisplayID: WallpaperWindow] = [:]
    private var videoEngines: [CGDirectDisplayID: VideoEngine] = [:]
    private var gradients: [CGDirectDisplayID: GradientWallpaper] = [:]

    private var screenObserver: NSObjectProtocol?

    struct DisplayInfo: Identifiable, Equatable {
        let id: CGDirectDisplayID
        let name: String
        let width: Int
        let height: Int
        let isMain: Bool
    }

    init() {
        syncDisplays()

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.syncDisplays()
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

        // Phase 2: still prefer bundled sample.mp4 if present,
        // otherwise the animated gradient. Per-display wallpaper
        // selection arrives in Phase 4.
        if let videoURL = Bundle.main.url(
            forResource: "sample", withExtension: "mp4"
        ) {
            let engine = VideoEngine(videoURL: videoURL)
            engine.isMuted = isMuted
            window.install(layer: engine.layer)
            if !isPaused {
                engine.play()
            }
            videoEngines[id] = engine
        } else {
            let gradient = GradientWallpaper()
            window.install(layer: gradient.layer)
            gradients[id] = gradient
        }

        window.orderFront(nil)
        windows[id] = window
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
