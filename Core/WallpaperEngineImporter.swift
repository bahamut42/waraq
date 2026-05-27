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
import Foundation

/// Imports Wallpaper Engine .we archives (Steam Workshop format).
/// Phase 8 supports type=="video" only; scenes and web wallpapers
/// are rejected with a clear error.
@MainActor
enum WallpaperEngineImporter {
    enum ImportError: LocalizedError {
        case unzipFailed
        case missingProjectJSON
        case unsupportedType(String)
        case missingMediaFile(String)
        case underlyingLibraryError(Error)

        var errorDescription: String? {
            switch self {
            case .unzipFailed:
                "Could not unpack the .we archive."
            case .missingProjectJSON:
                "The .we archive doesn't contain a project.json."
            case let .unsupportedType(t):
                "Wallpaper type '\(t)' is not supported. Waraq currently imports video wallpapers only."
            case let .missingMediaFile(name):
                "Could not find the media file '\(name)' inside the archive."
            case let .underlyingLibraryError(e):
                e.localizedDescription
            }
        }
    }

    private struct ProjectJSON: Decodable {
        let title: String?
        let type: String?
        let file: String?
    }

    @discardableResult
    static func importArchive(at archiveURL: URL) throws -> Wallpaper {
        // Unzip to a temp directory.
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "waraq-we-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true
        )

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = [
            "-o", "-q", archiveURL.path, "-d", tempDir.path,
        ]
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                try? FileManager.default.removeItem(at: tempDir)
                throw ImportError.unzipFailed
            }
        } catch {
            try? FileManager.default.removeItem(at: tempDir)
            throw ImportError.unzipFailed
        }
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Find project.json (sometimes at root, sometimes nested).
        guard let projectJSONURL = findProjectJSON(in: tempDir) else {
            throw ImportError.missingProjectJSON
        }

        let data = try Data(contentsOf: projectJSONURL)
        let project = try JSONDecoder().decode(
            ProjectJSON.self, from: data
        )

        let type = (project.type ?? "").lowercased()
        guard type == "video" else {
            throw ImportError.unsupportedType(project.type ?? "unknown")
        }

        guard let fileName = project.file else {
            throw ImportError.missingMediaFile("")
        }

        // The media file lives next to project.json typically.
        let projectDir = projectJSONURL.deletingLastPathComponent()
        let mediaURL = projectDir.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: mediaURL.path) else {
            throw ImportError.missingMediaFile(fileName)
        }

        // Hand off to the library's standard file import.
        let library = WallpaperLibrary.shared
        do {
            let wallpaper = try library.importFile(at: mediaURL)
            // Override the name with the project's title if provided.
            if let title = project.title, !title.isEmpty {
                renameWallpaper(id: wallpaper.id, to: title)
            }
            return library.wallpaper(forID: wallpaper.id) ?? wallpaper
        } catch {
            throw ImportError.underlyingLibraryError(error)
        }
    }

    private static func findProjectJSON(in dir: URL) -> URL? {
        let directRoot = dir.appendingPathComponent("project.json")
        if FileManager.default.fileExists(atPath: directRoot.path) {
            return directRoot
        }
        // Look one level deep.
        guard let enumerator = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return nil }
        for case let url as URL in enumerator {
            if url.lastPathComponent == "project.json" {
                return url
            }
        }
        return nil
    }

    private static func renameWallpaper(id: String, to newName: String) {
        let library = WallpaperLibrary.shared
        guard let index = library.wallpapers.firstIndex(
            where: { $0.id == id }
        ) else { return }
        let existing = library.wallpapers[index]
        let renamed = Wallpaper(
            id: existing.id,
            name: newName,
            kind: existing.kind,
            addedDate: existing.addedDate,
            relativePath: existing.relativePath,
            urlString: existing.urlString,
            proceduralKey: existing.proceduralKey,
            fileSizeBytes: existing.fileSizeBytes
        )
        library.replaceWallpaper(at: index, with: renamed)
    }
}
