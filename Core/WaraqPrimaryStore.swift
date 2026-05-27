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
import Foundation

/// Tracks the user's chosen primary display, separately from macOS's
/// NSScreen.main (which is whichever display has the menu bar).
/// Persisted as a hardware-ID string in UserDefaults so it survives
/// launches and display disconnect/reconnect cycles.
///
/// Falls back to NSScreen.main if no choice is stored or the chosen
/// display isn't currently connected. Uses a standalone UserDefaults
/// key — it deliberately does NOT touch the DisplayProfile struct,
/// since adding a field there would break already-stored profiles.
enum WaraqPrimaryStore {
    private static let key = "waraqPrimaryHardwareID"

    /// User-chosen primary display hardware ID, or nil if unset.
    static var chosenHardwareID: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    /// The displayID currently considered "Waraq Primary": the chosen
    /// hardware ID's display if connected, else NSScreen.main. Nil only
    /// if there are no screens at all.
    @MainActor
    static func currentPrimaryDisplayID() -> CGDirectDisplayID? {
        if let chosen = chosenHardwareID {
            for screen in NSScreen.screens {
                guard let displayID = screen.waraqDisplayID,
                      let hwID = DisplayHardwareID(displayID: displayID) else { continue }
                if hwID.key == chosen { return displayID }
            }
            // Chosen display not connected — fall through to macOS main.
        }
        return NSScreen.main?.waraqDisplayID
    }

    @MainActor
    static func isPrimary(displayID: CGDirectDisplayID) -> Bool {
        currentPrimaryDisplayID() == displayID
    }
}

private extension NSScreen {
    /// CGDirectDisplayID for this screen, if available. File-private
    /// copy: the other definitions live in DisplayManager /
    /// PerformanceGovernor as private extensions and aren't visible
    /// here.
    var waraqDisplayID: CGDirectDisplayID? {
        deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")
        ] as? CGDirectDisplayID
    }
}
