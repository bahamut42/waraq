import Combine
import Foundation

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
        addedDate: Date.distantPast
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
            withIntermediateDirectories: true
        )

        load()
        seedBuiltInsIfNeeded()
    }

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
            id: id, name: name, kind: .video,
            addedDate: Date(),
            relativePath: destFilename,
            fileSizeBytes: size
        )
        wallpapers.append(wallpaper)
        save()
        return wallpaper
    }

    @discardableResult
    func importURL(_ urlString: String, name: String) throws -> Wallpaper {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard URL(string: trimmed) != nil else {
            throw WallpaperImportError.invalidURL(trimmed)
        }

        let wallpaper = Wallpaper(
            id: UUID().uuidString,
            name: name.isEmpty ? trimmed : name,
            kind: .url,
            addedDate: Date(),
            urlString: trimmed
        )
        wallpapers.append(wallpaper)
        save()
        return wallpaper
    }

    func remove(_ wallpaper: Wallpaper) {
        // Animated Gradient can never be removed.
        guard wallpaper.kind != .builtInGradient else { return }

        if let rel = wallpaper.relativePath {
            let fileURL = wallpapersDir.appendingPathComponent(rel)
            try? FileManager.default.removeItem(at: fileURL)
        }
        wallpapers.removeAll { $0.id == wallpaper.id }
        save()

        // If procedural built-in was removed, note it so reseed
        // doesn't re-add it automatically. User can use "Restore"
        // to bring them back explicitly.
        if wallpaper.kind == .procedural,
           let key = wallpaper.proceduralKey
        {
            var removed = removedProceduralKeys
            removed.insert(key)
            UserDefaults.standard.set(
                Array(removed),
                forKey: "removedProceduralKeys"
            )
        }
    }

    /// Re-seed any procedural built-ins the user previously deleted.
    func restoreBuiltIns() {
        UserDefaults.standard.removeObject(
            forKey: "removedProceduralKeys"
        )
        seedBuiltInsIfNeeded(force: true)
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

    // Internal

    private var removedProceduralKeys: Set<String> {
        Set(UserDefaults.standard.array(
            forKey: "removedProceduralKeys"
        ) as? [String] ?? [])
    }

    private func seedBuiltInsIfNeeded(force: Bool = false) {
        let existing = Set(wallpapers.map(\.id))
        let removed = removedProceduralKeys

        for builtIn in ProceduralFactory.allBuiltIns {
            if existing.contains(builtIn.id) { continue }
            if !force, let key = builtIn.proceduralKey,
               removed.contains(key)
            {
                continue
            }
            wallpapers.append(builtIn)
        }
        save()
    }

    private func load() {
        var all: [Wallpaper] = [Self.builtInGradient]

        if let data = try? Data(contentsOf: manifestURL),
           let imported = try? JSONDecoder().decode(
               [Wallpaper].self, from: data
           )
        {
            for wallpaper in imported {
                // Validate file existence for file-backed kinds
                if wallpaper.kind == .video || wallpaper.kind == .image {
                    if let rel = wallpaper.relativePath {
                        let url = wallpapersDir.appendingPathComponent(rel)
                        if FileManager.default.fileExists(atPath: url.path) {
                            all.append(wallpaper)
                        }
                    }
                } else {
                    all.append(wallpaper)
                }
            }
        }
        wallpapers = all
    }

    private func save() {
        let serializable = wallpapers.filter {
            $0.kind != .builtInGradient
        }
        if let data = try? JSONEncoder().encode(serializable) {
            try? data.write(to: manifestURL)
        }
    }
}
