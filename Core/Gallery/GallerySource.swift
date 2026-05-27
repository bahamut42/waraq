import Foundation

enum GallerySource: String, Codable, CaseIterable {
    case pixabay
    case pexels // reserved for 9.8b
    case mixkit // reserved for 9.8c

    var displayName: String {
        switch self {
        case .pixabay: "Pixabay"
        case .pexels: "Pexels"
        case .mixkit: "Mixkit"
        }
    }

    var websiteURL: URL {
        switch self {
        case .pixabay: URL(string: "https://pixabay.com/")!
        case .pexels: URL(string: "https://pexels.com/")!
        case .mixkit: URL(string: "https://mixkit.co/")!
        }
    }

    var apiKeySignupURL: URL? {
        switch self {
        case .pixabay: URL(string: "https://pixabay.com/api/docs/")
        case .pexels: URL(string: "https://www.pexels.com/api/")
        case .mixkit: nil
        }
    }
}
