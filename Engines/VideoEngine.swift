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
            let rawNatural = naturalSize(fallback: CGSize(
                width: displayBounds.width / 3,
                height: displayBounds.height / 3
            ))
            // Guard against a zero/degenerate tile size. At launch
            // the container bounds can be .zero and the video's
            // presentationSize may not have loaded yet, so the
            // fallback collapses to 0. A 0-width tile makes the
            // column/row count 0/0 = NaN, and Int(NaN) traps with
            // "Double value cannot be converted to Int". applyFitMode
            // re-runs once the layer is sized and the size loads.
            let natural = CGSize(
                width: max(1, rawNatural.width),
                height: max(1, rawNatural.height)
            )
            playerLayer.videoGravity = .resize
            playerLayer.autoresizingMask = []
            playerLayer.frame = CGRect(
                origin: .zero, size: natural
            )

            // Two-level CAReplicator: horizontal row, then vertical
            // stack of rows.
            let cols = tileCount(total: displayBounds.width, unit: natural.width)
            let rows = tileCount(total: displayBounds.height, unit: natural.height)

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

    /// Number of `unit`-sized tiles needed to cover `total`, clamped
    /// to a finite, sane range. Returns 1 for degenerate inputs
    /// (zero/NaN/infinite) so `Int(...)` can never trap on a NaN or
    /// infinite value.
    private func tileCount(total: CGFloat, unit: CGFloat) -> Int {
        guard total > 0, unit > 0, total.isFinite, unit.isFinite else {
            return 1
        }
        let count = ceil(total / unit)
        guard count.isFinite, count >= 1 else { return 1 }
        return Int(min(count, 1000))
    }

    deinit {
        presentationSizeObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)
        player.pause()
    }
}
