import SwiftUI

/// A single grid tile: thumbnail still from the source CDN with
/// a play-icon overlay and a duration badge. The thumbnail URL
/// is a transient browse-time render (Pixabay CDN) — nothing is
/// persisted until the user explicitly adds to the library.
struct GalleryItemTile: View {
    let item: GalleryItem

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            thumbnail
            durationBadge
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
    }

    private var thumbnail: some View {
        AsyncImage(url: item.thumbnailURL) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .aspectRatio(16.0 / 9.0, contentMode: .fill)
            case .failure:
                placeholder(systemImage: "exclamationmark.triangle")
            case .empty:
                placeholder(systemImage: "photo")
                    .overlay(ProgressView().controlSize(.small))
            @unknown default:
                placeholder(systemImage: "photo")
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .background(Color.primary.opacity(0.05))
        .overlay(playIcon)
    }

    private func placeholder(systemImage: String) -> some View {
        Rectangle()
            .fill(Color.primary.opacity(0.05))
            .overlay(
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(.tertiary)
            )
    }

    private var playIcon: some View {
        Image(systemName: "play.circle.fill")
            .font(.system(size: 28))
            .foregroundStyle(.white.opacity(0.9))
            .shadow(radius: 3)
    }

    private var durationBadge: some View {
        Text(item.durationString)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.black.opacity(0.55), in: Capsule())
            .padding(6)
    }
}
