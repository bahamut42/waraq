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

struct DisplayConfigSheet: View {
    let display: DisplayManager.DisplayInfo

    @EnvironmentObject var displayManager: DisplayManager
    @StateObject private var library = WallpaperLibrary.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedID: String
    @State private var settings: DisplaySettings

    init(display: DisplayManager.DisplayInfo) {
        self.display = display
        let assignments = UserDefaults.standard.dictionary(
            forKey: "displayWallpaperAssignments"
        ) as? [String: String] ?? [:]
        let initial = assignments[String(display.id)]
            ?? WallpaperLibrary.builtInGradient.id
        _selectedID = State(initialValue: initial)
        _settings = State(
            initialValue: DisplaySettingsStore.settings(for: display.id)
        )
    }

    private var selectedWallpaper: Wallpaper? {
        library.wallpapers.first { $0.id == selectedID }
    }

    private var showsFitAndVolume: Bool {
        guard let w = selectedWallpaper else { return false }
        switch w.kind {
        case .video, .gif, .gifURL: return true
        default: return false
        }
    }

    private var showsVolumeAndLoop: Bool {
        guard let w = selectedWallpaper else { return false }
        switch w.kind {
        case .video: return true
        default: return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    enableSection
                    sectionLabel("WALLPAPER")
                    grid.padding(.bottom, 8)
                    sectionLabel("PLAYBACK")
                    playbackCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            footer
        }
        .frame(width: 560, height: 660)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Configure \(display.name)")
                .font(.system(size: 15, weight: .medium))
            Text("\(display.width) x \(display.height)\(display.isMain ? " · Main display" : "")")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .tracking(0.5)
            .foregroundStyle(.secondary)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .padding(.horizontal, 2)
    }

    private var enableSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Run wallpaper on this display")
                        .font(.system(size: 13))
                    Text(settings.enabled
                        ? "Active. macOS wallpaper is hidden."
                        : "Off. macOS wallpaper shows normally.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $settings.enabled)
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
        .padding(.top, 4)
    }

    private var grid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 130, maximum: 180), spacing: 10)],
            spacing: 10
        ) {
            ForEach(library.wallpapers) { wallpaper in
                pickerCard(wallpaper)
                    .onTapGesture { selectedID = wallpaper.id }
            }
        }
    }

    private func pickerCard(_ wallpaper: Wallpaper) -> some View {
        let isSelected = wallpaper.id == selectedID
        return VStack(alignment: .leading, spacing: 0) {
            pickerThumbnail(wallpaper)
            VStack(alignment: .leading, spacing: 2) {
                Text(wallpaper.name)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Text(metaLine(for: wallpaper))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
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

    /// Shows the generated thumbnail image for video/GIF wallpapers
    /// (falling back to a gradient while it generates or if missing).
    /// Procedural/built-in wallpapers keep their gradient swatch.
    @ViewBuilder
    private func pickerThumbnail(_ wallpaper: Wallpaper) -> some View {
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

    private func metaLine(for w: Wallpaper) -> String {
        switch w.kind {
        case .builtInGradient: "BUILT-IN"
        case .procedural:
            "BUILT-IN · " + (w.proceduralKey?.uppercased() ?? "")
        case .video: "VIDEO"
        case .gif: "GIF"
        case .gifURL:
            if let host = w.urlHost { "GIF · \(host.uppercased())" } else { "GIF · URL" }
        case .url: "URL"
        case .image: "IMAGE"
        }
    }

    private func thumbnailGradient(for w: Wallpaper) -> LinearGradient {
        switch w.kind {
        case .builtInGradient:
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.10, blue: 0.22),
                    Color(red: 0.24, green: 0.06, blue: 0.12),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .procedural:
            proceduralGradient(for: w.proceduralKey ?? "")
        case .video:
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.18, blue: 0.30),
                    Color(red: 0.10, green: 0.12, blue: 0.18),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .gif, .gifURL:
            LinearGradient(
                colors: [
                    Color(red: 0.30, green: 0.20, blue: 0.40),
                    Color(red: 0.15, green: 0.10, blue: 0.20),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .url, .image:
            LinearGradient(
                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    private func proceduralGradient(for key: String) -> LinearGradient {
        let colors: [Color] = switch key {
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
            [Color.gray, .black]
        }
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var playbackCard: some View {
        VStack(spacing: 0) {
            if showsFitAndVolume {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fit")
                            .font(.system(size: 13))
                        Text(settings.fitMode.description)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    Picker("", selection: $settings.fitMode) {
                        ForEach(
                            DisplaySettings.FitMode.allCases,
                            id: \.self
                        ) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 200)
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
                Divider()
            }

            if !showsFitAndVolume {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Fit modes apply to video and GIF wallpapers only. Procedural and gradient wallpapers always fill the display.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 14)
            }

            if showsVolumeAndLoop {
                HStack(spacing: 16) {
                    Text("Loop")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle("", isOn: $settings.loop)
                        .toggleStyle(.switch).labelsHidden()
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 14)

                Divider()

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Muted")
                            .font(.system(size: 13))
                        Text("Wallpapers default to muted")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $settings.muted)
                        .toggleStyle(.switch).labelsHidden()
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 14)

                if !settings.muted {
                    Divider()
                    HStack(spacing: 16) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                        Slider(value: $settings.volume, in: 0...1)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                        Text("\(Int(settings.volume * 100))%")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 36, alignment: .trailing)
                    }
                    .padding(.vertical, 11)
                    .padding(.horizontal, 14)
                }
            }
        }
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Cancel") { dismiss() }.controlSize(.large)
            Button("Done") {
                displayManager.reassignWallpaper(
                    displayID: display.id,
                    wallpaperID: selectedID
                )
                displayManager.updateDisplaySettings(
                    displayID: display.id,
                    settings: settings
                )
                dismiss()
            }
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.primary.opacity(0.03))
    }
}
