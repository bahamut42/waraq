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

final class WallpaperWindow: NSWindow {
    init(for screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        let desktopIconLevel = Int(CGWindowLevelForKey(.desktopIconWindow))
        level = NSWindow.Level(rawValue: desktopIconLevel - 1)
        collectionBehavior = [
            .canJoinAllSpaces, .stationary,
            .ignoresCycle, .fullScreenAuxiliary,
        ]
        ignoresMouseEvents = true
        isOpaque = true
        backgroundColor = .black
        hasShadow = false
        isReleasedWhenClosed = false

        let contentView = NSView(frame: screen.frame)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.black.cgColor
        self.contentView = contentView
    }

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }

    func install(layer: CALayer) {
        guard let contentView else { return }
        clearContent()
        layer.frame = contentView.bounds
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        contentView.layer?.addSublayer(layer)
    }

    func install(view: NSView) {
        guard let contentView else { return }
        clearContent()
        view.frame = contentView.bounds
        view.autoresizingMask = [.width, .height]
        contentView.addSubview(view)
    }

    private func clearContent() {
        guard let contentView else { return }
        contentView.subviews.forEach { $0.removeFromSuperview() }
        contentView.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
}
