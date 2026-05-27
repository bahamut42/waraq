import Foundation

struct GalleryAttribution: Codable, Hashable {
    let creatorName: String
    let creatorURL: URL?
    let sourceName: String
    let sourceURL: URL
}
