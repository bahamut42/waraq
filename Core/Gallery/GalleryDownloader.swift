import Foundation

/// Downloads a GalleryItem's video to a temp file and registers
/// it in the user's WallpaperLibrary via the existing
/// `importFile(at:)` API (which copies into the library folder
/// and generates a thumbnail). We never re-implement library
/// state here.
struct GalleryDownloader {
    let library: WallpaperLibrary

    enum DownloadError: Error, LocalizedError {
        case downloadFailed(Int)
        case importFailed(Error)

        var errorDescription: String? {
            switch self {
            case let .downloadFailed(code):
                "Download failed (HTTP \(code))."
            case let .importFailed(error):
                "Library import failed: \(error.localizedDescription)"
            }
        }
    }

    /// Downloads the large-quality MP4 to a temp file with a
    /// meaningful name, hands it to WallpaperLibrary.importFile
    /// (which copies it in and generates a thumbnail), then
    /// cleans up the temp file. Returns the new wallpaper's ID.
    ///
    /// Note: WallpaperLibrary.importFile(at:) does not accept
    /// attribution, so creator/source metadata is not persisted
    /// in 9.8a. Attribution is still shown in the preview before
    /// the user downloads. Persisting it is deferred.
    func download(_ item: GalleryItem) async throws -> String {
        let (tempURL, response) = try await URLSession.shared
            .download(from: item.downloadVideoURL)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard code == 200 else {
            throw DownloadError.downloadFailed(code)
        }

        // Rename the temp file so the imported Wallpaper.name is
        // human-readable (importFile derives the name from the
        // source filename).
        let fm = FileManager.default
        let safeName = Self.sanitizedFilename(item.title)
        let named = tempURL.deletingLastPathComponent()
            .appendingPathComponent("\(safeName).mp4")
        try? fm.removeItem(at: named)
        try fm.moveItem(at: tempURL, to: named)
        defer { try? fm.removeItem(at: named) }

        do {
            let wallpaper = try await library.importFile(at: named)
            return wallpaper.id
        } catch {
            throw DownloadError.importFailed(error)
        }
    }

    private static func sanitizedFilename(_ raw: String) -> String {
        let illegal = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let cleaned = raw
            .components(separatedBy: illegal)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Pixabay Video" : cleaned
    }
}
