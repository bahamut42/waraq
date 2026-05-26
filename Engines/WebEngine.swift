import AppKit
import WebKit

@MainActor
final class WebEngine: NSObject {
    let webView: WKWebView
    var view: NSView {
        webView
    }

    init(url: URL) {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = false
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        let css = """
        html, body {
          margin: 0 !important;
          padding: 0 !important;
          overflow: hidden !important;
          background: transparent !important;
          width: 100% !important;
          height: 100% !important;
        }
        ::-webkit-scrollbar { display: none !important; }
        iframe, video {
          width: 100% !important;
          height: 100% !important;
          object-fit: cover;
        }
        """
        let script = """
        var style = document.createElement('style');
        style.innerHTML = `\(css)`;
        document.head.appendChild(style);
        """
        config.userContentController.addUserScript(
            WKUserScript(
                source: script,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.width, .height]

        super.init()

        webView.setValue(false, forKey: "drawsBackground")

        let target = Self.processURL(url) ?? url
        webView.load(URLRequest(url: target))
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

    static func processURL(_ url: URL) -> URL? {
        if let id = extractYouTubeID(from: url) {
            let s = "https://www.youtube.com/embed/\(id)?autoplay=1&loop=1&playlist=\(id)&controls=0&modestbranding=1&mute=1&disablekb=1&playsinline=1&iv_load_policy=3&rel=0&fs=0"
            return URL(string: s)
        }
        if let id = extractVimeoID(from: url) {
            let s = "https://player.vimeo.com/video/\(id)?autoplay=1&loop=1&muted=1&controls=0&background=1"
            return URL(string: s)
        }
        return nil
    }

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
