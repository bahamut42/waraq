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

        let image = NSImage(named: "MenuBarIcon") ?? NSImage(
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
