import Foundation

/// External wallpaper source. Unlike GallerySource (which has an API
/// client), these are just curated links — users browse in their
/// default browser, download manually under each site's personal-use
/// license, then drag the downloaded MP4 into Waraq's Library.
///
/// Waraq does not scrape, proxy, mirror, or redistribute any external
/// site's content. These are bookmarks.
struct GalleryExternalSource: Identifiable, Hashable {
    let id: String
    let name: String
    let descriptionText: String
    let symbolName: String // SF Symbol
    let websiteURL: URL
    let categoryTags: [String]
}
