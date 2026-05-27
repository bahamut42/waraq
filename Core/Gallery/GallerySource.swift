import Foundation

enum GallerySource: String, Codable, CaseIterable {
    case pixabay
    case pexels
    case coverr // reserved for 9.8c
    case nasa // reserved for 9.8d

    var displayName: String {
        switch self {
        case .pixabay: "Pixabay"
        case .pexels: "Pexels"
        case .coverr: "Coverr"
        case .nasa: "NASA"
        }
    }

    var websiteURL: URL {
        switch self {
        case .pixabay: URL(string: "https://pixabay.com/")!
        case .pexels: URL(string: "https://pexels.com/")!
        case .coverr: URL(string: "https://coverr.co/")!
        case .nasa: URL(string: "https://images.nasa.gov/")!
        }
    }

    var apiKeySignupURL: URL? {
        switch self {
        case .pixabay: URL(string: "https://pixabay.com/api/docs/")
        case .pexels: URL(string: "https://www.pexels.com/api/")
        case .coverr: URL(string: "https://coverr.co/developers")
        case .nasa: nil // NASA API works without a key for low-volume use
        }
    }

    /// True if this source's client is fully implemented and ready to
    /// use. Sources still in stub state return false; the Gallery UI
    /// shows a "Coming soon" notice for them. Flipped to true in each
    /// source's own phase.
    var isImplemented: Bool {
        switch self {
        case .pixabay, .pexels, .coverr: true
        case .nasa: false
        }
    }
}
