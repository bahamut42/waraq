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
import SwiftUI

struct WallpaperStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @StateObject private var library = WallpaperLibrary.shared

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var builtIns: [Wallpaper] {
        library.wallpapers.filter {
            $0.kind == .builtInGradient || $0.kind == .procedural
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(
                title: "Pick a Starter Wallpaper",
                subtitle: "We'll apply this to all enabled displays. You can change it any time from Settings."
            )

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(builtIns) { wallpaper in
                        tile(wallpaper)
                            .onTapGesture {
                                viewModel.selectedWallpaperID = wallpaper.id
                            }
                    }
                }
                .padding(.vertical, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }

    private func tile(_ wallpaper: Wallpaper) -> some View {
        let isSelected = wallpaper.id == viewModel.selectedWallpaperID
        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                thumbnail(for: wallpaper)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white, Color.accentColor)
                        .padding(6)
                }
            }
            Text(wallpaper.name)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(
                    isSelected
                        ? Color.accentColor
                        : Color.primary.opacity(0.08),
                    lineWidth: isSelected ? 2 : 0.5
                )
        )
        .contentShape(Rectangle())
    }

    /// Real captured thumbnail when available (video/GIF/procedural),
    /// otherwise the gradient swatch while it's still being generated.
    @ViewBuilder
    private func thumbnail(for wallpaper: Wallpaper) -> some View {
        if library.hasAnyThumbnail(for: wallpaper),
           let nsImage = NSImage(
               contentsOf: library.displayThumbnailURL(for: wallpaper)
           )
        {
            Color.clear
                .aspectRatio(16.0 / 10.0, contentMode: .fit)
                .overlay(
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                )
                .clipped()
        } else {
            Rectangle()
                .fill(thumbnailGradient(for: wallpaper))
                .aspectRatio(16.0 / 10.0, contentMode: .fit)
        }
    }

    private func thumbnailGradient(for w: Wallpaper) -> LinearGradient {
        if w.kind == .builtInGradient {
            return LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.10, blue: 0.22),
                    Color(red: 0.24, green: 0.06, blue: 0.12),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
        let colors: [Color] = switch w.proceduralKey ?? "" {
        case "aurora":
            [
                Color(red: 0.10, green: 0.30, blue: 0.40),
                Color(red: 0.30, green: 0.10, blue: 0.45),
            ]
        case "matrix-rain":
            [Color(red: 0.02, green: 0.18, blue: 0.05), .black]
        case "synthwave":
            [
                Color(red: 0.85, green: 0.20, blue: 0.50),
                Color(red: 0.10, green: 0.02, blue: 0.30),
            ]
        case "starfield":
            [Color(red: 0.04, green: 0.04, blue: 0.10), .black]
        case "neural-network":
            [
                Color(red: 0.10, green: 0.20, blue: 0.40),
                Color(red: 0.04, green: 0.05, blue: 0.10),
            ]
        default:
            [.gray, .black]
        }
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}
