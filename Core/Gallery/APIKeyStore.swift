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

import Foundation

/// Stores per-source API keys in UserDefaults. Keys are not
/// secrets in the cryptographic sense (they identify
/// rate-limit buckets, not personal data), so UserDefaults is
/// adequate. Stored locally; never transmitted except as
/// query parameters to the relevant API host.
enum APIKeyStore {
    static func key(for source: GallerySource) -> String? {
        let key = userDefaultsKey(for: source)
        let raw = UserDefaults.standard.string(forKey: key) ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func setKey(_ key: String?, for source: GallerySource) {
        let trimmed = key?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
        let defaultsKey = userDefaultsKey(for: source)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: defaultsKey)
        }
    }

    static func hasKey(for source: GallerySource) -> Bool {
        key(for: source) != nil
    }

    private static func userDefaultsKey(for source: GallerySource) -> String {
        "GalleryAPIKey.\(source.rawValue)"
    }
}
