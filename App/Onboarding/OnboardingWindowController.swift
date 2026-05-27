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
final class OnboardingWindowController: NSWindowController {
    private static var current: OnboardingWindowController?
    private let viewModel: OnboardingViewModel

    init(displayManager: DisplayManager) {
        viewModel = OnboardingViewModel(displayManager: displayManager)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Waraq Setup"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)

        let content = OnboardingRootView(viewModel: viewModel) {
            [weak self] in
            self?.close()
            OnboardingWindowController.current = nil
        }
        window.contentView = NSHostingView(rootView: content)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Show the wizard only if the user hasn't completed it. Called
    /// from AppDelegate at first launch.
    static func presentIfNeeded(displayManager: DisplayManager) {
        guard !OnboardingViewModel.hasCompletedOnboarding else { return }
        presentForced(displayManager: displayManager)
    }

    /// Show the wizard unconditionally. Called from the About pane's
    /// "Run Setup Again" button.
    static func presentForced(displayManager: DisplayManager) {
        if let existing = current {
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let controller = OnboardingWindowController(
            displayManager: displayManager
        )
        current = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
