//  Waraq - A native macOS animated wallpaper app.
//  Copyright (C) 2026 Omar A. Othman
//
//  This program is free software: you can redistribute it
//  and/or modify it under the terms of the GNU General
//  Public License as published by the Free Software
//  Foundation, either version 3 of the License, or (at
//  your option) any later version.
//
//  This program is distributed in the hope that it will
//  be useful, but WITHOUT ANY WARRANTY; without even the
//  implied warranty of MERCHANTABILITY or FITNESS FOR A
//  PARTICULAR PURPOSE. See the GNU General Public License
//  for more details.
//
//  You should have received a copy of the GNU General
//  Public License along with this program. If not, see
//  <https://www.gnu.org/licenses/>.
//

import AppKit
import WebKit

/// WKWebView-backed engine for animated GIFs. Handles both local
/// files (file:// via baseURL) and remote URLs (https://) using
/// an HTML wrapper with CSS object-fit for all 5 fit modes.
@MainActor
final class GifEngine: NSObject {
    let webView: WKWebView
    var view: NSView {
        webView
    }

    private let source: Source
    private var fitMode: DisplaySettings.FitMode

    enum Source {
        case localFile(URL)
        case remoteURL(URL)
    }

    init(source: Source, fitMode: DisplaySettings.FitMode = .fill) {
        self.source = source
        self.fitMode = fitMode

        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.width, .height]

        super.init()

        webView.setValue(false, forKey: "drawsBackground")
        loadCurrent()
    }

    func updateFitMode(_ mode: DisplaySettings.FitMode) {
        guard mode != fitMode else { return }
        fitMode = mode
        loadCurrent()
    }

    func play() {
        // GIFs are auto-playing in browsers; the page just needs
        // to be present. Force a reload only if document is gone.
        webView.evaluateJavaScript("typeof document !== 'undefined'") {
            [weak self] result, _ in
            if result as? Bool != true {
                self?.loadCurrent()
            }
        }
    }

    func pause() {
        // No reliable GIF pause in standard HTML. Cost is
        // negligible (a few KB and a small render loop). Treat
        // as no-op.
    }

    // MARK: Private

    private func loadCurrent() {
        switch source {
        case let .localFile(url):
            let parent = url.deletingLastPathComponent()
            let html = generateHTML(
                src: url.lastPathComponent,
                fitMode: fitMode
            )
            webView.loadHTMLString(html, baseURL: parent)
        case let .remoteURL(url):
            let html = generateHTML(
                src: url.absoluteString,
                fitMode: fitMode
            )
            webView.loadHTMLString(
                html,
                baseURL: URL(string: "https://localhost")
            )
        }
    }

    private func generateHTML(
        src: String,
        fitMode: DisplaySettings.FitMode
    ) -> String {
        let escaped = src
            .replacingOccurrences(of: "'", with: "&apos;")
            .replacingOccurrences(of: "\"", with: "&quot;")

        switch fitMode {
        case .tile:
            return """
            <!DOCTYPE html>
            <html>
            <head>
            <style>
              html, body {
                margin: 0; padding: 0;
                width: 100vw; height: 100vh;
                background: #000;
                overflow: hidden;
              }
              .tile {
                width: 100vw; height: 100vh;
                background-image: url('\(escaped)');
                background-repeat: repeat;
                background-position: top left;
                background-size: auto;
              }
            </style>
            </head>
            <body><div class="tile"></div></body>
            </html>
            """
        case .center:
            return """
            <!DOCTYPE html>
            <html>
            <head>
            <style>
              html, body {
                margin: 0; padding: 0;
                width: 100vw; height: 100vh;
                background: #000;
                overflow: hidden;
              }
              .stage {
                width: 100vw; height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
              }
              img {
                max-width: 100%;
                max-height: 100%;
                width: auto;
                height: auto;
                display: block;
              }
            </style>
            </head>
            <body>
              <div class="stage"><img src="\(escaped)"></div>
            </body>
            </html>
            """
        case .fill, .fit, .stretch:
            let objectFit = switch fitMode {
            case .fill: "cover"
            case .fit: "contain"
            case .stretch: "fill"
            default: "cover"
            }
            return """
            <!DOCTYPE html>
            <html>
            <head>
            <style>
              html, body {
                margin: 0; padding: 0;
                width: 100vw; height: 100vh;
                background: #000;
                overflow: hidden;
              }
              img {
                width: 100vw;
                height: 100vh;
                object-fit: \(objectFit);
                display: block;
              }
            </style>
            </head>
            <body><img src="\(escaped)"></body>
            </html>
            """
        }
    }
}
