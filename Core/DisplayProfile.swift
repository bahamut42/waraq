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

import CoreGraphics
import Foundation

/// Stable per-monitor identifier built from vendor/model/serial.
/// Survives reconnects (unlike CGDirectDisplayID which is
/// session-local). Returns nil if the display reports zero for
/// all three components (some virtual displays).
struct DisplayHardwareID: Hashable, Codable {
    let vendor: UInt32
    let model: UInt32
    let serial: UInt32

    init?(displayID: CGDirectDisplayID) {
        let v = CGDisplayVendorNumber(displayID)
        let m = CGDisplayModelNumber(displayID)
        let s = CGDisplaySerialNumber(displayID)
        if v == 0, m == 0, s == 0 { return nil }
        vendor = v
        model = m
        serial = s
    }

    init(vendor: UInt32, model: UInt32, serial: UInt32) {
        self.vendor = vendor
        self.model = model
        self.serial = serial
    }

    var key: String {
        "\(vendor)-\(model)-\(serial)"
    }
}

/// What we remember about a physical monitor across sessions.
struct DisplayProfile: Codable {
    var hardwareID: DisplayHardwareID
    var lastKnownName: String
    var wallpaperID: String
    var settings: DisplaySettings
    var lastSeen: Date

    /// Used for the Diagnostics pane to format the hardware ID
    /// in a way that's human-readable.
    var formattedHardwareID: String {
        String(
            format: "%08X-%08X-%08X",
            hardwareID.vendor,
            hardwareID.model,
            hardwareID.serial
        )
    }
}

/// Persistence layer. Keyed by hardware ID string in UserDefaults.
enum DisplayProfileStore {
    private static let key = "displayProfiles"

    static func profile(
        for hardwareID: DisplayHardwareID
    ) -> DisplayProfile? {
        guard let map = UserDefaults.standard.dictionary(
            forKey: key
        ) as? [String: Data],
            let data = map[hardwareID.key] else { return nil }
        return try? JSONDecoder().decode(
            DisplayProfile.self, from: data
        )
    }

    static func save(_ profile: DisplayProfile) {
        var map = UserDefaults.standard.dictionary(
            forKey: key
        ) as? [String: Data] ?? [:]
        if let data = try? JSONEncoder().encode(profile) {
            map[profile.hardwareID.key] = data
            UserDefaults.standard.set(map, forKey: key)
        }
    }

    static func delete(hardwareID: DisplayHardwareID) {
        var map = UserDefaults.standard.dictionary(
            forKey: key
        ) as? [String: Data] ?? [:]
        map.removeValue(forKey: hardwareID.key)
        UserDefaults.standard.set(map, forKey: key)
    }

    static func allProfiles() -> [DisplayProfile] {
        guard let map = UserDefaults.standard.dictionary(
            forKey: key
        ) as? [String: Data] else { return [] }
        return map.values.compactMap {
            try? JSONDecoder().decode(DisplayProfile.self, from: $0)
        }.sorted { $0.lastSeen > $1.lastSeen }
    }
}
