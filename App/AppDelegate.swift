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
