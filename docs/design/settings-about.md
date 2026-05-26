# Settings: About Pane Spec

Status: locked v1 (2026-05-26)
Phase: 7 (final polish)
Implementer: Claude Code (SwiftUI)

## Intent

The About pane closes out Settings. It shows the app identity,
credits, open source dependencies, GitHub repo links, sponsorship,
and license. It is also the most personal pane: project warmth lives
here.

## Form

Standard Settings content pane. Compact layout, centered hero.

## Layout

Pane title: "About" (still 22 pt at the top)

Sections in order:
1. Hero (app icon, name, version, tagline)
2. Credits
3. Links
4. Copyright footer

## Sections

### Hero

Centered block, 32 pt top padding, 28 pt bottom padding.

- App icon: 96 × 96 pt, 22 pt corner radius (Apple squircle)
  - Uses `waraq-icon-dark` or `waraq-icon-light` per appearance
  - With drop shadow (system shadow on rounded rect)
- Name: "Waraq" at 24 pt weight 500 `labelColor`,
  letter-spacing -0.3 pt, 16 pt top margin
- Version line: "Version {version} (build {build}) · macOS 14.0+" at
  12 pt `secondaryLabelColor`, 4 pt top margin
- Tagline: "A lightweight, native animated wallpaper engine for
  macOS. Open source, MIT licensed." at 12 pt
  `secondaryLabelColor`, 12 pt top margin, max 360 pt wide,
  line height 1.5

### Credits

Header: "CREDITS"

Card with two rows.

**Row 1: Author**
- Layout: avatar circle + text block + GitHub link
- Avatar: 36 × 36 pt circle, gradient bg (deep fel green to crimson),
  centered "B" character 14 pt weight 500 white
- Title: "Bahamüt" at 13 pt weight 500
- Sublabel: "Design, code, and the bird that wouldn't shut up" at
  11 pt `secondaryLabelColor`
- Trailing: link "Niiro92Othman" with leading GitHub icon at 14 pt,
  text 12 pt `systemBlue`, clickable, opens
  `https://github.com/Niiro92Othman`

**Row 2: Built on the shoulders of**
- Layout: title line + tag chips
- Title: 12 pt `labelColor` opacity 0.7 "Built on the shoulders of:"
- 8 pt below: flex-wrap row of dependency pills, 6 pt gap
- Each pill: 11 pt `labelColor` opacity 0.85, padded 3 pt vertical /
  9 pt horizontal, 5 pt radius, `Color.primary.opacity(0.06)` bg,
  0.5 pt `separatorColor` border
- Clicking a pill opens that dependency's repo URL

Dependency list (with URLs):
- Sparkle → https://github.com/sparkle-project/Sparkle
- LaunchAtLogin → https://github.com/sindresorhus/LaunchAtLogin
- Defaults → https://github.com/sindresorhus/Defaults
- Swift → https://developer.apple.com/swift/
- Metal → https://developer.apple.com/metal/
- AVFoundation → https://developer.apple.com/av-foundation/

### Links

Header: "LINKS"

Card with four rows. Each row is a tappable link with leading icon
and trailing `arrow.up.right.square` at 13 pt `tertiaryLabelColor`.

**Row 1: Source on GitHub**
- Icon: `chevron.left.slash.chevron.right` 16 pt (or GitHub mark
  asset if available)
- Title: "Source on GitHub"
- Sublabel: "Star, fork, or contribute"
- URL: https://github.com/Niiro92Othman/waraq

**Row 2: Report a bug**
- Icon: `ant` 16 pt
- Title: "Report a bug"
- No sublabel
- URL: https://github.com/Niiro92Othman/waraq/issues/new

**Row 3: Sponsor development**
- Icon: `heart` 16 pt in soft pink (`#ffaaaa` dark / `#ff6688` light)
- Title: "Sponsor development"
- Sublabel: "Waraq is free. Help keep it that way"
- URL: https://paypal.me/OOthman666

**Row 4: License (MIT)**
- Icon: `doc.text` 16 pt
- Title: "License (MIT)"
- No sublabel
- URL: https://github.com/Niiro92Othman/waraq/blob/main/LICENSE

### Copyright footer

Centered text, 12 pt top padding from the last card.
- 11 pt `tertiaryLabelColor`
- Format: "© 2026 Omar A. Othman"

## Behaviors

### Link clicks

All link rows open the URL in the system default browser via
`NSWorkspace.shared.open(URL)`. No in-app browser.

### Version string

Composed from `Bundle.main`:
- `CFBundleShortVersionString` for version
- `CFBundleVersion` for build
- `ProcessInfo.processInfo.operatingSystemVersionString` for macOS
  hint

### Icon respects appearance

Uses the dark icon asset in dark mode, light icon asset in light
mode. Switches live with system appearance.

### About in Help menu

The standard "About Waraq" menu item (Help menu) opens the Settings
window with the About pane pre-selected.

## Implementation notes

- App icon image asset has both light and dark variants ("Image Set"
  in Asset Catalog with appearance variants)
- Use `SwiftUI` `Link` for the GitHub author link
- For dependency pills, build with `LazyVGrid` adaptive(minimum: 60)
- "Built on the shoulders of" is a known phrase, do not change it
- The author one-liner ("the bird that wouldn't shut up") is a deliberate
  joke about the cawing crow icon and should not be sanitized

## Out of scope

- Acknowledgements long form (could be a sheet from a "View all
  acknowledgements" link, v1.1)
- Privacy policy page (not needed for v1 since usage data is opt-in
  and there is no account)
- Press kit links (post-launch v1.1)

## Changelog
- v1 (2026-05-26): Initial lock.
