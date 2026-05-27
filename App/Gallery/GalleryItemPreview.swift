import AVKit
import SwiftUI

/// Preview sheet shown when a tile is tapped. Plays the
/// medium-quality video on loop, muted, and offers "Add to
/// Library" (downloads the large quality + imports) or Cancel.
struct GalleryItemPreview: View {
    let item: GalleryItem
    let isDownloading: Bool
    let downloadError: String?
    let onAdd: () -> Void
    let onCancel: () -> Void

    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?

    var body: some View {
        VStack(spacing: 0) {
            header
            videoArea
            metadata
            Divider()
            footer
        }
        .frame(width: 560, height: 480)
        .onAppear(perform: startPlayback)
        .onDisappear(perform: stopPlayback)
    }

    private var header: some View {
        HStack {
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(12)
    }

    private var videoArea: some View {
        Group {
            if let player {
                PlayerContainerView(player: player)
            } else {
                Rectangle()
                    .fill(Color.black.opacity(0.85))
                    .overlay(ProgressView().controlSize(.large))
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
            Text("\(item.resolutionString) · \(item.durationString)")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text("by \(item.attribution.creatorName) on \(item.attribution.sourceName)")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            if let downloadError {
                Text(downloadError)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Spacer()
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.cancelAction)
            Button(action: onAdd) {
                if isDownloading {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Adding…")
                    }
                } else {
                    Text("Add to Library")
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(isDownloading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private func startPlayback() {
        let avPlayer = AVPlayer(url: item.previewVideoURL)
        avPlayer.isMuted = true
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: avPlayer.currentItem,
            queue: .main
        ) { _ in
            avPlayer.seek(to: .zero)
            avPlayer.play()
        }
        player = avPlayer
        avPlayer.play()
    }

    private func stopPlayback() {
        player?.pause()
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
        }
        loopObserver = nil
        player = nil
    }
}

/// Wraps AppKit's `AVPlayerView` directly. We deliberately avoid
/// SwiftUI's `VideoPlayer`: on this macOS/SDK combination, building
/// it crashes inside `_AVKit_SwiftUI` generic-metadata
/// instantiation (getSuperclassMetadata fatalError → SIGABRT).
/// AVPlayerView is stable and lets us hide the transport controls.
private struct PlayerContainerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context _: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .none
        view.videoGravity = .resizeAspect
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context _: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
    }
}
