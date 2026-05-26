import AppKit
import AVFoundation

final class VideoEngine {
    private let player: AVPlayer
    private let playerItem: AVPlayerItem
    let layer: AVPlayerLayer

    var isMuted: Bool {
        get { player.isMuted }
        set { player.isMuted = newValue }
    }

    var volume: Float {
        get { player.volume }
        set { player.volume = newValue }
    }

    var fitMode: DisplaySettings.FitMode {
        didSet { applyFitMode() }
    }

    var loop: Bool = true

    init(videoURL: URL, fitMode: DisplaySettings.FitMode = .fill) {
        playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        player.isMuted = true
        player.actionAtItemEnd = .none

        layer = AVPlayerLayer(player: player)
        self.fitMode = fitMode
        applyFitMode()

        NotificationCenter.default.addObserver(
            self, selector: #selector(playerDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime, object: playerItem
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
        guard loop else { return }
        player.seek(to: .zero)
        player.play()
    }

    private func applyFitMode() {
        switch fitMode {
        case .fill: layer.videoGravity = .resizeAspectFill
        case .fit: layer.videoGravity = .resizeAspect
        case .stretch: layer.videoGravity = .resize
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        player.pause()
    }
}
