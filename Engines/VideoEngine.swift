import AppKit
import AVFoundation

/// AVPlayer-backed wallpaper engine. Loops a video file forever.
///
/// Phase 1 implementation. Performance governor integration arrives
/// in Phase 3, see docs/design/settings-performance.md.
final class VideoEngine {
    private let player: AVPlayer
    private let playerItem: AVPlayerItem
    let layer: AVPlayerLayer

    init(videoURL: URL) {
        playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)

        // Wallpapers should never make sound by default.
        player.isMuted = true
        player.actionAtItemEnd = .none

        layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    @objc
    private func playerDidReachEnd() {
        player.seek(to: .zero)
        player.play()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        player.pause()
    }
}
