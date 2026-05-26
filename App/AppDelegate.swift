import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var wallpaperWindow: WallpaperWindow?
    private var videoEngine: VideoEngine?
    private var gradientWallpaper: GradientWallpaper?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else {
            NSLog("Waraq: no main screen, exiting")
            NSApp.terminate(nil)
            return
        }

        let window = WallpaperWindow(for: screen)
        wallpaperWindow = window

        // Phase 1: try a bundled "sample.mp4" first, fall back to
        // the animated gradient. Drop any MP4 named sample.mp4 into
        // Resources/ and rebuild to test video playback.
        if let videoURL = Bundle.main.url(
            forResource: "sample", withExtension: "mp4"
        ) {
            let engine = VideoEngine(videoURL: videoURL)
            window.install(layer: engine.layer)
            engine.play()
            videoEngine = engine
            NSLog("Waraq: playing bundled video wallpaper")
        } else {
            let gradient = GradientWallpaper()
            window.install(layer: gradient.layer)
            gradientWallpaper = gradient
            NSLog("Waraq: no bundled video, using gradient fallback")
        }

        window.orderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        videoEngine?.pause()
    }
}
