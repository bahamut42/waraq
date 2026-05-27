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

enum GallerySource: String, Codable, CaseIterable {
    case pixabay
    case pexels
    case nasa

    var displayName: String {
        switch self {
        case .pixabay: "Pixabay"
        case .pexels: "Pexels"
        case .nasa: "NASA"
        }
    }

    var websiteURL: URL {
        switch self {
        case .pixabay: URL(string: "https://pixabay.com/")!
        case .pexels: URL(string: "https://pexels.com/")!
        case .nasa: URL(string: "https://images.nasa.gov/")!
        }
    }

    var apiKeySignupURL: URL? {
        switch self {
        case .pixabay: URL(string: "https://pixabay.com/api/docs/")
        case .pexels: URL(string: "https://www.pexels.com/api/")
        case .nasa: nil // NASA API works without a key for low-volume use
        }
    }

    /// True if this source's client is fully implemented and ready to
    /// use. All current sources are implemented.
    var isImplemented: Bool {
        switch self {
        case .pixabay, .pexels, .nasa: true
        }
    }

    /// True if this source needs an API key. NASA's public library is
    /// open for low-volume use, so it skips the key entry entirely.
    var requiresAPIKey: Bool {
        switch self {
        case .pixabay, .pexels: true
        case .nasa: false
        }
    }
}
