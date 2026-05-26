import AppKit
import WebKit

@MainActor
final class WebEngine: NSObject {
    let webView: WKWebView
    var view: NSView {
        webView
    }

    /// Safari 17 desktop UA so YouTube serves the standard embed
    /// rather than detecting an unknown browser.
    private static let userAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    init(url: URL) {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = false
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.width, .height]

        super.init()

        // Transparent background (Plash-style trick, stable since 10.10).
        webView.setValue(false, forKey: "drawsBackground")

        // Identify as Safari so YouTube and Vimeo accept the embed.
        webView.customUserAgent = Self.userAgent

        loadContent(for: url)
    }

    private func loadContent(for url: URL) {
        if let id = Self.extractYouTubeID(from: url) {
            loadYouTubeEmbed(videoID: id)
        } else if let id = Self.extractVimeoID(from: url) {
            loadVimeoEmbed(videoID: id)
        } else {
            webView.load(URLRequest(url: url))
        }
    }

    private func loadYouTubeEmbed(videoID: String) {
        // Wrap the iframe in HTML so Webkit treats the page as a
        // first-class document. Loading the embed URL directly
        // sometimes triggers Error 153 in WKWebView.
        //
        // The iframe is sized to fill the viewport using the
        // 16:9 aspect-fill trick: width = 177.78vh (16/9 * 100),
        // min-width/height clamp to viewport.
        let src = "https://www.youtube-nocookie.com/embed/\(videoID)?autoplay=1&loop=1&playlist=\(videoID)&controls=0&showinfo=0&modestbranding=1&mute=1&disablekb=1&playsinline=1&iv_load_policy=3&rel=0&fs=0"

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          html, body {
            margin: 0 !important;
            padding: 0 !important;
            height: 100vh !important;
            width: 100vw !important;
            background: #000 !important;
            overflow: hidden !important;
          }
          .stage {
            position: absolute;
            top: 0; left: 0;
            width: 100vw;
            height: 100vh;
            overflow: hidden;
          }
          iframe {
            position: absolute;
            top: 50%; left: 50%;
            width: 177.78vh;
            height: 100vh;
            min-width: 100vw;
            min-height: 56.25vw;
            transform: translate(-50%, -50%);
            border: 0;
            pointer-events: none;
          }
        </style>
        </head>
        <body>
          <div class="stage">
            <iframe
              src="\(src)"
              allow="autoplay; encrypted-media"
              allowfullscreen>
            </iframe>
          </div>
        </body>
        </html>
        """

        webView.loadHTMLString(
            html,
            baseURL: URL(string: "https://www.youtube.com")
        )
    }

    private func loadVimeoEmbed(videoID: String) {
        let src = "https://player.vimeo.com/video/\(videoID)?autoplay=1&loop=1&muted=1&controls=0&background=1"
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
          html, body {
            margin: 0; padding: 0;
            height: 100vh; width: 100vw;
            background: #000;
            overflow: hidden;
          }
          iframe {
            position: absolute;
            top: 50%; left: 50%;
            width: 177.78vh;
            height: 100vh;
            min-width: 100vw;
            min-height: 56.25vw;
            transform: translate(-50%, -50%);
            border: 0;
            pointer-events: none;
          }
        </style>
        </head>
        <body>
          <iframe
            src="\(src)"
            allow="autoplay; encrypted-media"
            allowfullscreen>
          </iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(
            html,
            baseURL: URL(string: "https://vimeo.com")
        )
    }

    func play() {
        webView.evaluateJavaScript(
            "document.querySelectorAll('video').forEach(v => { v.muted = true; v.play().catch(() => {}); });",
            completionHandler: nil
        )
    }

    func pause() {
        webView.evaluateJavaScript(
            "document.querySelectorAll('video').forEach(v => v.pause());",
            completionHandler: nil
        )
    }

    // Static helpers (unchanged from Phase 6, kept here for reference)

    static func extractYouTubeID(from url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        if host.contains("youtu.be") {
            let id = url.path.replacingOccurrences(of: "/", with: "")
            return id.isEmpty ? nil : id
        }
        if host.contains("youtube.com") {
            if url.path.hasPrefix("/embed/") || url.path.hasPrefix("/v/") {
                return url.lastPathComponent
            }
            if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let v = comps.queryItems?.first(where: { $0.name == "v" })?.value
            {
                return v
            }
        }
        return nil
    }

    static func extractVimeoID(from url: URL) -> String? {
        guard let host = url.host?.lowercased(),
              host.contains("vimeo.com") else { return nil }
        for comp in url.pathComponents where Int(comp) != nil {
            return comp
        }
        return nil
    }

    static func isDirectVideo(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["mp4", "mov", "m4v", "webm"].contains(ext)
    }
}
