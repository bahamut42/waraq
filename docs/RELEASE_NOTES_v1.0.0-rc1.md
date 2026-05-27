# Waraq 1.0.0-rc1

Release candidate for v1. Beta period — please report bugs.

## What is this

Waraq is a free, open-source live wallpaper app for macOS. It plays videos, GIFs, and procedural animations as your desktop background, on every connected display independently.

The name is Arabic for paper (ورق).

## Install

**DMG (drag-to-Applications):** Download `Waraq-1.0.0-rc1.dmg`, open it, drag Waraq onto Applications.

**PKG (guided installer):** Download `Waraq-1.0.0-rc1.pkg`, double-click, follow the wizard.

Both methods install to `/Applications/Waraq.app`. Pick whichever you prefer.

Waraq requires macOS 14 Sonoma or later. Both Apple Silicon and Intel are supported. Both downloads are signed with a Developer ID and notarized by Apple, so they pass Gatekeeper cleanly.

## What's in v1

- Play videos and GIFs as wallpaper on any number of displays, independently
- Six built-in procedural wallpapers (Aurora Borealis, Matrix Rain, Synthwave Drive, Starfield, Neural Network, Animated Gradient)
- Built-in Gallery with thousands of free wallpapers from Pixabay, Pexels, and NASA
- Browse Web tab linking to anime/gaming wallpaper sites (you download manually, drag into Waraq)
- Per-display profiles saved by hardware ID
- Manual "Waraq Primary" display override
- Performance governor: pauses on battery, behind fullscreen apps, and on thermal pressure
- Wallpaper Engine `.we` video import (video subset only, not scene files)
- Zero telemetry, zero analytics, zero phone-home

## Privacy

The only network activity Waraq does is API calls to Pixabay, Pexels, or NASA when you search the Gallery. Nothing else. Ever. Browse Web just opens links in your default browser — Waraq fetches nothing from those sites.

If you never use the Gallery, Waraq makes zero outbound connections.

## License

GPL v3. Free forever. Cannot practically be sold — anyone who receives a copy can redistribute it for free under the same license.

## Known limitations carried into v1

- In-app Gallery previews are static thumbnails, not video (motion preview deferred to a future release)
- Library location is fixed at `~/Library/Application Support/Waraq/` — external-drive support is the top post-v1 roadmap item
- "Yield to GPU-heavy apps" toggle is hidden pending detection logic

## What's next

If 1.0.0-rc1 has no blocking issues during the beta, 1.0.0 final ships. After that:
- Configurable library location (external-drive support)
- Automatic updates via Sparkle
- More procedural wallpapers
- Homebrew Cask

## Reporting bugs

[github.com/bahamut42/waraq/issues](https://github.com/bahamut42/waraq/issues) — include your macOS version, Mac model, Waraq version, and steps to reproduce.

---

Built by Omar A. Othman. Coded with significant assistance from Anthropic's Claude.
