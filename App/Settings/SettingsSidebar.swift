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

struct SettingsSidebar: View {
    @Binding var selectedPane: PaneID
    @Binding var isAdvanced: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            SearchField()
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 4)

            // Nav items
            List(selection: $selectedPane) {
                ForEach(visiblePanes, id: \.id) { pane in
                    NavLabel(pane: pane)
                        .tag(pane)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Spacer(minLength: 0)

            // Advanced toggle footer
            advancedFooter
        }
    }

    private var visiblePanes: [PaneID] {
        PaneID.allCases.filter { $0.isVisible(advanced: isAdvanced) }
    }

    private var advancedFooter: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Advanced")
                        .font(.system(size: 12, weight: .medium))
                    Text("Full depth controls")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $isAdvanced)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.accentColor.opacity(0.06))
        }
    }
}

private struct NavLabel: View {
    let pane: PaneID

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: pane.icon)
                .font(.system(size: 14))
                .frame(width: 18)
            Text(pane.label)
                .font(.system(size: 13))
            Spacer()
            if pane == .diagnostics {
                Text("ADV")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(0.3)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.accentColor.opacity(0.18))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
    }
}

private struct SearchField: View {
    @State private var query: String = ""
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            TextField("Search", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
