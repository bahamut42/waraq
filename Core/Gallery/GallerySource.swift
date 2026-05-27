import Foundation

enum GallerySource: String, Codable, CaseIterable {
    case pixabay
    case pexels
    case nasa

    var displayName: String {
        switch self {
        case .pixabay: "Pixabay"
        case .pexels: "Pexels"
        case .nasa: "NASA"
        }
    }

    var websiteURL: URL {
        switch self {
        case .pixabay: URL(string: "https://pixabay.com/")!
        case .pexels: URL(string: "https://pexels.com/")!
        case .nasa: URL(string: "https://images.nasa.gov/")!
        }
    }

    var apiKeySignupURL: URL? {
        switch self {
        case .pixabay: URL(string: "https://pixabay.com/api/docs/")
        case .pexels: URL(string: "https://www.pexels.com/api/")
        case .nasa: nil // NASA API works without a key for low-volume use
        }
    }

    /// True if this source's client is fully implemented and ready to
    /// use. All current sources are implemented.
    var isImplemented: Bool {
        switch self {
        case .pixabay, .pexels, .nasa: true
        }
    }

    /// True if this source needs an API key. NASA's public library is
    /// open for low-volume use, so it skips the key entry entirely.
    var requiresAPIKey: Bool {
        switch self {
        case .pixabay, .pexels: true
        case .nasa: false
        }
    }
}
