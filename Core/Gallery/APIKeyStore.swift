import Foundation

/// Stores per-source API keys in UserDefaults. Keys are not
/// secrets in the cryptographic sense (they identify
/// rate-limit buckets, not personal data), so UserDefaults is
/// adequate. Stored locally; never transmitted except as
/// query parameters to the relevant API host.
enum APIKeyStore {
    static func key(for source: GallerySource) -> String? {
        let key = userDefaultsKey(for: source)
        let raw = UserDefaults.standard.string(forKey: key) ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func setKey(_ key: String?, for source: GallerySource) {
        let trimmed = key?.trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""
        let defaultsKey = userDefaultsKey(for: source)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: defaultsKey)
        }
    }

    static func hasKey(for source: GallerySource) -> Bool {
        key(for: source) != nil
    }

    private static func userDefaultsKey(for source: GallerySource) -> String {
        "GalleryAPIKey.\(source.rawValue)"
    }
}
