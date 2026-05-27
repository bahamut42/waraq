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

import SwiftUI

struct SynthwaveView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                // Sky gradient (sunset)
                ctx.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: Color(red: 0.10, green: 0.02, blue: 0.30), location: 0),
                            .init(color: Color(red: 0.85, green: 0.20, blue: 0.50), location: 0.45),
                            .init(color: Color(red: 0.95, green: 0.45, blue: 0.20), location: 0.55),
                            .init(color: Color(red: 0.05, green: 0.02, blue: 0.15), location: 0.6),
                            .init(color: Color(red: 0.05, green: 0.02, blue: 0.15), location: 1.0),
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )

                // Sun (semicircle in upper half)
                let sunR: CGFloat = size.height * 0.18
                let sunCx = size.width / 2
                let sunCy = size.height * 0.55
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: sunCx - sunR, y: sunCy - sunR,
                        width: sunR * 2, height: sunR * 2
                    )),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.30),
                            Color(red: 0.95, green: 0.30, blue: 0.55),
                        ]),
                        startPoint: CGPoint(x: 0, y: sunCy - sunR),
                        endPoint: CGPoint(x: 0, y: sunCy + sunR)
                    )
                )

                // Horizon glow
                let glow = CGRect(
                    x: 0, y: size.height * 0.58,
                    width: size.width, height: 4
                )
                ctx.fill(
                    Path(glow),
                    with: .color(Color(red: 1, green: 0.6, blue: 0.9, opacity: 0.5))
                )

                // Perspective grid
                let gridTop = size.height * 0.6
                let vanishX = size.width / 2
                let vanishY = gridTop
                let gridColor = Color(red: 1.0, green: 0.30, blue: 0.85)
                let lineWidth: CGFloat = 1.0

                // Horizontal lines (animated, receding effect)
                let speed: Double = 60
                let offset = (t * speed).truncatingRemainder(
                    dividingBy: 36
                )
                for i in 0..<30 {
                    let progress = (CGFloat(i) * 36 + CGFloat(offset)) / 600
                    let y = gridTop + progress * (size.height - gridTop)
                    if y > size.height { continue }
                    let alpha = min(1.0, max(0.0, 1.0 - Double(progress) * 0.3))
                    ctx.stroke(
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: size.width, y: y))
                        },
                        with: .color(gridColor.opacity(alpha * 0.6)),
                        lineWidth: lineWidth
                    )
                }

                // Vertical lines (perspective)
                for i in -8...8 {
                    let endX = vanishX + CGFloat(i) * size.width * 0.18
                    ctx.stroke(
                        Path { p in
                            p.move(to: CGPoint(x: vanishX, y: vanishY))
                            p.addLine(to: CGPoint(x: endX, y: size.height))
                        },
                        with: .color(gridColor.opacity(0.4)),
                        lineWidth: lineWidth
                    )
                }
            }
        }
    }
}
