import Foundation
import os

extension Logger {
    /// Diagnostic logging for the Gallery source clients. Filter in
    /// Console.app by subsystem "com.bahamut.waraq.gallery". Never log
    /// API keys here — only URLs, status codes, sizes, and counts.
    static let gallery = Logger(
        subsystem: "com.bahamut.waraq.gallery",
        category: "client"
    )
}

/// Shared formatting for user-visible Gallery client errors. Includes
/// the first 500 chars of the raw API response so decoding/HTTP
/// failures are diagnosable from the error card alone — no curl.
enum GalleryErrorText {
    /// Truncate a response body to a copy-pasteable snippet.
    static func rawSnippet(_ data: Data) -> String? {
        guard let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        return String(text.prefix(500))
    }

    static func http(_ source: String, code: Int, raw: String?) -> String {
        var msg = "\(source) returned HTTP \(code)."
        if let raw, !raw.isEmpty {
            msg += "\n\nRaw response (first 500 chars):\n\(raw)"
        }
        return msg
    }

    static func decoding(
        _ source: String, error: Error, raw: String?
    ) -> String {
        var msg = "\(source) response decoding failed: "
            + error.localizedDescription
        if let raw, !raw.isEmpty {
            msg += "\n\nRaw response (first 500 chars):\n\(raw)"
        }
        return msg
    }
}
