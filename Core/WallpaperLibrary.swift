import Combine
import Foundation

/// Manages the wallpaper collection on disk and in memory.
/// Persists imported wallpapers as `library.json`, copies imported
/// files into the Library `Wallpapers/` directory.
///
/// The built-in animated gradient is always present as the first
/// item and cannot be removed.
@MainActor
final class WallpaperLibrary: ObservableObject {
    static let shared = WallpaperLibrary()

    @Published private(set) var wallpapers: [Wallpaper] = []

    let libraryDir: URL
    let wallpapersDir: URL
    let manifestURL: URL

    static let supportedVideoExtensions: Set<String> = ["mp4", "mov", "m4v"]

    static let builtInGradient = Wallpaper(
        id: "com.bahamut.waraq.builtin.gradient",
        name: "Animated Gradient",
        kind: .builtInGradient,
        addedDate: Date.distantPast,
        relativePath: nil
    )

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        libraryDir = appSupport
            .appendingPathComponent("Waraq", isDirectory: true)
        wallpapersDir = libraryDir
            .appendingPathComponent("Wallpapers", isDirectory: true)
        manifestURL = libraryDir
            .appendingPathComponent("library.json")

        try? FileManager.default.createDirectory(
            at: wallpapersDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        load()
    }

    // Public API

    func importFile(at sourceURL: URL) throws -> Wallpaper {
        let ext = sourceURL.pathExtension.lowercased()
        guard Self.supportedVideoExtensions.contains(ext) else {
            throw WallpaperImportError.unsupportedFormat(ext)
        }

        let id = UUID().uuidString
        let destFilename = "\(id).\(ext)"
        let destURL = wallpapersDir.appendingPathComponent(destFilename)

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        } catch {
            throw WallpaperImportError.copyFailed(error)
        }

        var size: Int64?
        if let attrs = try? FileManager.default.attributesOfItem(
            atPath: destURL.path
        ), let bytes = attrs[.size] as? Int64 {
            size = bytes
        }

        var name = sourceURL.deletingPathExtension().lastPathComponent
        if name.isEmpty { name = "Untitled" }

        let wallpaper = Wallpaper(
            id: id,
            name: name,
            kind: .video,
            addedDate: Date(),
            relativePath: destFilename,
            fileSizeBytes: size
        )

        wallpapers.append(wallpaper)
        save()
        return wallpaper
    }

    func remove(_ wallpaper: Wallpaper) {
        guard wallpaper.kind != .builtInGradient else { return }
        if let rel = wallpaper.relativePath {
            let fileURL = wallpapersDir.appendingPathComponent(rel)
            try? FileManager.default.removeItem(at: fileURL)
        }
        wallpapers.removeAll { $0.id == wallpaper.id }
        save()
    }

    func wallpaper(forID id: String) -> Wallpaper? {
        wallpapers.first { $0.id == id }
    }

    func fileURL(for wallpaper: Wallpaper) -> URL? {
        guard let rel = wallpaper.relativePath else { return nil }
        return wallpapersDir.appendingPathComponent(rel)
    }

    var totalSizeBytes: Int64 {
        wallpapers.compactMap(\.fileSizeBytes).reduce(0, +)
    }

    // Persistence

    private func load() {
        var all: [Wallpaper] = [Self.builtInGradient]

        if let data = try? Data(contentsOf: manifestURL),
           let imported = try? JSONDecoder().decode(
               [Wallpaper].self, from: data
           )
        {
            // Verify files still exist; drop missing entries.
            for wallpaper in imported {
                if let rel = wallpaper.relativePath {
                    let url = wallpapersDir.appendingPathComponent(rel)
                    if FileManager.default.fileExists(atPath: url.path) {
                        all.append(wallpaper)
                    }
                }
            }
        }
        wallpapers = all
    }

    private func save() {
        let imported = wallpapers.filter {
            $0.kind != .builtInGradient
        }
        if let data = try? JSONEncoder().encode(imported) {
            try? data.write(to: manifestURL)
        }
    }
}
