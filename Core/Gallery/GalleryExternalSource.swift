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

/// External wallpaper source. Unlike GallerySource (which has an API
/// client), these are just curated links — users browse in their
/// default browser, download manually under each site's personal-use
/// license, then drag the downloaded MP4 into Waraq's Library.
///
/// Waraq does not scrape, proxy, mirror, or redistribute any external
/// site's content. These are bookmarks.
struct GalleryExternalSource: Identifiable, Hashable {
    let id: String
    let name: String
    let descriptionText: String
    let symbolName: String // SF Symbol
    let websiteURL: URL
    let categoryTags: [String]
}
