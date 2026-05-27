import Foundation

/// Curated bookmarks to external live-wallpaper sites. Anime/gaming
/// focused, since that's the content gap Pixabay/Pexels/NASA don't
/// fill. Not exhaustive — just reasonable known options. Waraq only
/// links out; all downloads happen between the user and the site.
enum ExternalSources {
    static let all: [GalleryExternalSource] = [
        GalleryExternalSource(
            id: "motionbgs",
            name: "MotionBGs",
            descriptionText: "9,000+ anime, gaming, and cyberpunk live wallpapers in 4K. Free for personal use.",
            symbolName: "sparkles.tv",
            websiteURL: URL(string: "https://motionbgs.com/")!,
            categoryTags: ["Anime", "Gaming", "4K"]
        ),
        GalleryExternalSource(
            id: "moewalls",
            name: "MoeWalls",
            descriptionText: "One of the largest anime live wallpaper libraries on the web. Curated daily.",
            symbolName: "star.fill",
            websiteURL: URL(string: "https://moewalls.com/")!,
            categoryTags: ["Anime", "Curated"]
        ),
        GalleryExternalSource(
            id: "mylivewallpapers",
            name: "MyLiveWallpapers",
            descriptionText: "Diverse community collection — anime, abstract, scenic, gaming.",
            symbolName: "circle.grid.3x3.fill",
            websiteURL: URL(string: "https://mylivewallpapers.com/")!,
            categoryTags: ["Diverse", "Community"]
        ),
        GalleryExternalSource(
            id: "wallsflow",
            name: "Wallsflow",
            descriptionText: "Anime, gaming, and abstract live wallpapers. Updated weekly.",
            symbolName: "wind",
            websiteURL: URL(string: "https://wallsflow.com/")!,
            categoryTags: ["Anime", "Gaming"]
        ),
    ]
}
