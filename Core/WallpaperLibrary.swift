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
import Combine
import Foundation

@MainActor
final class WallpaperLibrary: ObservableObject {
    static let shared = WallpaperLibrary()

    @Published private(set) var wallpapers: [Wallpaper] = []

    let libraryDir: URL
    let wallpapersDir: URL
    let thumbnailsDir: URL
    let manifestURL: URL

    static let supportedVideoExtensions: Set<String> = [
        "mp4", "mov", "m4v",
    ]
    static let supportedGifExtensions: Set<String> = ["gif"]
    static var supportedAllExtensions: Set<String> {
        supportedVideoExtensions.union(supportedGifExtensions)
    }

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
        thumbnailsDir = libraryDir
            .appendingPathComponent("Thumbnails", isDirectory: true)
        manifestURL = libraryDir
            .appendingPathComponent("library.json")

        try? FileManager.default.createDirectory(
            at: wallpapersDir,
            withIntermediateDirectories: true
        )
        try? FileManager.default.createDirectory(
            at: thumbnailsDir,
            withIntermediateDirectories: true
        )

        load()
        seedBuiltInsIfNeeded()
        generateProceduralThumbnailsIfNeeded()
    }

    /// Capture a still for any procedural built-in that lacks a cached
    /// thumbnail, so Library/Configure/Onboarding show its real look
    /// instead of a flat gradient swatch. Runs off the main loop after
    /// init so it never blocks launch; posts objectWillChange as each
    /// thumbnail lands so dependent views refresh.
    private func generateProceduralThumbnailsIfNeeded() {
        let procedurals = wallpapers.filter(\.kind.isProcedural)
        guard !procedurals.isEmpty else { return }
        let folder = libraryDir
        Task { @MainActor in
            var didGenerate = false
            for wallpaper in procedurals where !hasThumbnail(for: wallpaper) {
                do {
                    try ProceduralThumbnailGenerator.generateThumbnail(
                        for: wallpaper, in: folder
                    )
                    didGenerate = true
                } catch {
                    // Silent: the gradient swatch fallback still works.
                    NSLog("Waraq: procedural thumb gen failed for \(wallpaper.id): \(error)")
                }
            }
            if didGenerate { objectWillChange.send() }
        }
    }

    // MARK: Import

    func importFile(at sourceURL: URL) throws -> Wallpaper {
        let ext = sourceURL.pathExtension.lowercased()
        guard Self.supportedAllExtensions.contains(ext) else {
            throw WallpaperImportError.unsupportedFormat(ext)
        }

        let kind: Wallpaper.Kind = Self.supportedGifExtensions
            .contains(ext) ? .gif : .video

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
            id: id, name: name, kind: kind,
            addedDate: Date(),
            relativePath: destFilename,
            fileSizeBytes: size
        )
        wallpapers.append(wallpaper)
        save()
        generateThumbnailAsync(for: wallpaper)
        return wallpaper
    }

    @discardableResult
    func importFolder(at folderURL: URL) -> [Wallpaper] {
        var imported: [Wallpaper] = []
        let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
        while let fileURL = enumerator?.nextObject() as? URL {
            let ext = fileURL.pathExtension.lowercased()
            guard Self.supportedAllExtensions.contains(ext) else {
                continue
            }
            if (try? importFile(at: fileURL)) != nil {
                if let last = wallpapers.last {
                    imported.append(last)
                }
            }
        }
        return imported
    }

    @discardableResult
    func importGifURL(_ urlString: String, name: String) throws -> Wallpaper {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()) else
        {
            throw WallpaperImportError.invalidURL(trimmed)
        }
        // Light validation: prefer .gif extension or known GIF hosts.
        let ext = url.pathExtension.lowercased()
        let host = url.host?.lowercased() ?? ""
        let likelyGif = ext == "gif" ||
            host.contains("giphy.com") ||
            host.contains("tenor.com") ||
            host.contains("imgur.com")
        guard likelyGif else {
            throw WallpaperImportError.invalidURL(
                "URL must point to a .gif file"
            )
        }

        let wallpaper = Wallpaper(
            id: UUID().uuidString,
            name: name.isEmpty ? trimmed : name,
            kind: .gifURL,
            addedDate: Date(),
            urlString: trimmed
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
        try? FileManager.default.removeItem(at: thumbnailURL(for: wallpaper))
        try? FileManager.default.removeItem(
            at: customThumbnailURL(for: wallpaper)
        )
        wallpapers.removeAll { $0.id == wallpaper.id }
        save()

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

    func restoreBuiltIns() {
        UserDefaults.standard.removeObject(
            forKey: "removedProceduralKeys"
        )
        seedBuiltInsIfNeeded(force: true)
    }

    func wallpaper(forID id: String) -> Wallpaper? {
        wallpapers.first { $0.id == id }
    }

    func replaceWallpaper(at index: Int, with new: Wallpaper) {
        guard index >= 0, index < wallpapers.count else { return }
        wallpapers[index] = new
        save()
    }

    func fileURL(for wallpaper: Wallpaper) -> URL? {
        guard let rel = wallpaper.relativePath else { return nil }
        return wallpapersDir.appendingPathComponent(rel)
    }

    func thumbnailURL(for wallpaper: Wallpaper) -> URL {
        thumbnailsDir.appendingPathComponent("\(wallpaper.id).jpg")
    }

    func hasThumbnail(for wallpaper: Wallpaper) -> Bool {
        FileManager.default.fileExists(
            atPath: thumbnailURL(for: wallpaper).path
        )
    }

    func customThumbnailURL(for wallpaper: Wallpaper) -> URL {
        thumbnailsDir.appendingPathComponent("\(wallpaper.id).custom.jpg")
    }

    func hasCustomThumbnail(for wallpaper: Wallpaper) -> Bool {
        FileManager.default.fileExists(
            atPath: customThumbnailURL(for: wallpaper).path
        )
    }

    /// Returns the URL of the thumbnail to display: custom if set,
    /// otherwise auto-generated.
    func displayThumbnailURL(for wallpaper: Wallpaper) -> URL {
        let custom = customThumbnailURL(for: wallpaper)
        if FileManager.default.fileExists(atPath: custom.path) {
            return custom
        }
        return thumbnailURL(for: wallpaper)
    }

    func hasAnyThumbnail(for wallpaper: Wallpaper) -> Bool {
        hasCustomThumbnail(for: wallpaper) || hasThumbnail(for: wallpaper)
    }

    func setCustomThumbnail(
        from imageURL: URL, for wallpaper: Wallpaper
    ) throws {
        guard let nsImage = NSImage(contentsOf: imageURL) else {
            throw NSError(
                domain: "Waraq", code: 1,
                userInfo: [NSLocalizedDescriptionKey:
                    "Could not read image file."]
            )
        }
        let resized = resize(image: nsImage, maxSize: NSSize(
            width: 480, height: 300
        ))
        guard let tiff = resized.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let jpeg = rep.representation(
                  using: .jpeg, properties: [.compressionFactor: 0.85]
              ) else
        {
            throw NSError(
                domain: "Waraq", code: 2,
                userInfo: [NSLocalizedDescriptionKey:
                    "Could not encode JPEG."]
            )
        }
        try jpeg.write(
            to: customThumbnailURL(for: wallpaper),
            options: .atomic
        )
        objectWillChange.send()
    }

    func clearCustomThumbnail(for wallpaper: Wallpaper) {
        let url = customThumbnailURL(for: wallpaper)
        try? FileManager.default.removeItem(at: url)
        objectWillChange.send()
    }

    private func resize(image: NSImage, maxSize: NSSize) -> NSImage {
        let originalSize = image.size
        let widthRatio = maxSize.width / originalSize.width
        let heightRatio = maxSize.height / originalSize.height
        let ratio = min(widthRatio, heightRatio, 1.0)
        let newSize = NSSize(
            width: originalSize.width * ratio,
            height: originalSize.height * ratio
        )
        let resized = NSImage(size: newSize)
        resized.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy, fraction: 1.0
        )
        resized.unlockFocus()
        return resized
    }

    var totalSizeBytes: Int64 {
        wallpapers.compactMap(\.fileSizeBytes).reduce(0, +)
    }

    // MARK: Thumbnails

    func generateThumbnailAsync(for wallpaper: Wallpaper) {
        guard wallpaper.kind == .video || wallpaper.kind == .gif,
              let fileURL = fileURL(for: wallpaper) else { return }
        let destURL = thumbnailURL(for: wallpaper)
        Task.detached(priority: .background) {
            await ThumbnailGenerator.generate(
                fileURL: fileURL,
                isGif: wallpaper.kind == .gif,
                outputURL: destURL
            )
            await MainActor.run {
                self.objectWillChange.send()
            }
        }
    }

    func regenerateAllThumbnails() {
        for wallpaper in wallpapers where !hasThumbnail(for: wallpaper) {
            generateThumbnailAsync(for: wallpaper)
        }
    }

    // MARK: Internal

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
                // Filter out deprecated .url kind (Phase 7 migration)
                if wallpaper.kind == .url { continue }
                // Validate file existence for file-backed kinds
                if wallpaper.kind == .video || wallpaper.kind == .gif
                    || wallpaper.kind == .image
                {
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
        // Kick off thumbnail backfill for any missing thumbnails
        regenerateAllThumbnails()
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
