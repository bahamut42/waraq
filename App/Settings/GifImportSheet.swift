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

import SwiftUI

/// Sheet for adding a remote GIF URL to the library.
struct GifImportSheet: View {
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
            Text("Import GIF from URL")
                .font(.system(size: 15, weight: .medium))
            Text("Paste a direct GIF URL (ending in .gif, or from Giphy/Tenor/Imgur).")
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
                TextField(
                    "https://media.giphy.com/.../giphy.gif",
                    text: $urlString
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))
                .onChange(of: urlString) { _, _ in autofillName() }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("My GIF wallpaper", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }

            if let detected = detectedSource {
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
                .disabled(!looksValid)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.primary.opacity(0.03))
    }

    private var looksValid: Bool {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else { return false }
        return true
    }

    private struct Detected {
        let icon: String
        let color: Color
        let description: String
    }

    private var detectedSource: Detected? {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)),
              let host = url.host?.lowercased() else { return nil }

        let ext = url.pathExtension.lowercased()
        if ext == "gif" {
            return Detected(
                icon: "photo.stack",
                color: .green,
                description: "Direct GIF · will stream and animate"
            )
        }
        if host.contains("giphy.com") {
            return Detected(
                icon: "photo.stack",
                color: .pink,
                description: "Giphy URL · use the direct media link ending in .gif"
            )
        }
        if host.contains("tenor.com") {
            return Detected(
                icon: "photo.stack",
                color: .blue,
                description: "Tenor URL · use the direct media link ending in .gif"
            )
        }
        return Detected(
            icon: "questionmark.circle",
            color: .orange,
            description: "Not recognized as a GIF URL"
        )
    }

    private func autofillName() {
        errorText = nil
        if name.isEmpty,
           let url = URL(string: urlString.trimmingCharacters(in: .whitespaces))
        {
            let last = url.deletingPathExtension().lastPathComponent
            if !last.isEmpty, last != "/" {
                name = last
            } else if let host = url.host {
                name = host.replacingOccurrences(of: "www.", with: "")
            }
        }
    }

    private func addToLibrary() {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        let displayName = name.trimmingCharacters(in: .whitespaces).isEmpty
            ? trimmed : name
        do {
            _ = try library.importGifURL(trimmed, name: displayName)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
