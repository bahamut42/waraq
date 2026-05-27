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

/// Preview sheet shown when a tile is tapped. Shows a large static
/// thumbnail of the video plus its metadata and attribution, and
/// offers "Add to Library" (downloads the large quality + imports)
/// or Cancel.
///
/// We intentionally show a still image rather than a live player:
/// remote streaming via AVPlayerView rendered black on this
/// macOS/SDK, and the SwiftUI VideoPlayer wrapper crashes outright
/// (see the gallery preview crash fix). The wallpaper animates once
/// it's applied to a display through the normal engine.
struct GalleryItemPreview: View {
    let item: GalleryItem
    let isDownloading: Bool
    let downloadError: String?
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            previewArea
            metadata
            Divider()
            footer
        }
        .frame(width: 560, height: 480)
    }

    private var header: some View {
        HStack {
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(12)
    }

    private var previewArea: some View {
        Color.black
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .overlay(thumbnailImage)
            .overlay(alignment: .bottomLeading) { motionHint }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
    }

    private var thumbnailImage: some View {
        AsyncImage(url: item.thumbnailURL) { phase in
            switch phase {
            case let .success(image):
                image.resizable().scaledToFill()
            case .failure:
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.7))
            case .empty:
                ProgressView().controlSize(.large)
            @unknown default:
                Color.black
            }
        }
        .clipped()
    }

    private var motionHint: some View {
        HStack(spacing: 5) {
            Image(systemName: "play.circle.fill")
            Text("Animates when set as wallpaper")
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.55), in: Capsule())
        .padding(10)
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
            Text("\(item.resolutionString) · \(item.durationString)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text("by \(item.attribution.creatorName) on \(item.attribution.sourceName)")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            if let downloadError {
                Text(downloadError)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Spacer()
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.cancelAction)
            Button(action: onAdd) {
                if isDownloading {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Adding…")
                    }
                } else {
                    Text("Add to Library")
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(isDownloading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}
