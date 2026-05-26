import Foundation

/// A single wallpaper entry in the Library.
struct Wallpaper: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let kind: Kind
    let addedDate: Date
    /// Filename within the Library's `Wallpapers/` directory.
    /// Nil for the built-in gradient.
    let relativePath: String?

    enum Kind: String, Codable {
        case builtInGradient
        case video
        case image // reserved for Phase 7
    }

    /// File size in bytes if known.
    var fileSizeBytes: Int64?

    /// Human-readable size string. Computed.
    var fileSizeString: String? {
        guard let bytes = fileSizeBytes else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

enum WallpaperImportError: LocalizedError {
    case unsupportedFormat(String)
    case copyFailed(Error)
    case libraryUnavailable

    var errorDescription: String? {
        switch self {
        case let .unsupportedFormat(ext):
            "Unsupported file format: .\(ext). Try MP4, MOV, or M4V."
        case let .copyFailed(underlying):
            "Could not copy file to library: \(underlying.localizedDescription)"
        case .libraryUnavailable:
            "Library directory is not available."
        }
    }
}
