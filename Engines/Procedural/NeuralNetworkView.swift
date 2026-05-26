import SwiftUI

struct NeuralNetworkView: View {
    struct Node {
        var x: Double
        var y: Double
        var vx: Double
        var vy: Double
    }

    private static let nodes: [Node] = (0..<32).map { _ in
        Node(
            x: Double.random(in: 0...1),
            y: Double.random(in: 0...1),
            vx: Double.random(in: -0.04...0.04),
            vy: Double.random(in: -0.04...0.04)
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                // Deep tech background
                ctx.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.04, green: 0.05, blue: 0.10),
                            Color(red: 0.02, green: 0.04, blue: 0.14),
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )

                // Compute current positions (bounced)
                let speed = 0.06
                let positions: [(x: Double, y: Double)] = Self.nodes.map { n in
                    var x = n.x + n.vx * t * speed
                    var y = n.y + n.vy * t * speed
                    // Bouncing in [0, 1]
                    x = x.truncatingRemainder(dividingBy: 2)
                    if x < 0 { x += 2 }
                    if x > 1 { x = 2 - x }
                    y = y.truncatingRemainder(dividingBy: 2)
                    if y < 0 { y += 2 }
                    if y > 1 { y = 2 - y }
                    return (x, y)
                }

                let absPositions = positions.map {
                    CGPoint(x: $0.x * size.width, y: $0.y * size.height)
                }

                // Lines between nearby nodes
                let threshold: CGFloat = min(size.width, size.height) * 0.18
                for i in 0..<absPositions.count {
                    for j in (i + 1)..<absPositions.count {
                        let dx = absPositions[i].x - absPositions[j].x
                        let dy = absPositions[i].y - absPositions[j].y
                        let dist = sqrt(dx * dx + dy * dy)
                        if dist < threshold {
                            let alpha = 1.0 - dist / threshold
                            ctx.stroke(
                                Path { p in
                                    p.move(to: absPositions[i])
                                    p.addLine(to: absPositions[j])
                                },
                                with: .color(Color(
                                    red: 0.40,
                                    green: 0.75,
                                    blue: 1.0
                                ).opacity(alpha * 0.55)),
                                lineWidth: 0.7
                            )
                        }
                    }
                }

                // Nodes
                for p in absPositions {
                    let r: CGFloat = 2.5
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: p.x - r, y: p.y - r,
                            width: r * 2, height: r * 2
                        )),
                        with: .color(Color(red: 0.75, green: 0.9, blue: 1.0))
                    )
                }
            }
        }
    }
}
