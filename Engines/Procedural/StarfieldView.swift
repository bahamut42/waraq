import SwiftUI

struct StarfieldView: View {
    struct Star {
        var angle: Double
        var speed: Double
        var startDistance: Double
    }

    private static let stars: [Star] = (0..<200).map { _ in
        Star(
            angle: Double.random(in: 0..<2 * .pi),
            speed: Double.random(in: 60...260),
            startDistance: Double.random(in: 0...600)
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                ctx.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(.black)
                )

                let cx = size.width / 2
                let cy = size.height / 2
                let maxDist = max(size.width, size.height) * 0.8

                for star in Self.stars {
                    let dist = (star.startDistance + t * star.speed)
                        .truncatingRemainder(dividingBy: maxDist)
                    let x = cx + cos(star.angle) * dist
                    let y = cy + sin(star.angle) * dist
                    if x < 0 || x > size.width || y < 0 || y > size.height {
                        continue
                    }
                    let progress = dist / maxDist
                    let r = 0.5 + progress * 2.5
                    let alpha = min(1.0, progress * 1.8)

                    // Streak (tail)
                    let tailX = cx + cos(star.angle) * (dist - 8)
                    let tailY = cy + sin(star.angle) * (dist - 8)
                    ctx.stroke(
                        Path { p in
                            p.move(to: CGPoint(x: tailX, y: tailY))
                            p.addLine(to: CGPoint(x: x, y: y))
                        },
                        with: .color(.white.opacity(alpha * 0.5)),
                        lineWidth: r * 0.6
                    )

                    // Head
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: x - r, y: y - r,
                            width: r * 2, height: r * 2
                        )),
                        with: .color(.white.opacity(alpha))
                    )
                }
            }
        }
    }
}
