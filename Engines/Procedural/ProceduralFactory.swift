import AppKit
import SwiftUI

/// Maps a procedural wallpaper key to an NSView (via NSHostingView
/// around the matching SwiftUI view).
enum ProceduralFactory {
    static func makeView(for key: String) -> NSView? {
        switch key {
        case "aurora":
            NSHostingView(rootView: AuroraView())
        case "matrix-rain":
            NSHostingView(rootView: MatrixRainView())
        case "synthwave":
            NSHostingView(rootView: SynthwaveView())
        case "starfield":
            NSHostingView(rootView: StarfieldView())
        case "neural-network":
            NSHostingView(rootView: NeuralNetworkView())
        default:
            nil
        }
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
