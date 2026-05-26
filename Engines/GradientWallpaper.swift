import AppKit
import QuartzCore

/// Animated gradient fallback wallpaper. Used when no video file
/// is bundled. Phase 1.
///
/// Cycles between three brand-adjacent colors with a slow wave
/// motion. Light enough to run on any Mac without measurable
/// resource usage.
final class GradientWallpaper {
    let layer: CAGradientLayer

    init() {
        let gradient = CAGradientLayer()

        // Three stops: deep blue, near-black, deep crimson.
        gradient.colors = [
            NSColor(red: 0.06, green: 0.10, blue: 0.22, alpha: 1).cgColor,
            NSColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1).cgColor,
            NSColor(red: 0.24, green: 0.06, blue: 0.12, alpha: 1).cgColor,
        ]
        gradient.locations = [0.0, 0.5, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)

        layer = gradient

        let animation = CABasicAnimation(keyPath: "endPoint")
        animation.fromValue = NSValue(point: CGPoint(x: 1, y: 1))
        animation.toValue = NSValue(point: CGPoint(x: 0.2, y: 0.8))
        animation.duration = 8.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(
            name: .easeInEaseOut
        )
        gradient.add(animation, forKey: "wave")
    }
}
