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
import Combine
import Foundation
import IOKit.ps

/// Observes the system and decides whether each display should
/// Play, Pause, or Throttle. Wired into DisplayManager which
/// drives the actual engines accordingly.
///
/// Phase 4 implementation per docs/design/settings-performance.md.
@MainActor
final class PerformanceGovernor: ObservableObject {
    enum PlaybackState: String {
        case playing
        case paused
        case throttled
    }

    /// Per-display target state. Display IDs without an entry default
    /// to .playing.
    @Published private(set) var perDisplayState:
        [CGDirectDisplayID: PlaybackState] = [:]

    /// True if any pause rule is currently active globally.
    @Published private(set) var globallyPaused: Bool = false

    /// Current thermal state as a string, for the Performance pane
    /// status banner.
    @Published private(set) var thermalStateLabel: String = "Nominal"

    /// Battery percent, 0 to 100. -1 if no battery (desktop Mac).
    @Published private(set) var batteryPercent: Int = -1

    /// True on portable Macs (battery detected at init).
    let isPortable: Bool

    // System observers
    private var thermalObserver: NSObjectProtocol?
    private var lpmObserver: NSObjectProtocol?
    private var screenLockObserver: NSObjectProtocol?
    private var screenUnlockObserver: NSObjectProtocol?
    private var spaceChangeObserver: NSObjectProtocol?
    private var screenSleepObserver: NSObjectProtocol?
    private var screenWakeObserver: NSObjectProtocol?

    // Internal state
    private var isScreenLocked = false
    private var isScreenAsleep = false
    private var fullscreenAppBundleID: String?
    private var batteryPoll: Timer?

    init() {
        isPortable = Self.detectPortableMac()
        batteryPercent = Self.currentBatteryPercent() ?? -1

        installObservers()
        refreshState()

        // Poll battery and fullscreen every 5 seconds.
        batteryPoll = Timer.scheduledTimer(
            withTimeInterval: 5.0, repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollAdHoc()
            }
        }
    }

    deinit {
        [
            thermalObserver,
            lpmObserver,
            screenLockObserver,
            screenUnlockObserver,
            spaceChangeObserver,
            screenSleepObserver,
            screenWakeObserver,
        ]
        .compactMap { $0 }
        .forEach { NotificationCenter.default.removeObserver($0) }
        batteryPoll?.invalidate()
    }

    /// Public refresh API; DisplayManager can call this on screen
    /// change to evaluate for newly-added displays.
    func refreshState() {
        var newState: [CGDirectDisplayID: PlaybackState] = [:]
        var anyPause = false

        for screen in NSScreen.screens {
            guard let id = screen.displayID else { continue }
            let s = evaluate(for: screen)
            newState[id] = s
            if s == .paused { anyPause = true }
        }

        perDisplayState = newState
        globallyPaused = anyPause
        thermalStateLabel = Self.label(
            for: ProcessInfo.processInfo.thermalState
        )
        if isPortable {
            batteryPercent = Self.currentBatteryPercent() ?? -1
        }
    }

    /// Priority-ordered evaluation per spec.
    private func evaluate(for _: NSScreen) -> PlaybackState {
        // 1. Screen sleeping
        if isScreenAsleep { return .paused }

        // 2. Reduce Motion
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return .paused
        }

        // 3. Screen locked (if user opted in)
        if pauseWhenScreenLocked, isScreenLocked { return .paused }

        // 4. Fullscreen app on this screen (if user opted in)
        if pauseOnFullscreen, fullscreenAppBundleID != nil {
            // Phase 4: pause globally on any fullscreen, future
            // phases refine per-screen detection.
            return .paused
        }

        // 5. Thermal Critical
        if ProcessInfo.processInfo.thermalState == .critical {
            return .paused
        }

        // 6. Battery threshold
        if isPortable, pauseOnBattery {
            let charge = batteryPercent
            if charge >= 0, charge < batteryThreshold,
               !Self.isOnACPower()
            {
                return .paused
            }
        }

        // 7. Low Power Mode
        if pauseInLowPowerMode,
           ProcessInfo.processInfo.isLowPowerModeEnabled
        {
            return .paused
        }

        // 8. Thermal Fair / Serious -> Throttle
        let thermal = ProcessInfo.processInfo.thermalState
        if thermal == .fair || thermal == .serious {
            return .throttled
        }

        return .playing
    }

    /// AppStorage-driven settings
    private var pauseOnFullscreen: Bool {
        UserDefaults.standard.object(
            forKey: "pauseOnFullscreen"
        ) as? Bool ?? true
    }

    private var pauseWhenScreenLocked: Bool {
        UserDefaults.standard.object(
            forKey: "pauseWhenScreenLocked"
        ) as? Bool ?? true
    }

    private var pauseOnBattery: Bool {
        UserDefaults.standard.object(
            forKey: "pauseOnBattery"
        ) as? Bool ?? true
    }

    private var pauseInLowPowerMode: Bool {
        UserDefaults.standard.object(
            forKey: "pauseInLowPowerMode"
        ) as? Bool ?? true
    }

    private var batteryThreshold: Int {
        UserDefaults.standard.object(
            forKey: "batteryThreshold"
        ) as? Int ?? 35
    }

    // Observers

    private func installObservers() {
        let nc = NotificationCenter.default
        let dnc = DistributedNotificationCenter.default()
        let wsnc = NSWorkspace.shared.notificationCenter

        thermalObserver = nc.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshState() }
        }

        lpmObserver = nc.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshState() }
        }

        screenLockObserver = dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isScreenLocked = true
                self?.refreshState()
            }
        }

        screenUnlockObserver = dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isScreenLocked = false
                self?.refreshState()
            }
        }

        spaceChangeObserver = wsnc.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.detectFullscreenApp()
                self?.refreshState()
            }
        }

        screenSleepObserver = wsnc.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isScreenAsleep = true
                self?.refreshState()
            }
        }

        screenWakeObserver = wsnc.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isScreenAsleep = false
                self?.refreshState()
            }
        }
    }

    private func pollAdHoc() {
        detectFullscreenApp()
        refreshState()
    }

    private func detectFullscreenApp() {
        // Look for a window covering an entire screen at layer 0.
        let options: CGWindowListOption = [
            .optionOnScreenOnly, .excludeDesktopElements,
        ]
        guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
            as? [[String: Any]] else
        {
            fullscreenAppBundleID = nil
            return
        }

        let screenBounds = NSScreen.main?.frame ?? .zero
        let exemptions = exemptionBundleIDs()

        for window in info {
            guard let layer = window[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let boundsDict = window[kCGWindowBounds as String]
                  as? [String: Any],
                  let bx = boundsDict["X"] as? CGFloat,
                  let by = boundsDict["Y"] as? CGFloat,
                  let bw = boundsDict["Width"] as? CGFloat,
                  let bh = boundsDict["Height"] as? CGFloat else
            {
                continue
            }

            // Treat windows that cover the main screen as fullscreen.
            let isFullSize = abs(bw - screenBounds.width) < 5 &&
                abs(bh - screenBounds.height) < 5 &&
                abs(bx) < 5 && abs(by) < 50
            if isFullSize {
                if let ownerName = window[kCGWindowOwnerName as String]
                    as? String,
                    !ownerName.isEmpty,
                    ownerName != "Window Server",
                    ownerName != "Waraq"
                {
                    // Skip if in exemption list (by display name match)
                    if exemptions.contains(where: {
                        ownerName.lowercased().contains($0.lowercased())
                    }) {
                        continue
                    }
                    fullscreenAppBundleID = ownerName
                    return
                }
            }
        }
        fullscreenAppBundleID = nil
    }

    private func exemptionBundleIDs() -> [String] {
        UserDefaults.standard.array(
            forKey: "fullscreenExemptions"
        ) as? [String] ?? []
    }

    // Helpers

    private static func detectPortableMac() -> Bool {
        guard let blob = IOPSCopyPowerSourcesInfo()?
            .takeRetainedValue() else
        {
            return false
        }
        guard let sources = IOPSCopyPowerSourcesList(blob)?
            .takeRetainedValue() as? [CFTypeRef] else
        {
            return false
        }
        for source in sources {
            guard let dict = IOPSGetPowerSourceDescription(blob, source)?
                .takeUnretainedValue() as? [String: Any] else
            {
                continue
            }
            if let type = dict[kIOPSTypeKey as String] as? String,
               type == kIOPSInternalBatteryType
            {
                return true
            }
        }
        return false
    }

    private static func currentBatteryPercent() -> Int? {
        guard let blob = IOPSCopyPowerSourcesInfo()?
            .takeRetainedValue() else { return nil }
        guard let sources = IOPSCopyPowerSourcesList(blob)?
            .takeRetainedValue() as? [CFTypeRef] else { return nil }
        for source in sources {
            guard let dict = IOPSGetPowerSourceDescription(blob, source)?
                .takeUnretainedValue() as? [String: Any] else
            {
                continue
            }
            if let cap = dict[kIOPSCurrentCapacityKey as String] as? Int {
                return cap
            }
        }
        return nil
    }

    private static func isOnACPower() -> Bool {
        guard let blob = IOPSCopyPowerSourcesInfo()?
            .takeRetainedValue() else { return false }
        guard let sources = IOPSCopyPowerSourcesList(blob)?
            .takeRetainedValue() as? [CFTypeRef] else { return false }
        for source in sources {
            guard let dict = IOPSGetPowerSourceDescription(blob, source)?
                .takeUnretainedValue() as? [String: Any] else
            {
                continue
            }
            if let state = dict[kIOPSPowerSourceStateKey as String]
                as? String, state == kIOPSACPowerValue
            {
                return true
            }
        }
        return false
    }

    private static func label(
        for state: ProcessInfo.ThermalState
    ) -> String {
        switch state {
        case .nominal: "Nominal"
        case .fair: "Fair"
        case .serious: "Serious"
        case .critical: "Critical"
        @unknown default: "Unknown"
        }
    }
}

private extension NSScreen {
    /// The CGDirectDisplayID for this screen, if available.
    var displayID: CGDirectDisplayID? {
        deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")
        ] as? CGDirectDisplayID
    }
}
