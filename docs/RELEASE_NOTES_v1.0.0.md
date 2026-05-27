# Waraq v1.0.0

The first stable release.

## What is Waraq

A free, open-source live wallpaper app for macOS. Plays videos, GIFs, and procedural animations as your desktop background, on every connected display independently.

The name is Arabic for paper (ورق).

## Install

Two ways, both ship in this release. Pick whichever you prefer — both install to `/Applications/Waraq.app`.

**DMG (drag-to-Applications):**
1. Download `Waraq-1.0.0.dmg`
2. Double-click the downloaded file
3. Drag the Waraq icon to the Applications folder shortcut
4. Eject the disk image, launch Waraq from Applications

**PKG (guided installer):**
1. Download `Waraq-1.0.0.pkg`
2. Double-click to launch the installer
3. Follow the prompts: Continue, agree to GPL v3, Install
4. Waraq is ready in Applications

Both methods install a code-signed, notarized app — no Gatekeeper warnings.

**Requirements:** macOS 14 Sonoma or later. Apple Silicon and Intel both supported.

## Features

**Wallpaper playback**
- Plays MP4, MOV, M4V video files as live wallpapers
- Plays animated GIFs as wallpapers
- Six built-in procedural animations (Aurora Borealis, Matrix Rain, Synthwave Drive, Starfield, Neural Network, Animated Gradient) — zero file footprint, generated at runtime
- Imports Wallpaper Engine `.we` video files (video subset only, not scene files)

**Multi-monitor**
- Each connected display gets its own wallpaper, fit mode, mute setting, and volume independently
- Profiles save by hardware ID — plugging a different monitor in doesn't break your setup
- Plugging a familiar monitor back in restores its last config automatically
- "Show Numbers" flashes a big number on each physical screen so you can match Waraq's rows to your monitors
- Optional manual "Waraq Primary" display selection, independent of which display macOS treats as main

**Gallery (built-in wallpaper discovery)**
- Search across three free sources: Pixabay, Pexels, NASA
- Pixabay and Pexels use a free API key from those sites; NASA needs no key (public domain)
- Results cached locally for 24 hours
- One click adds a downloaded wallpaper to your Library

**Browse Web (external sources)**
- Curated list of community wallpaper sites (MotionBGs, MoeWalls, MyLiveWallpapers, Wallsflow)
- Opens links in your default browser; you download manually under each site's personal-use license
- Drag the downloaded file onto Waraq's Library tab to import

**Performance**
- Pauses behind fullscreen apps, on battery (configurable), and on thermal pressure
- Hardware decoding when available
- Configurable render quality and frame-rate cap; drops frames under heavy load instead of slowing the system
- Adjustable memory limit per wallpaper

**Onboarding**
- 5-step setup wizard on first launch (displays, starter wallpaper, performance preferences)
- "Run Setup Again" available in the About pane any time

## Privacy

Zero telemetry. No analytics. No phone-home. No tracking. No anonymous usage data.

The only outbound network activity Waraq ever does is API calls to Pixabay, Pexels, or NASA when **you** search the Gallery, and downloads of the specific wallpaper you choose to add. If you never use the Gallery, Waraq makes zero outbound connections. API keys are stored in your local UserDefaults and only sent as authentication to the relevant API host. The Browse Web tab opens links in your default browser — Waraq fetches nothing from those sites.

## License

GPL v3. See [LICENSE](https://github.com/bahamut42/waraq/blob/main/LICENSE). Free forever — use, study, modify, and redistribute it; any redistribution stays GPL v3 (no closed-source forks). This is intentional. Waraq stays free.

## Known limitations

- In-app Gallery previews show static thumbnails, not motion video (wallpaper playback on the desktop is full motion)
- The wallpaper library location is fixed at `~/Library/Application Support/Waraq/` — external-drive support is the top post-v1 roadmap item
- The "Yield to GPU-heavy apps" performance toggle is hidden pending the detection logic that backs it

## What's next

- Configurable library location (external drive support)
- Automatic update channel via Sparkle
- Homebrew Cask installation channel
- Motion previews in the in-app Gallery
- More built-in procedural wallpapers

No timelines. It ships when it ships.

## Reporting bugs

https://github.com/bahamut42/waraq/issues — include your macOS version, Mac model, Waraq version (Settings → About), and steps to reproduce.

## Credits

Built by Omar A. Othman. Coded with significant assistance from Anthropic's Claude.

Stock wallpaper sources in the Gallery: [Pixabay](https://pixabay.com), [Pexels](https://www.pexels.com), [NASA Image and Video Library](https://images.nasa.gov).

Curated external sources in Browse Web (Waraq is not affiliated with these and doesn't redistribute their content): [MotionBGs](https://motionbgs.com), [MoeWalls](https://moewalls.com), [MyLiveWallpapers](https://mylivewallpapers.com), [Wallsflow](https://wallsflow.com).

## Support

If Waraq is useful to you and you want to throw something my way: [paypal.me/OOthman666](https://paypal.me/OOthman666). Not required. Ever.
