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
import SwiftUI

/// Maps a procedural wallpaper key to an NSView (via NSHostingView
/// around the matching SwiftUI view).
enum ProceduralFactory {
    /// The SwiftUI view that renders a procedural key. Single source of
    /// truth, reused both for the live NSHostingView and for offscreen
    /// thumbnail capture (ProceduralThumbnailGenerator).
    static func swiftUIView(for key: String) -> AnyView? {
        switch key {
        case "aurora": AnyView(AuroraView())
        case "matrix-rain": AnyView(MatrixRainView())
        case "synthwave": AnyView(SynthwaveView())
        case "starfield": AnyView(StarfieldView())
        case "neural-network": AnyView(NeuralNetworkView())
        default: nil
        }
    }

    static func makeView(for key: String) -> NSView? {
        guard let view = swiftUIView(for: key) else { return nil }
        return NSHostingView(rootView: view)
    }

    static let allBuiltIns: [Wallpaper] = [
        Wallpaper(
            id: "com.bahamut.waraq.builtin.aurora",
            name: "Aurora Borealis",
            kind: .procedural,
            addedDate: Date.distantPast,
            proceduralKey: "aurora"
        ),
        Wallpaper(
            id: "com.bahamut.waraq.builtin.matrix",
            name: "Matrix Rain",
            kind: .procedural,
            addedDate: Date.distantPast,
            proceduralKey: "matrix-rain"
        ),
        Wallpaper(
            id: "com.bahamut.waraq.builtin.synthwave",
            name: "Synthwave Drive",
            kind: .procedural,
            addedDate: Date.distantPast,
            proceduralKey: "synthwave"
        ),
        Wallpaper(
            id: "com.bahamut.waraq.builtin.starfield",
            name: "Starfield",
            kind: .procedural,
            addedDate: Date.distantPast,
            proceduralKey: "starfield"
        ),
        Wallpaper(
            id: "com.bahamut.waraq.builtin.neural",
            name: "Neural Network",
            kind: .procedural,
            addedDate: Date.distantPast,
            proceduralKey: "neural-network"
        ),
    ]
}
