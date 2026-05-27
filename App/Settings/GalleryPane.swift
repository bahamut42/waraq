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

/// Settings pane hosting the online wallpaper gallery. This is
/// the composition root for the gallery feature: it resolves the
/// shared WallpaperLibrary and injects it into GalleryViewModel
/// (the view model itself never touches `.shared`, mirroring the
/// Phase 9.7 dependency-injection pattern).
struct GalleryPane: View {
    @StateObject private var viewModel = GalleryViewModel(
        library: WallpaperLibrary.shared
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleRow
            GalleryView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gallery")
                    .font(.system(size: 20, weight: .semibold))
                Text("Browse and download free video wallpapers")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if viewModel.hasAPIKey, viewModel.selectedSource.requiresAPIKey {
                Menu {
                    Button("Change API key…") { viewModel.clearAPIKey() }
                } label: {
                    Label(
                        viewModel.selectedSource.displayName,
                        systemImage: "chevron.down"
                    )
                    .font(.system(size: 12))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
        .padding(.bottom, 16)
    }
}
