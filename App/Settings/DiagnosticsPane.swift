import AppKit
import SwiftUI

struct DiagnosticsPane: View {
    @EnvironmentObject var displayManager: DisplayManager
    @StateObject private var library = WallpaperLibrary.shared
    @StateObject private var monitor = ResourceMonitor.shared

    @State private var profiles: [DisplayProfile] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Diagnostics")
                    .font(.system(size: 22, weight: .medium))
                    .tracking(-0.2)
                    .padding(.bottom, 18)

                sectionHeader("CONNECTED DISPLAYS")
                ForEach(displayManager.displays, id: \.id) { display in
                    diagnosticsCard(for: display)
                        .padding(.bottom, 8)
                }

                sectionHeader("LIBRARY")
                libraryCard
                    .padding(.bottom, 8)

                sectionHeader("SYSTEM")
                systemCard
                    .padding(.bottom, 8)

                sectionHeader("KNOWN MONITORS (\(profiles.count))")
                if profiles.isEmpty {
                    Text("No saved profiles yet. Profiles appear after a display has been configured.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 14)
                } else {
                    ForEach(profiles, id: \.hardwareID.key) { profile in
                        profileCard(profile)
                            .padding(.bottom, 8)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .onAppear { profiles = DisplayProfileStore.allProfiles() }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .tracking(0.5)
            .foregroundStyle(.secondary)
            .padding(.top, 6)
            .padding(.bottom, 10)
    }

    private func diagnosticsCard(
        for display: DisplayManager.DisplayInfo
    ) -> some View {
        let settings = DisplaySettingsStore.settings(for: display.id)
        let assignments = UserDefaults.standard.dictionary(
            forKey: "displayWallpaperAssignments"
        ) as? [String: String] ?? [:]
        let assignedID = assignments[String(display.id)]
            ?? WallpaperLibrary.builtInGradient.id
        let wallpaper = library.wallpaper(forID: assignedID)
        let hardwareID = DisplayHardwareID(displayID: display.id)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(settings.enabled ? Color.green : Color.gray)
                    .frame(width: 6, height: 6)
                Text(display.name)
                    .font(.system(size: 13, weight: .medium))
                if display.isMain {
                    Text("MAIN")
                        .font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.18))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                Spacer()
                Text(settings.enabled ? "LIVE" : "OFF")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            row(
                "Resolution",
                "\(display.width) × \(display.height)"
            )
            row(
                "Hardware ID",
                hardwareID.map {
                    String(
                        format: "%08X-%08X-%08X",
                        $0.vendor,
                        $0.model,
                        $0.serial
                    )
                } ?? "Not available"
            )
            row(
                "Wallpaper",
                wallpaper?.name ?? "None"
            )
            row(
                "Engine",
                engineLabel(for: wallpaper)
            )
            row(
                "Fit",
                settings.fitMode.label
            )
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

    private func engineLabel(for wallpaper: Wallpaper?) -> String {
        guard let w = wallpaper else { return "None" }
        switch w.kind {
        case .builtInGradient: return "Gradient"
        case .procedural: return "Procedural · \(w.proceduralKey ?? "")"
        case .video: return "Video (AVPlayer)"
        case .gif: return "GIF (local, WebKit)"
        case .gifURL: return "GIF (remote, WebKit)"
        case .image: return "Image"
        case .url: return "URL (deprecated)"
        }
    }

    private var libraryCard: some View {
        let bytes = library.totalSizeBytes
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .file
        let sizeStr = bytes > 0 ? formatter.string(fromByteCount: bytes) : "0 bytes"

        return VStack(alignment: .leading, spacing: 6) {
            row("Wallpapers", "\(library.wallpapers.count)")
            row("Total size on disk", sizeStr)
            row(
                "Location",
                library.libraryDir.path
                    .replacingOccurrences(of: NSHomeDirectory(), with: "~")
            )
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

    private var systemCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            row(
                "Waraq CPU",
                String(format: "%.1f%%", monitor.cpuPercent)
            )
            row(
                "Waraq memory",
                String(format: "%.1f MB", monitor.memoryMB)
            )
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

    private func profileCard(_ profile: DisplayProfile) -> some View {
        let wallpaper = library.wallpaper(forID: profile.wallpaperID)
        let isConnected = displayManager.displays.contains { display in
            DisplayHardwareID(displayID: display.id)?.key
                == profile.hardwareID.key
        }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isConnected ? Color.green : Color.secondary)
                    .frame(width: 6, height: 6)
                Text(profile.lastKnownName)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text(isConnected ? "CONNECTED" : "DISCONNECTED")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            row("Hardware ID", profile.formattedHardwareID)
            row("Saved wallpaper", wallpaper?.name ?? "Missing")
            row("Last seen", df.string(from: profile.lastSeen))
            if !isConnected {
                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        DisplayProfileStore.delete(
                            hardwareID: profile.hardwareID
                        )
                        profiles = DisplayProfileStore.allProfiles()
                    } label: {
                        Label("Forget", systemImage: "trash")
                            .font(.system(size: 11))
                    }
                    .controlSize(.small)
                }
                .padding(.top, 4)
            }
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

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
        }
    }
}
