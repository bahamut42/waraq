# Waraq App Icon Spec

Status: locked v4 (2026-05-26)
Phase: 7 (final polish) but assets can be produced anytime
Implementer: Claude Code (icon exporter script) or designer

## Intent

The Waraq icon shows a profile crow silhouette standing on a horizon
line, mid-cry but with a closed beak (resting state, not actively
cawing). The icon doubles as a tiny wallpaper scene: moon and stars
in dark mode, sun and cloud in light mode, plus a subtle horizon line
in both. The icon itself looks like a wallpaper, which mirrors what
the app makes.

## Variants

macOS 14+ supports light and dark variants in `.icns` bundles. Both
are required.

### Dark mode

- Background: deep crimson radial fading to near-black
- Crow silhouette: warm cream `#f2ece4`
- Eye: dark crimson `#c83a4a`
- Scene: crescent moon, three small stars, subtle horizon line

### Light mode

- Background: cool neutral light grey-blue radial
- Crow silhouette: near-black `#0c0808`
- Eye: muted crimson `#a82838`
- Scene: soft warm sun with halo, white cloud upper-left, subtle
  horizon line

## Specs

- Master size: 1024 × 1024 pt at 1x
- Squircle radius: ~22% (Apple superellipse), use 46 / 200 in viewBox
- Required sizes for the iconset: 16, 32, 64, 128, 256, 512, 1024
- Each size needs @1x and @2x except the lowest (16)
- Light and dark variants for each

## Status item (menu bar) icon

A separate, template-rendered SVG. macOS treats `NSImage.isTemplate
= true` images as monochrome silhouettes that auto-adapt to the menu
bar appearance.

- 18 × 18 pt point size, 22 × 22 pt content area
- Single color silhouette only, no scene elements (moon, sun, cloud
  do not survive template rendering)
- 1.5 pt effective stroke equivalent
- States communicated by alpha:
  - Live (rendering): 100% alpha
  - Paused: 70% alpha + subtle outline if needed
  - Off: 40% alpha

## SVG source (canonical)

All variants below use viewBox `0 0 200 200`. Scale to target size at
export.

### Common crow silhouette (used in all variants)

```svg
<g transform="translate(108, 100)">
  <!-- Tail (extends right behind body) -->
  <path d="M 10,5 L 60,8 L 55,22 L 12,20 Z"/>
  <!-- Body, slightly tilted -->
  <ellipse cx="-12" cy="8" rx="38" ry="20" transform="rotate(-4 -12 8)"/>
  <!-- Neck connecting body to head -->
  <path d="M -32,-8 Q -42,-18 -42,-26 L -28,-30 L -22,-12 L -14,-2 Z"/>
  <!-- Head -->
  <ellipse cx="-40" cy="-28" rx="12" ry="13"/>
  <!-- Closed beak, single tapered triangle pointing left -->
  <path d="M -30,-30 L -72,-28 L -28,-25 Z"/>
  <!-- Legs -->
  <rect x="-18" y="22" width="3" height="26"/>
  <rect x="2" y="24" width="3" height="24"/>
  <!-- Feet (3 toes each, simplified) -->
  <path d="M -22,48 L -28,52 L -16,49 L -10,52 L -16,48 Z"/>
  <path d="M -2,48 L -8,52 L 4,49 L 10,52 L 4,48 Z"/>
</g>
```

Fill color of this whole group:
- Dark variant: `#f2ece4`
- Light variant: `#0c0808`
- Template menu bar: `#000000` (auto-inverts via `NSImage.isTemplate`)

Eye (rendered after the group, separate fill):
- Dark variant: `<circle cx="66" cy="72" r="2" fill="#c83a4a"/>`
  (note: cx=66 = -42 in group coords + 108 translate)
- Light variant: `<circle cx="66" cy="72" r="2" fill="#a82838"/>`
- Template: omit eye (single-color template cannot have it)

### Dark variant full SVG

```svg
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="bgDark" cx="32%" cy="28%" r="85%">
      <stop offset="0%" stop-color="#4a1626"/>
      <stop offset="55%" stop-color="#1a0410"/>
      <stop offset="100%" stop-color="#000000"/>
    </radialGradient>
  </defs>

  <!-- Squircle background -->
  <rect x="0" y="0" width="200" height="200" rx="46" ry="46" fill="url(#bgDark)"/>

  <!-- Crescent moon (upper right) -->
  <g opacity="0.22">
    <circle cx="158" cy="48" r="13" fill="#fce8d6"/>
    <circle cx="163" cy="45" r="11" fill="#1a0410"/>
  </g>

  <!-- Stars (three subtle dots) -->
  <circle cx="135" cy="32" r="0.8" fill="#fce8d6" opacity="0.5"/>
  <circle cx="170" cy="78" r="0.6" fill="#fce8d6" opacity="0.4"/>
  <circle cx="38" cy="55" r="0.7" fill="#fce8d6" opacity="0.4"/>

  <!-- Horizon line -->
  <rect x="20" y="159" width="160" height="0.5" fill="#fce8d6" opacity="0.18"/>

  <!-- Crow -->
  <g transform="translate(108, 100)" fill="#f2ece4">
    <path d="M 10,5 L 60,8 L 55,22 L 12,20 Z"/>
    <ellipse cx="-12" cy="8" rx="38" ry="20" transform="rotate(-4 -12 8)"/>
    <path d="M -32,-8 Q -42,-18 -42,-26 L -28,-30 L -22,-12 L -14,-2 Z"/>
    <ellipse cx="-40" cy="-28" rx="12" ry="13"/>
    <path d="M -30,-30 L -72,-28 L -28,-25 Z"/>
    <rect x="-18" y="22" width="3" height="26"/>
    <rect x="2" y="24" width="3" height="24"/>
    <path d="M -22,48 L -28,52 L -16,49 L -10,52 L -16,48 Z"/>
    <path d="M -2,48 L -8,52 L 4,49 L 10,52 L 4,48 Z"/>
    <circle cx="-42" cy="-28" r="2" fill="#c83a4a"/>
  </g>
</svg>
```

### Light variant full SVG

```svg
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="bgLight" cx="32%" cy="28%" r="85%">
      <stop offset="0%" stop-color="#f5f7fa"/>
      <stop offset="55%" stop-color="#dde2e8"/>
      <stop offset="100%" stop-color="#b8bec8"/>
    </radialGradient>
  </defs>

  <!-- Squircle background -->
  <rect x="0" y="0" width="200" height="200" rx="46" ry="46" fill="url(#bgLight)"/>

  <!-- Sun (with soft halo) -->
  <circle cx="160" cy="46" r="22" fill="#ffd09a" opacity="0.18"/>
  <circle cx="160" cy="46" r="14" fill="#ffd09a" opacity="0.55"/>

  <!-- Cloud (upper left) -->
  <g opacity="0.85" fill="#ffffff">
    <ellipse cx="80" cy="68" rx="20" ry="5"/>
    <circle cx="70" cy="63" r="5"/>
    <circle cx="80" cy="58" r="8"/>
    <circle cx="90" cy="63" r="6"/>
    <circle cx="97" cy="66" r="4"/>
  </g>

  <!-- Horizon line -->
  <rect x="20" y="159" width="160" height="0.5" fill="#1a1a1a" opacity="0.15"/>

  <!-- Crow -->
  <g transform="translate(108, 100)" fill="#0c0808">
    <path d="M 10,5 L 60,8 L 55,22 L 12,20 Z"/>
    <ellipse cx="-12" cy="8" rx="38" ry="20" transform="rotate(-4 -12 8)"/>
    <path d="M -32,-8 Q -42,-18 -42,-26 L -28,-30 L -22,-12 L -14,-2 Z"/>
    <ellipse cx="-40" cy="-28" rx="12" ry="13"/>
    <path d="M -30,-30 L -72,-28 L -28,-25 Z"/>
    <rect x="-18" y="22" width="3" height="26"/>
    <rect x="2" y="24" width="3" height="24"/>
    <path d="M -22,48 L -28,52 L -16,49 L -10,52 L -16,48 Z"/>
    <path d="M -2,48 L -8,52 L 4,49 L 10,52 L 4,48 Z"/>
    <circle cx="-42" cy="-28" r="2" fill="#a82838"/>
  </g>
</svg>
```

### Menu bar template SVG

```svg
<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
  <g transform="translate(108, 100)" fill="#000000">
    <path d="M 10,5 L 60,8 L 55,22 L 12,20 Z"/>
    <ellipse cx="-12" cy="8" rx="38" ry="20"/>
    <path d="M -32,-8 L -42,-26 L -14,-2 Z"/>
    <ellipse cx="-40" cy="-28" rx="12" ry="13"/>
    <path d="M -30,-30 L -72,-28 L -28,-25 Z"/>
    <rect x="-18" y="22" width="3" height="26"/>
    <rect x="2" y="24" width="3" height="24"/>
  </g>
</svg>
```

Note: feet are omitted at template scale (would be illegible at 18 pt).

## Export pipeline

Use `Scripts/build-icons.sh` to convert SVGs to required PNG sizes
and pack into an iconset:

```bash
#!/usr/bin/env bash
set -e

# Requires librsvg (brew install librsvg) and iconutil (built into macOS)

SIZES=(16 32 64 128 256 512 1024)
SVG_DARK="Resources/icon-source-dark.svg"
SVG_LIGHT="Resources/icon-source-light.svg"
OUT_DARK="Waraq-Dark.iconset"
OUT_LIGHT="Waraq-Light.iconset"

mkdir -p "$OUT_DARK" "$OUT_LIGHT"

for s in "${SIZES[@]}"; do
  rsvg-convert -w "$s" -h "$s" "$SVG_DARK" > "$OUT_DARK/icon_${s}x${s}.png"
  if [ "$s" -ne 16 ]; then
    rsvg-convert -w "$((s*2))" -h "$((s*2))" "$SVG_DARK" > "$OUT_DARK/icon_${s}x${s}@2x.png"
  fi
  rsvg-convert -w "$s" -h "$s" "$SVG_LIGHT" > "$OUT_LIGHT/icon_${s}x${s}.png"
  if [ "$s" -ne 16 ]; then
    rsvg-convert -w "$((s*2))" -h "$((s*2))" "$SVG_LIGHT" > "$OUT_LIGHT/icon_${s}x${s}@2x.png"
  fi
done

iconutil -c icns "$OUT_DARK"
iconutil -c icns "$OUT_LIGHT"
```

Bundle in Xcode: place both `.icns` in `Resources/`. In `Info.plist`,
set the `CFBundleIcons` key to the dark variant, and use the macOS
14+ Asset Catalog "Single Size" with appearance variants to ship
both.

## Status item integration (Swift)

```swift
import AppKit

let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
let image = NSImage(named: "WaraqStatusItem")
image?.isTemplate = true
image?.size = NSSize(width: 18, height: 18)
statusItem.button?.image = image
```

## Out of scope

- Animated icon variants (Live / Paused / Off state transitions on
  the status item icon, deferred to v1.1)
- App Store screenshots and marketing assets (separate exercise)
- Favicon for landing page (use exported 32 pt PNG)

## Changelog
- v4 (2026-05-26): Closed beak (single triangle), added cloud to
  light mode for parity with dark mode moon and stars.
- v3 (2026-05-26): Open beak refined to `<` chevron shape.
- v2 (2026-05-26): Wallpaper scene added (moon, stars, sun, horizon).
  Light mode background changed to cool neutral.
- v1 (2026-05-26): Initial profile crow silhouette, dark and light
  variants, color inversion implemented.
