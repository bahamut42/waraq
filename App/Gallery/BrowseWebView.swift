import AppKit
import SwiftUI

/// Curated bookmark cards for external live-wallpaper sites. Purely
/// informational: nothing is fetched, rendered, or proxied — each card
/// just opens the site in the user's default browser. The user
/// downloads manually and drags the MP4 into Library.
struct BrowseWebView: View {
    let sources: [GalleryExternalSource] = ExternalSources.all

    private static let howItWorks = [
        "1. Click a source to open it in your browser.",
        "2. Find a wallpaper you like and download the .mp4.",
        "3. Drag the file onto Waraq's Library tab.",
        "",
        "Waraq does not host, mirror, or redistribute external "
            + "content. Downloads happen directly between you and "
            + "the source site, under their personal-use terms.",
    ].joined(separator: "\n")

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                introHeader
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(sources) { source in
                        BrowseWebCard(source: source)
                    }
                }
                howItWorksFooter
            }
            .padding(.vertical, 2)
        }
    }

    private var introHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("More Wallpapers")
                .font(.system(size: 16, weight: .semibold))
            Text(
                "Browse curated external sites for anime, gaming, and themed live wallpapers. Download in your browser, then drag the MP4 onto the Library tab."
            )
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var howItWorksFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("How it works")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 11))
            }
            Text(Self.howItWorks)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.05))
        )
    }
}

struct BrowseWebCard: View {
    let source: GalleryExternalSource

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: source.symbolName)
                    .font(.system(size: 22))
                    .foregroundStyle(.tint)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentColor.opacity(0.12))
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.name)
                        .font(.system(size: 14, weight: .semibold))
                    Text(source.websiteURL.host ?? "")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text(source.descriptionText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                ForEach(source.categoryTags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Button {
                NSWorkspace.shared.open(source.websiteURL)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "safari")
                        .font(.system(size: 11))
                    Text("Open in Browser")
                        .font(.system(size: 12))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
    }
}
