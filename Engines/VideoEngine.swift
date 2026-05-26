import AppKit
import AVFoundation

/// AVPlayer-backed wallpaper engine. Loops a video file forever.
///
/// Phase 1 baseline, Phase 2 exposes mute control.
final class VideoEngine {
    private let player: AVPlayer
    private let playerItem: AVPlayerItem
    let layer: AVPlayerLayer

    var isMuted: Bool {
        get { player.isMuted }
        set { player.isMuted = newValue }
    }

    init(videoURL: URL) {
        playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
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
