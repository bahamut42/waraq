import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var displayManager: DisplayManager?
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let manager = DisplayManager()
        displayManager = manager

        let menuBar = MenuBarController(displayManager: manager)
        menuBarController = menuBar

        NSLog("Waraq: launched with \(manager.displays.count) display(s)")
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }
}
