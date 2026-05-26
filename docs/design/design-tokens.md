# Waraq Design Tokens

Status: locked v1 (2026-05-26)
Applies to: every surface

This spec defines the global design language. Every other spec
references this one for colors, typography, spacing, and materials.

## Typography

System font stack only:
```
-apple-system, "SF Pro Text", system-ui, sans-serif
```

Two weights:
- `400` regular: body text, descriptions, secondary labels
- `500` medium: titles, active states, section headers

Sizes:
| Size | Use |
|---|---|
| 22 pt / 500 | Pane title |
| 15 pt / 500 | Modal title |
| 13 pt / 400 | Body / list rows |
| 12 pt / 400 | Sub-labels, controls |
| 11 pt / 500 | Section header (uppercase, letter-spacing 0.5pt) |
| 11 pt / 400 | Helper text |
| 10 pt / 400 | Metadata, timestamps |
| 9 pt / 500 | Pills, badges (uppercase, letter-spacing 0.3pt) |

Line height: 1.3 for body, 1.4 for paragraphs, 1.2 for headings.

Never use weight 600 or 700. Never use Title Case. Never ALL CAPS
except small section headers and pill badges.

## Colors

All colors must resolve in both light and dark mode. Use NSColor
semantic tokens for chrome. Brand accents are allowed inside content
surfaces only (preview images, app icon, etc).

### Chrome (semantic, via NSColor)

| Token | NSColor | Use |
|---|---|---|
| Window bg | `windowBackgroundColor` | Settings window base |
| Primary text | `labelColor` | Titles, body |
| Secondary text | `secondaryLabelColor` | Helper text, section labels |
| Tertiary text | `tertiaryLabelColor` | Chevrons, shortcuts |
| Quaternary text | `quaternaryLabelColor` | Disabled |
| Hairline | `separatorColor` | Dividers, thumb borders |
| Selection | `selectedContentBackgroundColor` @ 0.18 | Active sidebar row, list selection |
| Control bg | `controlBackgroundColor` | Input bg |
| Material | `.regularMaterial` | Popovers, sheets, sidebar |

### Semantic states

| Token | Color | Use |
|---|---|---|
| Live / OK | `systemGreen` (`#34c759`) | Live status, success |
| Paused / Warn | `systemOrange` (`#ffb400`) | Paused, partial compat |
| Off / Error | `systemGray` / `systemRed` | Off, destructive |
| Info / Accent | `systemBlue` (`#5ea7ff`) | Recommended, active highlight |

### Brand (content only)

| Color | Hex | Use |
|---|---|---|
| Crimson | `#c83a4a` (dark) / `#a82838` (light) | Icon eye, brand moments |
| Cream | `#f2ece4` | Crow silhouette on dark icon |
| Near black | `#0c0808` | Crow silhouette on light icon |
| Deep crimson bg | `#4a1626` to `#000000` radial | Dark icon background |
| Cool neutral bg | `#f5f7fa` to `#b8bec8` radial | Light icon background |

Never use brand colors in Settings chrome. Brand stays in icon, in
preview thumbnails, and inside content surfaces.

## Layout

### Spacing scale
- 4, 6, 8, 10, 12, 14, 16, 20, 22, 24, 28, 32 pt

Use rem-equivalent vertical rhythm for sections (multiples of 4 pt).

### Radii
- 4 pt: chips, small pills
- 5 pt: popup chips
- 6 pt: buttons, list rows
- 8 pt: cards, grouped lists
- 10 pt: modal sheets
- 12 pt: large dialogs
- 46 pt: app icon (Apple squircle)

### Card pattern (used everywhere in Settings)
- Background: `Color.primary.opacity(0.04)` light, `Color.white.opacity(0.04)` dark
- Border: 0.5 pt `separatorColor`
- Radius: 8 pt
- Internal padding: 11 pt vertical, 14 pt horizontal per row
- Row dividers: 0.5 pt `separatorColor`, no horizontal inset

### Sub-setting indent (sub-controls under a parent toggle)
- Indent: 12 pt from left
- Left accent: 2 pt vertical bar in `systemBlue` @ 40%
- Vertical spacing: 8 pt between sub-controls

### Section header pattern
- Label: 11 pt, weight 500, `secondaryLabelColor`, uppercase, 0.5 pt
  letter-spacing
- Top margin: 22 pt
- Bottom margin: 8 pt
- Right side may include live count or status pill

## Controls

### Toggle (NSSwitch / SwiftUI Toggle .switch style)
- 36 × 20 pt
- ON: `systemGreen` track, white thumb
- OFF: `quaternaryLabelColor` track, near-white thumb (light) / off-white thumb (dark)

### Popup (Menu / NSPopUpButton)
- Pill style: 5 pt radius, 3 pt vertical / 6 pt right / 10 pt left padding
- Background: `Color.primary.opacity(0.06)`
- Trailing chevron: `chevron.down` at 12 pt
- Label: 12 pt regular

### Slider (NSSlider continuous)
- Track: 4 pt tall, 2 pt radius
- Filled track: `systemBlue` from start to thumb
- Empty track: `quaternaryLabelColor`
- Thumb: 14 pt circle, white with subtle shadow
- Always paired with a numeric readout right-aligned

### Button styles
- **Default**: transparent bg, 0.5 pt `separatorColor` border, 6 pt radius, 5 pt vertical / 12 pt horizontal padding, 12 pt label
- **Primary**: `systemBlue` bg, no border, white text, weight 500
- **Destructive**: red bg @ 0.15, red border @ 0.3, red text (`#ff8e8e` dark / `#a82838` light)

### Pills / badges
- 4 pt radius
- 3 pt vertical / 8 pt horizontal padding
- 10 pt text, weight 500, uppercase, 0.4 pt letter-spacing
- Background: 15% opacity of semantic color
- Text: matched semantic color (full opacity)

## Materials and effects

### Materials
- Popovers: `.regularMaterial`
- Settings window: standard window, no custom material
- Sidebar: `.regularMaterial` if isolating from content, else inherits
- Sheets: `.regularMaterial`

### Shadows
- Never on UI chrome
- Card lift: none (use border instead)
- Modal sheets: system default shadow (built into NSSheet)
- App icon at large display sizes: 0 10 40 black @ 0.5 (preview only,
  not in actual rendered icon)

### Animations
- Popover open / close: system default (NSPopover animator)
- Toggle: system default
- Sheet present / dismiss: system default
- Wallpaper crossfade: 0 to 3 sec, default 1.5 sec, ease-in-out
- Mode switch (Basic / Advanced): instant, no fade (avoids feeling
  modal)

## Accessibility

- Color contrast: WCAG AA minimum in both modes
- VoiceOver: every interactive element has a meaningful label
- Keyboard: standard tab navigation through interactive elements,
  Escape closes modals and popovers
- Reduce Motion: disable wallpaper crossfade, use instant switch
- Reduce Transparency: popovers fall back to solid
  `windowBackgroundColor` instead of `.regularMaterial`
- Increase Contrast: respected automatically via NSColor semantic
  tokens
- Minimum touch target: 28 × 28 pt (mouse 22 × 22 pt acceptable)

## Iconography

### SF Symbols only in shipped code
Tabler icons appear in mockups for convenience but never ship.
Mapping table:

| Mockup (Tabler) | SF Symbol |
|---|---|
| `ti-settings` | `gearshape` |
| `ti-device-desktop` | `display` |
| `ti-photo` | `photo.on.rectangle` |
| `ti-gauge` | `speedometer` |
| `ti-stack-2` | `square.stack.3d.up` |
| `ti-stethoscope` | `stethoscope` |
| `ti-info-circle` | `info.circle` |
| `ti-tools` | `wrench.and.screwdriver` |
| `ti-search` | `magnifyingglass` |
| `ti-folder` | `folder` |
| `ti-folder-open` | `folder.fill` |
| `ti-plus` | `plus` |
| `ti-chevron-down` | `chevron.down` |
| `ti-chevron-right` | `chevron.right` |
| `ti-selector` | `chevron.up.chevron.down` |
| `ti-player-pause` | `pause.fill` |
| `ti-player-play` | `play.fill` |
| `ti-volume` | `speaker.wave.2.fill` |
| `ti-volume-off` | `speaker.slash.fill` |
| `ti-player-skip-forward` | `forward.fill` |
| `ti-sun` | `sun.max` |
| `ti-sunrise` | `sunrise` |
| `ti-sunset` | `sunset` |
| `ti-moon` | `moon` |
| `ti-edit` | `pencil` |
| `ti-trash` | `trash` |
| `ti-leaf` | `leaf` |
| `ti-bolt` | `bolt` |
| `ti-flame` | `flame` |
| `ti-cpu` | `cpu` |
| `ti-adjustments` | `slider.horizontal.3` |
| `ti-arrows-sort` | `arrow.up.arrow.down` |
| `ti-external-link` | `arrow.up.right.square` |
| `ti-heart` | `heart` |
| `ti-bug` | `ant` |
| `ti-file-text` | `doc.text` |
| `ti-brand-github` | (custom asset, see app-icon.md) |
| `ti-brand-steam` | (custom asset, see settings-library.md) |
| `ti-feather` | `feather` (only as fallback placeholder) |
| `ti-power` / `ti-logout` | `power` |
| `ti-check` | `checkmark` |
| `ti-circle-check` | `checkmark.circle.fill` |
| `ti-circle-x` | `xmark.circle.fill` |
| `ti-alert-triangle` | `exclamationmark.triangle.fill` |

Icon sizing in code:
- Sidebar nav: 15 pt
- Toolbar button: 14 pt
- Inline body icon: 13 pt
- Row leading icon: 16 pt
- Pill leading icon: 11 pt

## Implementation notes

- SwiftUI for layout, AppKit interop where required (NSPopover,
  NSStatusItem, NSToolbar)
- Use `Color(nsColor: .labelColor)` etc, never hardcoded hex in
  chrome
- For light/dark variants of brand assets (icon), use
  `@Environment(\.colorScheme)` and switch the asset
- `.frame(maxWidth: .infinity)` is the norm for grouped list rows
- Avoid custom view modifiers when the system provides one (Toggle,
  Picker, Slider)
- Test every surface in both modes before merging

## Changelog
- v1.0 (2026-05-26): Initial lock.
