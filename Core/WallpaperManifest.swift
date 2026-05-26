import Foundation

/// Manifest format for .waraq wallpaper bundles.
struct WallpaperManifest: Codable {
    let schema: Int
    let id: String
    let name: String
    let author: String?
    let type: WallpaperType
    let entry: String

    enum WallpaperType: String, Codable {
        case video, web, image
    }
}
