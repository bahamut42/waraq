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
import ServiceManagement
import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case displays
    case wallpaper
    case performance
    case finish

    var title: String {
        switch self {
        case .welcome: "Welcome to Waraq"
        case .displays: "Choose Your Displays"
        case .wallpaper: "Pick a Starter Wallpaper"
        case .performance: "Performance Settings"
        case .finish: "All Set"
        }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    static let completionKey = "hasCompletedOnboarding"

    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedWallpaperID: String
    @Published var pauseOnBattery: Bool
    @Published var pauseOnFullscreen: Bool
    @Published var launchAtLogin: Bool

    /// The live DisplayManager driving the wallpaper windows. Injected
    /// rather than using DisplayManager.shared, because the running
    /// instance is the one AppDelegate created; touching .shared would
    /// spin up a second manager that spawns its own windows.
    let displayManager: DisplayManager

    init(displayManager: DisplayManager) {
        self.displayManager = displayManager
        let defaults = UserDefaults.standard
        // Read existing values so re-running the wizard later does not
        // reset the user's earlier choices.
        selectedWallpaperID = WallpaperLibrary.builtInGradient.id
        pauseOnBattery = defaults.object(
            forKey: "pauseOnBattery"
        ) as? Bool ?? true
        pauseOnFullscreen = defaults.object(
            forKey: "pauseOnFullscreen"
        ) as? Bool ?? true
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
    }

    var canGoBack: Bool {
        currentStep.rawValue > OnboardingStep.welcome.rawValue
    }

    var canGoForward: Bool {
        currentStep.rawValue < OnboardingStep.finish.rawValue
    }

    var isLastStep: Bool {
        currentStep == .finish
    }

    func next() {
        guard canGoForward,
              let nextStep = OnboardingStep(
                  rawValue: currentStep.rawValue + 1
              ) else { return }
        currentStep = nextStep
    }

    func back() {
        guard canGoBack,
              let prevStep = OnboardingStep(
                  rawValue: currentStep.rawValue - 1
              ) else { return }
        currentStep = prevStep
    }

    func skip() {
        markCompleted()
    }

    func finish() {
        applySettings()
        markCompleted()
    }

    private func applySettings() {
        let defaults = UserDefaults.standard
        defaults.set(pauseOnBattery, forKey: "pauseOnBattery")
        defaults.set(pauseOnFullscreen, forKey: "pauseOnFullscreen")
        defaults.set(launchAtLogin, forKey: "launchAtLogin")

        // Apply the selected wallpaper to every enabled display via the
        // same path DisplayConfigSheet uses. Iterate the manager's
        // published displays (exposes a public CGDirectDisplayID).
        for display in displayManager.displays {
            let settings = DisplaySettingsStore.settings(for: display.id)
            guard settings.enabled else { continue }
            displayManager.reassignWallpaper(
                displayID: display.id,
                wallpaperID: selectedWallpaperID
            )
        }

        // Launch at login via SMAppService (macOS 13+, we require 14+).
        do {
            if launchAtLogin {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            // Non-fatal: the user can adjust this in System Settings.
            NSLog("Waraq: launch-at-login setting failed: \(error)")
        }
    }

    private func markCompleted() {
        UserDefaults.standard.set(true, forKey: Self.completionKey)
    }

    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: completionKey)
    }
}
