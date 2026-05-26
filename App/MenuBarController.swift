import AppKit
import SwiftUI

/// Owns the menu bar status item and its popover.
///
/// Phase 2 implementation per docs/design/menubar.md (simplified;
/// preview hero is a placeholder gradient until Phase 4 hooks up
/// live wallpaper capture).
@MainActor
final class MenuBarController {
    private let displayManager: DisplayManager
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init(displayManager: DisplayManager) {
        self.displayManager = displayManager

        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 280, height: 380)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView(displayManager: displayManager)
        )

        configureStatusItem()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        // Placeholder template icon. Phase 7 swaps in the real
        // Waraq SVG per docs/design/app-icon.md.
        let image = NSImage(
            systemSymbolName: "square.stack.3d.up.fill",
            accessibilityDescription: "Waraq"
        )
        image?.isTemplate = true
        button.image = image
        button.target = self
        button.action = #selector(togglePopover(_:))
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .maxY
            )
            // Bring app to front briefly so the popover keyboard
            // shortcuts work even when the app is fully background.
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
