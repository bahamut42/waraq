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
final class AppDelegate: NSObject, NSApplicationDelegate {
    var displayManager: DisplayManager?
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let manager = DisplayManager()
        displayManager = manager

        let menuBar = MenuBarController(displayManager: manager)
        menuBarController = menuBar

        // Apply persisted appearance preference at launch.
        applyAppearancePreference()

        // Apply menu bar visibility preference.
        applyMenuBarVisibility()

        NSLog("Waraq: launched with \(manager.displays.count) display(s)")

        // Present the first-launch onboarding wizard after a short
        // delay so the menu bar icon is up before the wizard's final
        // step references it. No-op once the user has completed it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            OnboardingWindowController.presentIfNeeded(
                displayManager: manager
            )
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }

    /// Reads `appAppearance` from AppStorage and applies it to NSApp.
    func applyAppearancePreference() {
        let raw = UserDefaults.standard.string(forKey: "appAppearance")
            ?? "system"
        switch raw {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }

    /// Reads `showInMenuBar` and shows or hides the status item.
    func applyMenuBarVisibility() {
        let visible = UserDefaults.standard.object(
            forKey: "showInMenuBar"
        ) as? Bool ?? true
        menuBarController?.setVisible(visible)
    }
}
