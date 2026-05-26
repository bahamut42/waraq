import SwiftUI

/// Per-display wallpaper picker sheet. Phase 5 version: just the
/// wallpaper choice. Per-display volume/fit/mute arrive in Phase 6.
struct DisplayConfigSheet: View {
    let display: DisplayManager.DisplayInfo

    @EnvironmentObject var displayManager: DisplayManager
    @StateObject private var library = WallpaperLibrary.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedID: String

    init(display: DisplayManager.DisplayInfo) {
        self.display = display
        let assignments = UserDefaults.standard.dictionary(
            forKey: "displayWallpaperAssignments"
        ) as? [String: String] ?? [:]
        let initial = assignments[String(display.id)]
            ?? WallpaperLibrary.builtInGradient.id
        _selectedID = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            grid
            footer
        }
        .frame(width: 540, height: 540)
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

    private var grid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(
                    .adaptive(
                        minimum: 130,
                        maximum: 180
                    ),
                    spacing: 10
                )],
                spacing: 10
            ) {
                ForEach(library.wallpapers) { wallpaper in
                    pickerCard(wallpaper)
                        .onTapGesture {
                            selectedID = wallpaper.id
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    private func pickerCard(_ wallpaper: Wallpaper) -> some View {
        let isSelected = wallpaper.id == selectedID
        return VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(thumbnailGradient(for: wallpaper.kind))
                .aspectRatio(16.0 / 10.0, contentMode: .fit)
            VStack(alignment: .leading, spacing: 2) {
                Text(wallpaper.name)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Text(typeLabel(wallpaper.kind))
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

    private func thumbnailGradient(for kind: Wallpaper.Kind)
        -> LinearGradient
    {
        switch kind {
        case .builtInGradient:
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.10, blue: 0.22),
                    Color(red: 0.24, green: 0.06, blue: 0.12),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .video:
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.18, blue: 0.30),
                    Color(red: 0.10, green: 0.12, blue: 0.18),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .image:
            LinearGradient(
                colors: [
                    Color.gray.opacity(0.4),
                    Color.gray.opacity(0.2),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func typeLabel(_ kind: Wallpaper.Kind) -> String {
        switch kind {
        case .builtInGradient: "BUILT-IN"
        case .video: "VIDEO"
        case .image: "IMAGE"
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Cancel") { dismiss() }
                .controlSize(.large)
            Button("Done") {
                displayManager.reassignWallpaper(
                    displayID: display.id,
                    wallpaperID: selectedID
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
