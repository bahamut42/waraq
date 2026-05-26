import AppKit
import AVFoundation

final class VideoEngine: NSObject {
    private let player: AVPlayer
    private let playerItem: AVPlayerItem

    /// Container layer that's installed in the wallpaper window.
    /// Holds the player layer (and possibly a CAReplicatorLayer for
    /// Tile mode) at appropriate sizes and positions.
    let containerLayer: CALayer

    /// The actual AVPlayerLayer. Exposed for tests.
    let playerLayer: AVPlayerLayer

    /// Public interface for WallpaperWindow.install(layer:)
    var layer: CALayer {
        containerLayer
    }

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

    private var presentationSizeObserver: NSKeyValueObservation?

    init(videoURL: URL, fitMode: DisplaySettings.FitMode = .fill) {
        playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        player.isMuted = true
        player.actionAtItemEnd = .none

        containerLayer = CALayer()
        containerLayer.backgroundColor = NSColor.black.cgColor
        containerLayer.autoresizingMask = [
            .layerWidthSizable, .layerHeightSizable,
        ]

        playerLayer = AVPlayerLayer(player: player)
        self.fitMode = fitMode

        super.init()

        applyFitMode()

        // Re-apply fit when presentation size becomes known
        // (needed for Center and Tile which depend on video size).
        presentationSizeObserver = playerItem.observe(
            \.presentationSize, options: [.new]
        ) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.applyFitMode()
            }
        }

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

    /// Rebuild the container's sublayers based on the current fit
    /// mode. Called on init, on fit change, and when video
    /// presentation size becomes known.
    private func applyFitMode() {
        // Disable implicit animations during layer rebuild so we
        // don't get fade transitions between fit modes.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        containerLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let displayBounds = containerLayer.bounds
        // Containerlayer.bounds may be .zero if not yet sized.
        // We still set up the layer; autoresizing applies once
        // installed in a sized parent.

        switch fitMode {
        case .fill:
            playerLayer.videoGravity = .resizeAspectFill
            playerLayer.frame = displayBounds
            playerLayer.autoresizingMask = [
                .layerWidthSizable, .layerHeightSizable,
            ]
            containerLayer.addSublayer(playerLayer)

        case .fit:
            playerLayer.videoGravity = .resizeAspect
            playerLayer.frame = displayBounds
            playerLayer.autoresizingMask = [
                .layerWidthSizable, .layerHeightSizable,
            ]
            containerLayer.addSublayer(playerLayer)

        case .stretch:
            playerLayer.videoGravity = .resize
            playerLayer.frame = displayBounds
            playerLayer.autoresizingMask = [
                .layerWidthSizable, .layerHeightSizable,
            ]
            containerLayer.addSublayer(playerLayer)

        case .center:
            let natural = naturalSize(fallback: CGSize(
                width: displayBounds.width / 2,
                height: displayBounds.height / 2
            ))
            playerLayer.videoGravity = .resize
            playerLayer.autoresizingMask = []
            playerLayer.frame = CGRect(
                x: (displayBounds.width - natural.width) / 2,
                y: (displayBounds.height - natural.height) / 2,
                width: natural.width,
                height: natural.height
            )
            containerLayer.addSublayer(playerLayer)

        case .tile:
            let natural = naturalSize(fallback: CGSize(
                width: displayBounds.width / 3,
                height: displayBounds.height / 3
            ))
            playerLayer.videoGravity = .resize
            playerLayer.autoresizingMask = []
            playerLayer.frame = CGRect(
                origin: .zero, size: natural
            )

            // Two-level CAReplicator: horizontal row, then vertical
            // stack of rows.
            let cols = max(1, Int(ceil(
                displayBounds.width / natural.width
            )))
            let rows = max(1, Int(ceil(
                displayBounds.height / natural.height
            )))

            let horizontal = CAReplicatorLayer()
            horizontal.instanceCount = cols
            horizontal.instanceTransform = CATransform3DMakeTranslation(
                natural.width, 0, 0
            )
            horizontal.frame = CGRect(
                x: 0, y: 0,
                width: natural.width,
                height: natural.height
            )
            horizontal.addSublayer(playerLayer)

            let vertical = CAReplicatorLayer()
            vertical.instanceCount = rows
            vertical.instanceTransform = CATransform3DMakeTranslation(
                0, natural.height, 0
            )
            vertical.frame = CGRect(
                x: 0, y: 0,
                width: natural.width * CGFloat(cols),
                height: natural.height
            )
            vertical.addSublayer(horizontal)

            containerLayer.addSublayer(vertical)
        }
    }

    private func naturalSize(fallback: CGSize) -> CGSize {
        let p = playerItem.presentationSize
        if p == .zero { return fallback }
        return p
    }

    deinit {
        presentationSizeObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)
        player.pause()
    }
}
