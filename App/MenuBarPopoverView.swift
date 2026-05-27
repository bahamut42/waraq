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

/// Menu bar dropdown SwiftUI view. Simplified Phase 2 version of
/// docs/design/menubar.md.
struct MenuBarPopoverView: View {
    @ObservedObject var displayManager: DisplayManager

    var body: some View {
        VStack(spacing: 0) {
            previewHero
            titleBlock
            quickActions
            Divider().padding(.horizontal, 12).padding(.vertical, 4)
            displaysSection
            Spacer(minLength: 8)
            Divider().padding(.horizontal, 12)
            footerMenu
        }
        .frame(width: 280)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }

    // Preview hero: placeholder gradient (live capture is Phase 4)

    private var previewHero: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.10, blue: 0.22),
                    Color(red: 0.24, green: 0.06, blue: 0.12),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .aspectRatio(16.0 / 10.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 8)

            HStack(spacing: 4) {
                Circle()
                    .fill(displayManager.isPaused
                        ? Color.orange : Color.green)
                    .frame(width: 5, height: 5)
                Text(displayManager.isPaused ? "Paused" : "Live")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.55))
            .clipShape(Capsule())
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Waraq")
                .font(.system(size: 13, weight: .medium))
            Text(statusLine)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var statusLine: String {
        let count = displayManager.displays.count
        let suffix = count == 1 ? "display" : "displays"
        if displayManager.isPaused {
            return "Paused on \(count) \(suffix)"
        }
        return "Playing on \(count) \(suffix)"
    }

    // Quick actions row

    private var quickActions: some View {
        HStack(spacing: 5) {
            quickButton(
                icon: displayManager.isPaused
                    ? "play.fill" : "pause.fill",
                label: displayManager.isPaused ? "Resume" : "Pause",
                action: displayManager.togglePause
            )
            quickButton(
                icon: displayManager.isMuted
                    ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: displayManager.isMuted ? "Muted" : "Mute",
                action: displayManager.toggleMute
            )
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private func quickButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(label)
                    .font(.system(size: 11))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // Displays section

    private var displaysSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("DISPLAYS")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(0.4)
                Spacer()
                Text("\(displayManager.displays.count)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)

            VStack(spacing: 1) {
                ForEach(displayManager.displays) { display in
                    displayRow(display)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private func displayRow(
        _ display: DisplayManager.DisplayInfo
    ) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.10, blue: 0.22),
                        Color(red: 0.24, green: 0.06, blue: 0.12),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 38, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(display.name)
                        .font(.system(
                            size: 12,
                            weight: display.isMain
                                ? .medium : .regular
                        ))
                    if display.isMain {
                        Text("MAIN")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(0.3)
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Color.accentColor.opacity(0.18)
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 3)
                            )
                    }
                }
                Text("\(display.width) x \(display.height)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(Color.clear)
        .contentShape(Rectangle())
    }

    // Footer

    private var footerMenu: some View {
        VStack(spacing: 0) {
            SettingsLink {
                HStack {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                    Text("Settings...")
                        .font(.system(size: 12))
                    Spacer()
                    Text("⌘,")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: displayManager.quitApplication) {
                HStack {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                    Text("Quit Waraq")
                        .font(.system(size: 12))
                    Spacer()
                    Text("⌘Q")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.horizontal, 6)
        .padding(.top, 4)
    }
}
