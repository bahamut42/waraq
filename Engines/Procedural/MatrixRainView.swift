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

struct MatrixRainView: View {
    private static let glyphs: [String] = {
        let chars = "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789@#$%"
        return chars.map { String($0) }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                // Black background
                ctx.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(.black)
                )

                let columnWidth: CGFloat = 16
                let columns = Int(size.width / columnWidth)
                let rowHeight: CGFloat = 18

                for col in 0..<columns {
                    let seed = Double(col * 7919)
                    let speed = 60 + (sin(seed) + 1) * 100 // pixels/sec
                    let length = 20 + Int((sin(seed * 0.5) + 1) * 18)
                    let offset = (t * speed + seed * 100)
                        .truncatingRemainder(
                            dividingBy: size.height + CGFloat(length) * rowHeight
                        )

                    for row in 0..<length {
                        let y = offset - Double(row) * rowHeight
                        guard y > 0, y < size.height else { continue }
                        let alpha: Double = {
                            if row == 0 { return 1.0 }
                            if row < 4 { return 0.85 }
                            return max(0, 0.85 - Double(row) * 0.04)
                        }()
                        let color: Color = row == 0
                            ? Color(red: 0.85, green: 1.0, blue: 0.90)
                            : Color(red: 0.20, green: 0.95, blue: 0.40)
                            .opacity(alpha)
                        let glyphIndex = Int(
                            (t * 4 + seed + Double(row)).truncatingRemainder(
                                dividingBy: Double(Self.glyphs.count)
                            )
                        )
                        let glyph = Self.glyphs[abs(glyphIndex) % Self.glyphs.count]
                        let x = CGFloat(col) * columnWidth + 1
                        ctx.draw(
                            Text(glyph)
                                .font(.system(
                                    size: 14,
                                    weight: .medium,
                                    design: .monospaced
                                ))
                                .foregroundColor(color),
                            at: CGPoint(x: x, y: y)
                        )
                    }
                }
            }
        }
    }
}
