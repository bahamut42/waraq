# Menu Bar Dropdown Design Spec

Status: locked v1.1 (2026-05-26)
Phase: 2
Implementer: Claude Code (SwiftUI + AppKit)

## Intent

The menu bar dropdown is the daily-use control surface for Waraq. It
opens when the user clicks the status item, shows what is currently
playing, and exposes the three actions a user wants while mid-task
(pause, mute, switch). Anything that is not "I want this right now"
lives in Settings.

## Form

`NSPopover`, not `NSMenu`. NSMenu cannot host a preview image or
display thumbnails, both of which are essential for a wallpaper app.

- Behavior: `.transient` (closes on click-outside)
- Animates: yes (default popover animation)
- Anchor: `NSStatusItem.button`
- Arrow position: `.maxY` (arrow points up at status item)
- Material: `.regularMaterial` (auto-adapts to light/dark)

## Layout

Total popover width: 280 pt
Total height: dynamic, governed by content (typical 380 to 440 pt)

Vertical sections, top to bottom:

1. Preview hero (8 pt padding, 16:10 aspect ratio, 12 pt corner radius)
2. Title + status line (10/14/8 pt padding)
3. Quick actions row (0/10/10 pt padding, three equal buttons, 5 pt gap)
4. Hairline divider (separatorColor, 12 pt horizontal inset)
5. Displays section header (10/14/6 pt padding, label + mode chip)
6. Display rows (8 pt horizontal padding, 1 pt vertical gap between rows)
7. Hairline divider (separatorColor, 12 pt horizontal inset, 8 pt top margin)
8. Footer menu (6/8/8 pt padding: Open library, Settings, Quit)

## Components

### Preview hero

- Aspect ratio: 16:10
- Corner radius: 8 pt
- Source: render of the actual wallpaper currently playing on the
  primary display, refreshed every 2 seconds while popover is open
- Fallback: solid color from wallpaper manifest accent if render is
  unavailable
- Top-right "Live" badge:
  - Position: 8 pt from top, 8 pt from right
  - Pill: 10 pt radius, black @ 0.55 background
  - Dot: 5 pt circle, `systemGreen`
  - Text: "Live" / 10 pt / weight 500 / white
  - States: "Live" (`systemGreen`), "Paused" (`systemOrange`), "Off"
    (`systemGray`)

### Title block

- Title: wallpaper display name, 13 pt, weight 500, `labelColor`,
  line height 1.3
- Status line: "Playing on N displays" or "Playing" or "Paused" / 11
  pt / `secondaryLabelColor`
- Max one line each, truncate with tail ellipsis

### Quick action buttons

Three equal-width buttons, 5 pt gap, 7 pt vertical padding.

- Background: adaptive pill (see design-tokens.md)
- Hover, pressed: standard pill button states
- Corner radius: 6 pt
- Icon: 13 pt SF Symbol, `labelColor`, leading
- Label: 11 pt, weight 400, `labelColor`
- No border

Actions:
1. Pause / Resume (`pause.fill` / `play.fill`)
2. Muted / Unmuted (`speaker.slash.fill` / `speaker.wave.2.fill`)
3. Next (`forward.fill`) cycles to next wallpaper in current
   display's shuffle queue, disabled when shuffle is off

State: all three reflect current global state when "Same on all
displays" mode is active; reflect primary display when in "Per
display" mode.

### Displays section header

- Label: "DISPLAYS" / 11 pt / weight 500 / `secondaryLabelColor` /
  letter-spacing 0.4 pt / uppercase
- Mode chip on right:
  - Background: adaptive pill
  - Padding: 3 pt vertical, 6 pt right, 8 pt left
  - Radius: 5 pt
  - Text: 11 pt, `labelColor`, current mode name
  - Trailing chevron: 11 pt `chevron.down`, `secondaryLabelColor`
  - Click opens NSMenu: Same on all / Per display / Span / Single

Modes:
- **Same on all**: one wallpaper picker, all displays show it
- **Per display**: each display has its own wallpaper (default for
  multi-monitor)
- **Span**: one wallpaper stretches across all displays (single
  AVPlayer, viewport-clipped per window)
- **Single**: one display gets a wallpaper, others stay system
  default

### Display rows

- Height: 36 pt
- Padding: 6 pt all sides
- Corner radius: 6 pt
- Layout: thumbnail / text block / chevron

Thumbnail:
- Size: 38 × 24 pt
- Corner radius: 3 pt
- Border: 0.5 pt `separatorColor`
- Content: live snapshot of that display's wallpaper

Text block:
- Display name: 12 pt, weight 500 if active, 400 otherwise,
  `labelColor`, line height 1.25
- Current wallpaper: 10 pt, `secondaryLabelColor`, line height 1.3,
  truncate

Trailing: `chevron.right` at 12 pt, `tertiaryLabelColor`

States:
- Default: transparent background
- Hover: `Color.primary.opacity(0.04)`
- Active / selected: `selectedContentBackgroundColor` at 18% alpha

Click action: opens display detail sheet (see settings-displays.md
for the sheet spec).

### Footer menu

Three rows, 6 pt vertical padding, 8 pt horizontal, 6 pt corner
radius.

- Open library: `photo.on.rectangle` / 12 pt label
- Settings: `gearshape` / 12 pt label / opens Settings window
- Hairline divider (`separatorColor`, 4 pt horizontal inset)
- Quit Waraq: `power` / 12 pt label / trailing `⌘Q` shortcut hint in
  11 pt monospace, `tertiaryLabelColor`

Hover state on all three: `Color.primary.opacity(0.04)` background.

## Behaviors

### Popover lifecycle

- Opens on click of status item button
- Closes on click outside, Escape, or selecting Open library /
  Settings / Quit
- Does NOT close on quick action click, mode chip change, or display
  row click

### Preview refresh

- Captures current frame from primary display engine every 2 seconds
  while popover is open
- Pauses capture when popover closes
- Paused engines show last frame with 20% black overlay

### Appearance change

- When system switches appearance while popover is open, all
  surfaces update live without relaunch or flicker

### Quick actions

- Pause: global by default. When mode is Per display, acts on
  primary display only and shows a subtle tooltip on first use.
- Mute: per-wallpaper, disabled for image type.
- Next: disabled if shuffle off.

### Mode chip

- Opens NSMenu with: Same on all / Per display / Span / Single
- Current mode shows checkmark
- Span disabled if only one display connected
- Single reveals a submenu of display names to pick the target

### Keyboard

- `⌘Q`: quit
- `Space`: pause toggle (when popover focused)
- `M`: mute toggle (when popover focused)
- `→` on display row: open detail sheet

### Accessibility

- VoiceOver labels on all buttons
- Display rows are accessible buttons
- WCAG AA contrast in both modes (automatic via semantic colors)
- Reduce Transparency: popover falls back to solid
  `windowBackgroundColor`
- Increase Contrast respected automatically

## Status item icon

See app-icon.md for the template SVG. Requirements summary:
- Template-rendered (`NSImage.isTemplate = true`)
- 18 × 18 pt
- State variants by alpha:
  - Live (rendering): 100%
  - Paused: 70% with subtle outline
  - Off: 40%

## Implementation notes

- `NSPopover` hosting SwiftUI via `NSHostingController`
- `.frame(width: 280)` on content
- `MenuBarController.swift` per PLAN.md section 3
- Display thumbnails via `SCStream` at 1 fps while open, downscaled
  to 38 × 24 pt
- All colors via NSColor semantic tokens

## Out of scope

- Display detail sheet (see settings-displays.md)
- Settings window (see settings-shell.md and related specs)
- Status item icon final design (see app-icon.md)
- Onboarding flow (see onboarding.md)

## Changelog

- v1.1 (2026-05-26): Renamed Murmur to Waraq. Elevated dark mode to
  global requirement (in design-tokens.md). Consolidated colors to
  NSColor semantic tokens.
- v1.0 (2026-05-26): Initial lock.
