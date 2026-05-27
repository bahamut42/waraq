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

import SwiftUI

struct SettingsDetail: View {
    let pane: PaneID
    let isAdvanced: Bool

    var body: some View {
        Group {
            switch pane {
            case .general:
                GeneralPane(isAdvanced: isAdvanced)
            case .displays:
                DisplaysPane(isAdvanced: isAdvanced)
            case .library:
                LibraryPane()
            case .gallery:
                GalleryPane()
            case .performance:
                PerformancePane(isAdvanced: isAdvanced)
            case .wallpapers:
                WallpapersPane()
            case .diagnostics:
                DiagnosticsPane()
            case .about:
                AboutPane()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
