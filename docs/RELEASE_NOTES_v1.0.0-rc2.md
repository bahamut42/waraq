# Waraq 1.0.0-rc2

Second release candidate. Cosmetic polish based on rc1 feedback.

## What's new since rc1

- **New app icon** — a wallpaper-roll-being-applied composition: a two-panel sheet (plain left + decorative dotted right, mid-application diagonal split) with a coiled roll along the bottom, cream outline on dark slate. Replaces the previous chevron mark.
- **Animated hero** — the README hero is now a live desktop GIF showing a video wallpaper running behind the real desktop (dock + menu bar visible), with personal content blurred.
- **README intro rewritten** — explains what Waraq is: a proof of concept built for myself, free for anyone to use or extend, GPL v3 forever.
- **All pane screenshots refreshed** to match the current build (the removed Color/HDR section is gone; About shows the new icon).

## What is Waraq

A free, open-source live wallpaper app for macOS. Plays videos, GIFs, and procedural animations as your desktop background, on every connected display independently. The name is Arabic for paper (ورق).

## Install

**DMG (drag-to-Applications):** Download `Waraq-1.0.0-rc2.dmg`, open it, drag Waraq to Applications.

**PKG (guided installer):** Download `Waraq-1.0.0-rc2.pkg`, double-click, follow the wizard.

Both install to `/Applications/Waraq.app`. Pick whichever you prefer. Requires macOS 14 Sonoma or later (Apple Silicon + Intel). Both downloads are signed with a Developer ID and notarized by Apple, so they pass Gatekeeper cleanly.

## Privacy

Zero telemetry. The only network activity is API calls to Pixabay, Pexels, or NASA when you search the Gallery. If you never use the Gallery, Waraq makes zero outbound connections.

## License

GPL v3. Free forever.

## Known limitations (same as rc1)

- In-app Gallery previews are static thumbnails, not video
- Library location is fixed at `~/Library/Application Support/Waraq/`
- "Yield to GPU-heavy apps" toggle is hidden pending detection logic

## What's next

- If rc2 has no blockers, 1.0.0 final ships next
- Then: configurable library location, Sparkle auto-update, Homebrew Cask

## Reporting bugs

[github.com/bahamut42/waraq/issues](https://github.com/bahamut42/waraq/issues)

---

Built by Omar A. Othman. Coded with significant assistance from Anthropic's Claude.
