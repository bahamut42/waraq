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

/// Root view for the Settings window. NavigationSplitView with the
/// sidebar on the left and the selected pane on the right.
struct SettingsRootView: View {
    @AppStorage("selectedPane") private var selectedPane: PaneID = .general
    @AppStorage("isAdvancedMode") private var isAdvanced: Bool = false

    var body: some View {
        NavigationSplitView {
            SettingsSidebar(
                selectedPane: $selectedPane,
                isAdvanced: $isAdvanced
            )
            .navigationSplitViewColumnWidth(min: 190, ideal: 190, max: 220)
        } detail: {
            SettingsDetail(
                pane: selectedPane,
                isAdvanced: isAdvanced
            )
        }
        .navigationTitle("Waraq Settings")
    }
}

enum PaneID: String, CaseIterable, Identifiable {
    case general
    case displays
    case library
    case gallery
    case performance
    case wallpapers
    case diagnostics
    case about

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .general: "General"
        case .displays: "Displays"
        case .library: "Library"
        case .gallery: "Gallery"
        case .performance: "Performance"
        case .wallpapers: "Wallpapers"
        case .diagnostics: "Diagnostics"
        case .about: "About"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .displays: "display"
        case .library: "photo.on.rectangle"
        case .gallery: "photo.stack"
        case .performance: "speedometer"
        case .wallpapers: "square.stack.3d.up"
        case .diagnostics: "stethoscope"
        case .about: "info.circle"
        }
    }

    /// Returns true if this pane should be visible in the sidebar
    /// for the given Advanced mode state.
    func isVisible(advanced: Bool) -> Bool {
        if self == .diagnostics { return advanced }
        return true
    }
}
