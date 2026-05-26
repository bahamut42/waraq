import AppKit

/// NSWindow positioned just below the desktop icon layer.
/// Acts as the host for wallpaper rendering layers.
///
/// Phase 1 implementation. Multi-monitor and per-display profiles
/// arrive in Phase 2, see docs/design/settings-displays.md.
final class WallpaperWindow: NSWindow {
    init(for screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        // Sit just below the desktop icon layer so icons remain
        // visible and clickable on top of the wallpaper.
        let desktopIconLevel = Int(
            CGWindowLevelForKey(.desktopIconWindow)
        )
        level = NSWindow.Level(rawValue: desktopIconLevel - 1)

        // Visible on every Space, every fullscreen, every desktop.
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary,
        ]

        // Click-through so the user can interact with desktop icons
        // and apps as if the window were not there.
        ignoresMouseEvents = true

        // No focus, no titlebar, no shadow, opaque black under the
        // wallpaper content (avoids a white flash on launch).
        isOpaque = true
        backgroundColor = .black
        hasShadow = false
        isReleasedWhenClosed = false

        // Prepare a content view that hosts the wallpaper layer.
        let contentView = NSView(frame: screen.frame)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.black.cgColor
        self.contentView = contentView
    }

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }

    /// Install a wallpaper layer (gradient, video, etc) as the
    /// content view's hosting layer.
    func install(layer: CALayer) {
        guard let contentView else { return }
        contentView.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        layer.frame = contentView.bounds
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        contentView.layer?.addSublayer(layer)
    }
}
