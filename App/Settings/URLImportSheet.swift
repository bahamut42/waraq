import SwiftUI

struct URLImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var library = WallpaperLibrary.shared

    @State private var urlString: String = ""
    @State private var name: String = ""
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            content
            footer
        }
        .frame(width: 480, height: 360)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Import from URL")
                .font(.system(size: 15, weight: .medium))
            Text("Paste a YouTube, Vimeo, direct video, or web page URL.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("URL")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("https://youtu.be/...", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                    .onChange(of: urlString) { _, _ in autofillName() }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("My wallpaper", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }

            if let detected = detectedKind {
                HStack(spacing: 8) {
                    Image(systemName: detected.icon)
                        .foregroundStyle(detected.color)
                    Text(detected.description)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }

            if let errorText {
                Text(errorText)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Cancel") { dismiss() }.controlSize(.large)
            Button("Add to Library") { addToLibrary() }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidURL)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.primary.opacity(0.03))
    }

    private var isValidURL: Bool {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)) else { return false }
        return url.host != nil &&
            (url.scheme == "http" || url.scheme == "https")
    }

    private struct Detected {
        let icon: String
        let color: Color
        let description: String
    }

    private var detectedKind: Detected? {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)),
              url.host != nil else { return nil }
        if WebEngine.extractYouTubeID(from: url) != nil {
            return Detected(
                icon: "play.rectangle.fill",
                color: .red,
                description: "YouTube · will autoplay, loop, mute"
            )
        }
        if WebEngine.extractVimeoID(from: url) != nil {
            return Detected(
                icon: "play.rectangle.fill",
                color: .blue,
                description: "Vimeo · will autoplay, loop, mute"
            )
        }
        if WebEngine.isDirectVideo(url) {
            return Detected(
                icon: "video.fill",
                color: .green,
                description: "Direct video · streams via AVPlayer"
            )
        }
        return Detected(
            icon: "globe",
            color: .blue,
            description: "Web page · renders in WKWebView"
        )
    }

    private func autofillName() {
        errorText = nil
        if name.isEmpty,
           let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)),
           let host = url.host
        {
            name = host.replacingOccurrences(of: "www.", with: "")
        }
    }

    private func addToLibrary() {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard URL(string: trimmed) != nil else {
            errorText = "That doesn't look like a valid URL."
            return
        }
        let displayName = name.trimmingCharacters(in: .whitespaces).isEmpty
            ? trimmed : name
        do {
            _ = try library.importURL(trimmed, name: displayName)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
