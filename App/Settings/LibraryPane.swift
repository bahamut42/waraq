import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct LibraryPane: View {
    @StateObject private var library = WallpaperLibrary.shared
    @State private var searchQuery: String = ""
    @State private var typeFilter: TypeFilter = .all
    @State private var sortOrder: SortOrder = .recentlyAdded
    @State private var selectedID: String?
    @State private var importError: String?
    @State private var showingImportError: Bool = false

    enum TypeFilter: String, CaseIterable {
        case all = "All"
        case video = "Video"
        case image = "Image"
        case builtin = "Built-in"
    }

    enum SortOrder: String, CaseIterable {
        case recentlyAdded = "Recently added"
        case name = "Name"
        case type = "Type"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleRow
                toolbar
                counterLine
                wallpaperGrid
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .alert(
            "Import failed",
            isPresented: $showingImportError,
            actions: { Button("OK") {} },
            message: { Text(importError ?? "") }
        )
    }

    private var titleRow: some View {
        HStack {
            Text("Library")
                .font(.system(size: 22, weight: .medium))
                .tracking(-0.2)
            Spacer()
        }
        .padding(.bottom, 16)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                TextField("Search wallpapers", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Type filter
            Picker("", selection: $typeFilter) {
                ForEach(TypeFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            .labelsHidden()

            // Sort
            Menu {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button(order.rawValue) { sortOrder = order }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11))
                    Text("Sort")
                        .font(.system(size: 12))
                }
            }
            .menuStyle(.borderlessButton)
            .frame(width: 60)

            // Import
            Button {
                runImport()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                    Text("Import")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.bottom, 12)
    }

    private var counterLine: some View {
        let count = filteredAndSorted.count
        let bytes = library.totalSizeBytes
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .file
        let sizeString = bytes > 0
            ? formatter.string(fromByteCount: bytes) : "0 bytes"
        return Text("\(count) wallpaper\(count == 1 ? "" : "s") · \(sizeString)")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.bottom, 12)
            .padding(.horizontal, 2)
    }

    private var wallpaperGrid: some View {
        LazyVGrid(
            columns: [GridItem(
                .adaptive(minimum: 140, maximum: 200),
                spacing: 10
            )],
            spacing: 10
        ) {
            ForEach(filteredAndSorted) { wallpaper in
                WallpaperCard(
                    wallpaper: wallpaper,
                    isSelected: wallpaper.id == selectedID
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedID = wallpaper.id
                }
                .contextMenu {
                    if wallpaper.kind != .builtInGradient {
                        Button(role: .destructive) {
                            library.remove(wallpaper)
                            if selectedID == wallpaper.id {
                                selectedID = nil
                            }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    } else {
                        Text("Built-in wallpapers cannot be removed")
                    }
                }
            }
        }
    }

    private var filteredAndSorted: [Wallpaper] {
        var items = library.wallpapers

        // Type filter
        switch typeFilter {
        case .all: break
        case .video: items = items.filter { $0.kind == .video }
        case .image: items = items.filter { $0.kind == .image }
        case .builtin: items = items.filter {
                $0.kind == .builtInGradient
            }
        }

        // Search
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            items = items.filter {
                $0.name.localizedCaseInsensitiveContains(query)
            }
        }

        // Sort
        switch sortOrder {
        case .recentlyAdded:
            items.sort { $0.addedDate > $1.addedDate }
        case .name:
            items.sort {
                $0.name.localizedCaseInsensitiveCompare($1.name)
                    == .orderedAscending
            }
        case .type:
            items.sort { $0.kind.rawValue < $1.kind.rawValue }
        }

        return items
    }

    private func runImport() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "mp4")!,
            UTType(filenameExtension: "mov")!,
            UTType(filenameExtension: "m4v")!,
        ]
        panel.title = "Import wallpapers"
        panel.message = "Select MP4, MOV, or M4V files"

        let response = panel.runModal()
        guard response == .OK else { return }

        for url in panel.urls {
            do {
                _ = try library.importFile(at: url)
            } catch let error as WallpaperImportError {
                importError = error.errorDescription
                showingImportError = true
            } catch {
                importError = error.localizedDescription
                showingImportError = true
            }
        }
    }
}

private struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                thumbnail
                typePill
            }
            footer
        }
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected
                        ? Color.accentColor
                        : Color.primary.opacity(0.08),
                    lineWidth: isSelected ? 2 : 0.5
                )
        )
    }

    private var thumbnail: some View {
        Rectangle()
            .fill(thumbnailGradient)
            .aspectRatio(16.0 / 10.0, contentMode: .fit)
    }

    private var thumbnailGradient: LinearGradient {
        switch wallpaper.kind {
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
            // Phase 6: replace with real first-frame thumbnail
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
                    Color(red: 0.20, green: 0.20, blue: 0.20),
                    Color(red: 0.10, green: 0.10, blue: 0.10),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var typePill: some View {
        HStack(spacing: 4) {
            Image(systemName: typeIcon)
                .font(.system(size: 9))
            Text(typeLabel)
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(8)
    }

    private var typeIcon: String {
        switch wallpaper.kind {
        case .builtInGradient: "sparkles"
        case .video: "play.fill"
        case .image: "photo"
        }
    }

    private var typeLabel: String {
        switch wallpaper.kind {
        case .builtInGradient: "BUILT-IN"
        case .video: "VIDEO"
        case .image: "IMAGE"
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(wallpaper.name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
            Text(metaLine)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metaLine: String {
        switch wallpaper.kind {
        case .builtInGradient:
            "Lightweight · Always available"
        case .video:
            wallpaper.fileSizeString ?? "Video"
        case .image:
            wallpaper.fileSizeString ?? "Still image"
        }
    }
}
