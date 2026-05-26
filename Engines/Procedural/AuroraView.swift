import SwiftUI

struct AuroraView: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                // Deep navy sky
                ctx.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(colors: [
                            Color(red: 0.02, green: 0.04, blue: 0.10),
                            Color(red: 0.04, green: 0.02, blue: 0.16),
                            Color(red: 0.08, green: 0.02, blue: 0.10),
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )

                // Stars
                for i in 0..<60 {
                    let x = Double((i * 71) % Int(size.width))
                    let y = Double((i * 137) % Int(size.height * 0.6))
                    let r = 0.7 + sin(t + Double(i)) * 0.3
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: x, y: y, width: r, height: r
                        )),
                        with: .color(.white.opacity(0.6))
                    )
                }

                // Two aurora ribbons
                drawRibbon(
                    ctx: ctx, size: size, t: t,
                    phase: 0.0, baseY: 0.4,
                    color1: Color(red: 0.20, green: 0.85, blue: 0.55),
                    color2: Color(red: 0.10, green: 0.40, blue: 0.80)
                )
                drawRibbon(
                    ctx: ctx, size: size, t: t * 0.7,
                    phase: 1.5, baseY: 0.55,
                    color1: Color(red: 0.70, green: 0.30, blue: 0.85),
                    color2: Color(red: 0.30, green: 0.10, blue: 0.60)
                )
            }
        }
    }

    private func drawRibbon(
        ctx: GraphicsContext, size: CGSize, t: Double,
        phase: Double, baseY: Double,
        color1: Color, color2: Color
    ) {
        var path = Path()
        let steps = 40
        let w = size.width
        let h = size.height

        for i in 0...steps {
            let x = Double(i) * (w / Double(steps))
            let wave = sin(Double(i) * 0.3 + t * 0.5 + phase) * 60
            let y = baseY * h + wave
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        for i in stride(from: steps, through: 0, by: -1) {
            let x = Double(i) * (w / Double(steps))
            let wave = sin(Double(i) * 0.3 + t * 0.5 + phase) * 60
            let y = baseY * h + wave + 90
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.closeSubpath()

        ctx.fill(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    color1.opacity(0.5),
                    color2.opacity(0.05),
                ]),
                startPoint: CGPoint(x: 0, y: baseY * h),
                endPoint: CGPoint(x: 0, y: baseY * h + 90)
            )
        )
    }
}
