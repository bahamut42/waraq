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

struct DisplaySettings: Codable, Equatable {
    var enabled: Bool = true
    var fitMode: FitMode = .fill
    var volume: Double = 0
    var muted: Bool = true
    var loop: Bool = true

    enum FitMode: String, Codable, CaseIterable {
        case fill // Fill Screen
        case fit // Fit to Screen
        case stretch // Stretch to Fill Screen
        case center // Natural size, centered
        case tile // Repeat in a grid

        var label: String {
            switch self {
            case .fill: "Fill Screen"
            case .fit: "Fit to Screen"
            case .stretch: "Stretch to Fill Screen"
            case .center: "Center"
            case .tile: "Tile"
            }
        }

        var description: String {
            switch self {
            case .fill: "Crop edges to fill the display"
            case .fit: "Show entire video, may letterbox"
            case .stretch: "Stretch to fill exactly, may distort"
            case .center: "Natural pixel size, centered"
            case .tile: "Repeat in a grid across the display"
            }
        }
    }

    static var `default`: DisplaySettings {
        var s = DisplaySettings()
        if let raw = UserDefaults.standard.string(forKey: "defaultFitMode"),
           let mode = FitMode(rawValue: raw)
        {
            s.fitMode = mode
        }
        if UserDefaults.standard.object(forKey: "defaultMuted") != nil {
            s.muted = UserDefaults.standard.bool(forKey: "defaultMuted")
        }
        if UserDefaults.standard.object(forKey: "defaultLoop") != nil {
            s.loop = UserDefaults.standard.bool(forKey: "defaultLoop")
        }
        return s
    }
}

enum DisplaySettingsStore {
    private static let key = "displaySettings"

    static func settings(for displayID: CGDirectDisplayID) -> DisplaySettings {
        guard let map = UserDefaults.standard.dictionary(
            forKey: key
        ) as? [String: Data],
            let data = map[String(displayID)] else { return .default }
        return (try? JSONDecoder().decode(DisplaySettings.self, from: data))
            ?? .default
    }

    static func save(
        _ settings: DisplaySettings,
        for displayID: CGDirectDisplayID
    ) {
        var map = UserDefaults.standard.dictionary(
            forKey: key
        ) as? [String: Data] ?? [:]
        if let data = try? JSONEncoder().encode(settings) {
            map[String(displayID)] = data
            UserDefaults.standard.set(map, forKey: key)
        }
    }
}
