import AppKit
import SwiftUI

@MainActor
final class MenuBarController {
    private let displayManager: DisplayManager
    private var statusItem: NSStatusItem?
    private let popover: NSPopover

    init(displayManager: DisplayManager) {
        self.displayManager = displayManager

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 280, height: 380)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView(displayManager: displayManager)
        )

        setVisible(true)
    }

    func setVisible(_ visible: Bool) {
        if visible {
            if statusItem == nil {
                createStatusItem()
            }
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }

    private func createStatusItem() {
        let item = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        guard let button = item.button else { return }

        let image = NSImage(
            systemSymbolName: "square.stack.3d.up.fill",
            accessibilityDescription: "Waraq"
        )
        image?.isTemplate = true
        button.image = image
        button.target = self
        button.action = #selector(togglePopover(_:))

        statusItem = item
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .maxY
            )
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
