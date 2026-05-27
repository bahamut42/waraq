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
import QuartzCore

/// Animated gradient fallback wallpaper.
/// Phase 1 baseline, Phase 2 adds pause support.
final class GradientWallpaper {
    let layer: CAGradientLayer
    private var pausedTime: CFTimeInterval = 0

    init() {
        let gradient = CAGradientLayer()

        gradient.colors = [
            NSColor(red: 0.06, green: 0.10, blue: 0.22, alpha: 1).cgColor,
            NSColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1).cgColor,
            NSColor(red: 0.24, green: 0.06, blue: 0.12, alpha: 1).cgColor,
        ]
        gradient.locations = [0.0, 0.5, 1.0]
        gradient.startPoint = .zero
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

    /// Freeze or resume the gradient animation in place.
    func setPaused(_ paused: Bool) {
        if paused {
            pausedTime = layer.convertTime(
                CACurrentMediaTime(),
                from: nil
            )
            layer.speed = 0
            layer.timeOffset = pausedTime
        } else {
            let pausedTimeOld = layer.timeOffset
            layer.speed = 1
            layer.timeOffset = 0
            layer.beginTime = 0
            let timeSincePause = layer.convertTime(
                CACurrentMediaTime(), from: nil
            ) - pausedTimeOld
            layer.beginTime = timeSincePause
        }
    }
}
