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

struct WallpapersPane: View {
    @AppStorage("defaultFitMode") private var defaultFitMode: String = "fill"
    @AppStorage("defaultMuted") private var defaultMuted: Bool = true
    @AppStorage("defaultLoop") private var defaultLoop: Bool = true
    @AppStorage("onKnownDisplay") private var onKnownDisplay: String = "applySaved"
    @AppStorage("onNewDisplay") private var onNewDisplay: String = "applyDefault"

    @StateObject private var library = WallpaperLibrary.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Wallpapers")
                    .font(.system(size: 22, weight: .medium))
                    .tracking(-0.2)
                    .padding(.bottom, 18)

                sectionHeader("DEFAULTS FOR NEW IMPORTS")
                defaultsCard
                    .padding(.bottom, 8)

                sectionHeader("DISPLAY RECONNECTION")
                reconnectCard
                    .padding(.bottom, 8)

                sectionHeader("LIBRARY")
                libraryCard
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .tracking(0.5)
            .foregroundStyle(.secondary)
            .padding(.top, 6)
            .padding(.bottom, 10)
    }

    private var defaultsCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Default fit mode")
                        .font(.system(size: 13))
                    Text("Applied to newly imported wallpapers")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: $defaultFitMode) {
                    ForEach(
                        DisplaySettings.FitMode.allCases,
                        id: \.self
                    ) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 200)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)

            Divider()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start muted")
                        .font(.system(size: 13))
                    Text("Videos default to muted on import")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $defaultMuted)
                    .toggleStyle(.switch).labelsHidden()
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)

            Divider()

            HStack(spacing: 16) {
                Text("Loop")
                    .font(.system(size: 13))
                Spacer()
                Toggle("", isOn: $defaultLoop)
                    .toggleStyle(.switch).labelsHidden()
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
        }
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    private var reconnectCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("When a known display connects")
                        .font(.system(size: 13))
                    Text("Behavior for monitors Waraq has seen before")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: $onKnownDisplay) {
                    Text("Apply saved").tag("applySaved")
                    Text("Apply default").tag("applyDefault")
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 200)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)

            Divider()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("When a new display connects")
                        .font(.system(size: 13))
                    Text("Behavior for monitors Waraq has never seen")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: $onNewDisplay) {
                    Text("Apply default").tag("applyDefault")
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 200)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
        }
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    private var libraryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Library is stored at:")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(library.libraryDir.path
                .replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                .font(.system(size: 11, design: .monospaced))
                .textSelection(.enabled)
            HStack {
                Spacer()
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting(
                        [library.libraryDir]
                    )
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                        .font(.system(size: 11))
                }
                .controlSize(.small)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}
