# Settings: Displays Pane Spec

Status: locked v1 (2026-05-26)
Phase: 2 (basic structure) and 4 (display profiles + detail sheet)
Implementer: Claude Code (SwiftUI + AppKit)

## Intent

The Displays pane shows currently connected monitors, saved display
profiles (for the user's other contexts like Office, Home, Travel),
and rules for what happens when displays connect or disconnect.

This is the centerpiece for multi-monitor and portable Mac users.

## Form

Standard Settings content pane.

## Layout

Pane title: "Displays"

Sections in order:
1. Visual arrangement diagram (always, even in basic)
2. Connected now (always)
3. Saved profiles (always, shown empty-state if no profiles yet)
4. When displays change (always)
5. Color and HDR (advanced only)
6. Synchronization (advanced only)

## Sections

### Visual arrangement diagram

- Card surface, 20 pt vertical padding, 16 pt horizontal
- Centered horizontal layout of mini display rectangles
- Each rectangle is proportional to actual display resolution
- Mini base/stand: 3 pt tall, 22 pt wide gradient at bottom of each
- Display fill: linear gradient using the wallpaper's accent color
  (read from manifest), 1.5 pt border
- Main display has a blue dot marker (top-right corner) and blue
  accent border instead of white
- Display label inside the rectangle, top-left, 8-9 pt
- Click and drag (in real implementation) reorders, but for v1 just
  read-only display

Sizes (proportional to real resolution):
- Built-in Retina (typical 16:10): 70 × 44 pt
- 16:9 monitor (typical 1080p / 4K): 80 × 45 pt
- Studio Display ultrawide: 110 × 62 pt (5K)

### Connected now

Header: "CONNECTED NOW" + right-side count "{N} displays"

Card with one row per connected display.

Each row:
- Height: 50 pt
- Padding: 12 pt vertical, 14 pt horizontal
- Layout: thumbnail / text block / status pill / Configure button

Thumbnail (48 × 30 pt):
- Wallpaper accent gradient
- 1 pt border (white at 20% / blue at 40% if main)
- Top-right blue dot if main display (3 pt circle with dark ring)

Text block:
- Title: 13 pt / weight 500 / `labelColor`, with inline tags:
  - User-set profile name pill (e.g., "Home", "Office") at 9 pt
    weight 500 uppercase, `labelColor` on `Color.primary.opacity(0.1)`
  - "MAIN" pill at 9 pt weight 500 uppercase, `systemBlue` on
    `systemBlue` @ 18% (only on primary display)
- Subtitle: full specs at 11 pt `secondaryLabelColor`, format:
  `{width} × {height} · {Hz} Hz · {color space}` plus `· HDR` if
  display reports HDR support

Right side:
- "Live" pill: 5 pt green dot + "LIVE" 10 pt weight 500 `systemGreen`
  on `systemGreen` @ 15%
- "Configure" button: standard button style with trailing
  `chevron.right` 11 pt. Opens display detail sheet (below).

### Saved profiles

Header: "SAVED PROFILES" + right-side text "{N} saved · auto-restore
on connect"

Card with one row per saved (disconnected) profile.

Same row structure as Connected Now but:
- Opacity: 0.78
- Thumbnail: grayscale-filtered, lower saturation
- Subtitle ends with "· Last seen {relative time}"
- Right side: edit (`pencil`) and forget (`trash`) icon buttons
  instead of status pill and Configure
- Forget button uses red icon (`#ff8e8e` dark / `#a82838` light)

Below the rows, an informational note row (single line, no card):
- 11 pt `tertiaryLabelColor`
- "Profiles save wallpaper, per-display config, and position. They
  auto-restore when the same display is connected again."

Footer: Apple-style + / - segmented buttons (see design-tokens.md
for the standard pattern). Plus adds a manual profile (rare),
minus deletes the selected profile (with confirmation).

### When displays change

Card with three rows.

**Row 1: When a known display connects**
- Popup, default "Restore profile"
- Sublabel: "Profile is recognized by hardware ID"
- Options: Restore profile, Ask me, Use default wallpaper, Ignore

**Row 2: When a new display connects**
- Popup, default "Ask me"
- Sublabel: "Hardware ID not seen before"
- Options: Ask me, Use default wallpaper, Mirror main display, Ignore

**Row 3: Notify on connect or disconnect**
- Toggle, default OFF
- Sublabel: "Sends a push notification when profile changes too"
- Uses `UNUserNotificationCenter`

### Color and HDR (advanced only)

Card with two rows.

**Row 1: Match display color profile**
- Toggle, default ON
- Sublabel: "Renders wallpaper in each display's native gamut"
- Implementation: `CGDisplayCopyColorSpace()` per display

**Row 2: HDR rendering**
- Toggle, default OFF
- Sublabel: "{primary display name} only, HDR10 content"
- Disabled if no connected display supports HDR

### Synchronization (advanced only)

Card with two rows.

**Row 1: Sync playback across displays**
- Toggle, default ON
- Sublabel: "When in Span mode, align frame timing"

**Row 2: Stagger startup**
- Toggle, default ON
- Sublabel: "Load wallpapers one display at a time to reduce launch
  spike"

## Display profile model

A profile is identified by a composite key from
`IODisplayCreateInfoDictionary()`:
- Vendor ID
- Product ID
- Serial number (if available)
- EDID hash (fallback when serial is unavailable)

When a display connects:
1. Compute composite key
2. Look up in profile store (`~/Library/Application
   Support/Waraq/profiles.json`)
3. If found: apply profile (wallpaper, fit, volume, fps cap)
4. If not found: per "When a new display connects" setting

When a display disconnects:
1. Compute composite key
2. Save current per-display config to profile store with timestamp

When two identical-model displays are connected (rare but possible):
- EDID serial usually differentiates
- If both report identical serial: prompt user to assign profiles or
  treat second as "new display"

### Profile storage format

`profiles.json`:
```json
[
  {
    "id": "20a4-a02e-AABBCC123456",
    "name": "Office",
    "vendor_id": "0x20a4",
    "product_id": "0xa02e",
    "serial": "AABBCC123456",
    "edid_hash": "abc123...",
    "last_resolution": "3840x2160",
    "last_refresh": 60,
    "wallpaper_id": "com.author.howlingfjord",
    "config": {
      "fit": "fill",
      "volume": 0,
      "muted": true,
      "fps_cap": 60,
      "shuffle_enabled": false
    },
    "last_seen": "2026-05-22T14:33:00Z",
    "created": "2026-05-01T09:12:00Z"
  }
]
```

## Display detail sheet (per-display Configure)

Triggered by the Configure button in any connected display row.

Form: `NSSheet` attached to the Settings window. Centered on the
window, modal but not blocking other apps.

- Size: 480 × 540 pt, fixed
- Material: `.regularMaterial`
- Title: "Configure {display name}"

Layout:
1. Header card: thumbnail (large 200 × 124 pt) + display name +
   profile name (editable inline) + specs line
2. Section: Wallpaper (picker, similar to Wallpapers pane defaults)
3. Section: Playback (volume slider, mute toggle, fit popup,
   loop toggle)
4. Section: Rotation (independent rotation toggle, interval, source)
5. Section: Advanced (advanced-only: FPS cap slider, color profile
   override, HDR toggle if supported)
6. Footer: Cancel + Done buttons

Per-display settings here override global Wallpapers pane defaults.

## Behaviors

### Profile rename inline

Click the "Home" pill (or any user-set profile name pill) on a
connected display row to edit inline. NSTextField appears in place,
auto-selects all, returns to pill on Return or Escape.

Default profile names: "Profile 1", "Profile 2", etc. User can
overwrite with any string (max 24 chars).

### Forget with confirmation

Clicking the forget (trash) button on a saved profile shows a
confirmation alert:
- Title: "Forget profile '{name}'?"
- Body: "Waraq will not auto-restore wallpapers and settings for
  this display. The display will be treated as new on next
  connect."
- Buttons: Cancel (default), Forget (destructive red)

### Disconnect notification

If "Notify on connect or disconnect" is ON, push notifications fire
for both events. Format:
- Connect: "{display name} connected" / "Profile {name} restored"
- Disconnect: "{display name} disconnected" / "Settings saved"

Uses `UNUserNotificationCenter` with deduplication (within 10s).

### Visual arrangement live updates

When displays connect/disconnect, the diagram rebuilds within 200 ms.
Use `NSApplication.didChangeScreenParametersNotification`.

## Implementation notes

- `DisplayManager` in `Core/DisplayManager.swift` (per PLAN.md
  section 3) manages all this
- Profile persistence via Codable to JSON file
- Use `CGGetActiveDisplayList()` for enumeration, `CGDisplayIO*` for
  EDID
- Profile detail sheet is a separate SwiftUI view presented via
  `.sheet(item:)`
- Inline editing of profile name uses
  `TextField($name).textFieldStyle(.plain)` with focus management

## Out of scope

- Drag-to-rearrange in the visual diagram (read-only in v1)
- Per-app display preferences (e.g., "always use this profile when
  Chrome is open") (v2)

## Changelog
- v1 (2026-05-26): Initial lock.
