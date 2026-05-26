# Onboarding Spec

Status: locked v1 (2026-05-26)
Phase: 7 (final polish), but also triggered by Reset
Implementer: Claude Code (SwiftUI)

## Intent

The onboarding flow runs on first launch and any time the user
triggers a reset. Three screens in sequence. The middle screen
(hardware preset selector) is the unique feature: it auto-detects
the Mac model and recommends a performance preset.

## Form

Independent NSWindow (not a sheet over Settings). Modal in the sense
that it appears front and center, but does not block the system.

- Size: 640 × 540 pt
- Resizable: NO (fixed size)
- Style: standard NSWindow with traffic lights (yellow and green
  disabled visually but still present)
- Material: `.regularMaterial`
- Title: empty (cleaner first-run feel)

## Screen 1: Welcome

Centered content, ~480 pt internal width.

### Layout

- Top spacing: 60 pt
- App icon: 96 × 96 pt (light or dark variant per system appearance)
- Spacing: 24 pt
- Title: "Welcome to Waraq" at 28 pt weight 500
- Spacing: 8 pt
- Tagline: "Animated wallpapers, the way Apple would have built them"
  at 14 pt `secondaryLabelColor`, max 360 pt wide, line height 1.5,
  centered
- Spacing: 40 pt
- Three bullet points stacked, each row:
  - Leading icon (24 pt SF Symbol) in `systemBlue`
  - Title (13 pt weight 500) and sublabel (11 pt
    `secondaryLabelColor`)
  - 14 pt gap between rows
- Spacing: 40 pt
- Footer with progress dots (see Common elements) and "Continue"
  primary button

### Bullet points
1. `speedometer` "Built for performance" / "Lightweight, hardware
   accelerated, pause-aware"
2. `display` "Per-display profiles" / "Plug into your office and
   home setups, profiles auto-restore"
3. `lock.shield` "Private by default" / "No accounts, no cloud, no
   telemetry without your say"

## Screen 2: Hardware preset

Centered content, ~520 pt internal width.

### Layout

- Top spacing: 30 pt
- Progress dots (see below)
- Spacing: 32 pt
- Title: "Tune Waraq to your Mac" at 24 pt weight 500, centered,
  letter-spacing -0.2 pt
- Spacing: 6 pt
- Subtitle: "Pick a starting preset. You can change every setting
  later." at 13 pt `secondaryLabelColor`, centered
- Spacing: 26 pt
- Hardware detection banner (see below)
- Spacing: 22 pt
- Three preset cards (see below)
- Spacing: 28 pt
- "Customize manually instead" link, centered, with leading
  `slider.horizontal.3` 13 pt
- Spacing: 24 pt
- Footer with Back / Skip setup / Continue buttons

### Hardware detection banner

Card style with `systemBlue` @ 8% bg, `systemBlue` @ 25% border, 8
pt radius, 10 pt vertical / 14 pt horizontal padding.

- Leading: `cpu` 18 pt `systemBlue`
- Text block:
  - Line 1: "{chip name} · {RAM} · macOS {version}" at 12 pt weight
    500
  - Line 2: "Detected automatically. Override any time." at 11 pt
    `secondaryLabelColor`

Chip name format: "Apple M4 Max", "Apple M2", "Intel Core i7" etc.

### Preset cards (three, grid 1fr 1fr 1fr, 12 pt gap)

Each card:
- Padding: 16 pt vertical, 14 pt horizontal
- Background: `Color.primary.opacity(0.04)` (default), `systemBlue`
  @ 6% (selected)
- Border: 0.5 pt `Color.primary.opacity(0.08)` (default), 2 pt
  `systemBlue` (selected, the "Recommended" card)
- Radius: 10 pt

Layout per card:
- Top row: leading icon (16 pt) + title (14 pt weight 500), 8 pt gap
- Tagline: 11 pt `secondaryLabelColor`, line height 1.4, 4 pt top
  margin, 12 pt bottom margin
- Four bullets (each: leading `checkmark` 11 pt + text 11 pt), 5 pt
  vertical gap

#### Card 1: Conservative
- Icon: `leaf` `secondaryLabelColor`
- Tagline: "Quiet, battery friendly. Best for older Macs."
- Bullets:
  - 30 fps cap
  - All pause triggers on
  - Low render quality
  - 100 MB memory cap

#### Card 2: Balanced
- Icon: `bolt` `secondaryLabelColor`
- Tagline: "Smooth playback, smart pausing."
- Bullets:
  - 60 fps cap
  - Fullscreen + battery pause
  - Auto render quality
  - 250 MB memory cap

#### Card 3: Ultra (recommended for high-end Macs)
- Icon: `flame` `systemBlue`
- Title color: full `labelColor` (more emphasis)
- Tagline emphasis: "No compromises. Your {chip name} can handle it."
- Bullets in white-emphasis text (not muted):
  - Match refresh rate (up to 120 fps)
  - Low Power Mode pause only
  - High render quality + HDR
  - 500 MB memory cap
- Checkmarks in `systemBlue` instead of muted
- "Recommended" pill straddling the top edge of the card:
  - Position: top center, -10 pt offset
  - Background: `systemBlue`
  - Padding: 2 pt vertical, 10 pt horizontal
  - Radius: 10 pt
  - Text: "RECOMMENDED" 10 pt weight 500 white uppercase, 0.3 pt
    letter-spacing
  - Always visible regardless of which card is selected

#### Recommendation logic

Compute at runtime in onboarding view. Algorithm:

```
preset = "Balanced" (default)

if chip is Intel:
    preset = "Conservative"
elif chip family in [M1, M2, M3]:
    if chip is base (not Pro/Max/Ultra):
        preset = "Balanced"
    else:
        preset = "Balanced"
elif chip family in [M4, M5+]:
    preset = "Ultra"

if RAM < 16 GB:
    preset = downgrade(preset)  // e.g., Ultra -> Balanced

if macOS < 14:
    preset = "Conservative"

if is_portable AND battery_health < 80%:
    preset = downgrade(preset)
```

`is_portable`:
- True for MacBook Pro / Air models
- False for Mac mini, iMac, Mac Studio, Mac Pro

Tagline text changes:
- Portable: include "battery friendly" framing in Conservative card
- Desktop: focus on "power mode" framing in Conservative card

### Mode selection

- Default: the recommended card is pre-selected
- Click any card to select it (the 2 pt blue border moves)
- Selection persists across screen navigation

### "Customize manually instead" link

- 12 pt `systemBlue` with leading `slider.horizontal.3`
- Action: jumps to next screen with preset state = "Custom" (no
  preset applied, defaults to Balanced internally)

## Screen 3: Pick your first wallpaper

Centered content, ~520 pt internal width.

### Layout

- Top spacing: 30 pt
- Progress dots
- Spacing: 32 pt
- Title: "Pick your first wallpaper" at 24 pt weight 500, centered
- Spacing: 6 pt
- Subtitle: "We bundled three. Add more from the library anytime."
  at 13 pt `secondaryLabelColor`, centered
- Spacing: 28 pt
- Three wallpaper cards (similar to Library grid cards, larger)
- Spacing: 12 pt
- "Skip and use a still wallpaper for now" link, centered
- Spacing: 32 pt
- Footer with Back / Finish setup buttons

### Wallpaper cards

Each card 150 × 100 pt (16:10 thumbnail) + title row below.
Same card style as Library grid (see settings-library.md).

Default bundled wallpapers:
1. "Howling Fjord" (video, ~10 MB, default selection)
2. "Westfall Sunset" (image, ~2 MB)
3. "Calm Shader" (web/WebGL, ~50 KB)

Selected card: 2 pt `systemBlue` border. Default: card 1 selected.

## Common elements

### Progress dots

3 small dots, horizontally centered, near the top of screens 2 and
3. (Skipped on screen 1.)

- Each dot: 6 pt circle
- Inactive: `tertiaryLabelColor`
- Active: 22 × 6 pt rounded rect (3 pt radius) in `systemBlue` (the
  pill represents the current step)
- Gap: 6 pt between dots
- Centered horizontally

Note: screen 1 (Welcome) does not show progress dots. They appear
starting screen 2.

### Footer buttons

Padding: 20 pt top, 24 pt sides, 24 pt bottom.
Top border: 0.5 pt `separatorColor`.

Layout per screen:
- Screen 1: just "Continue" (primary, right side)
- Screen 2: "Back" (text-only, left side) | spacer | "Skip setup"
  (default style) + "Continue" (primary), 10 pt gap
- Screen 3: "Back" (text-only, left side) | spacer | "Finish setup"
  (primary)

Button styles:
- Text-only "Back": no border, no background, `secondaryLabelColor`
  label
- Default: 0.5 pt `separatorColor` border, transparent bg, 6 pt
  radius, 6 pt vertical / 16 pt horizontal padding
- Primary: `systemBlue` bg, no border, white text weight 500, 6 pt
  radius, 7 pt vertical / 20 pt horizontal padding

## Behaviors

### Persistence

If the user is interrupted mid-onboarding (closes window, force
quits, etc.), the next launch resumes from screen 1 (not the
middle). Onboarding is "complete" only after Finish on screen 3.

Stored via `@AppStorage("onboardingComplete")` Bool.

### Skip setup

Clicking "Skip setup" on screen 2 advances directly to screen 3 but
uses the recommended preset internally. User can still pick a first
wallpaper or skip that too.

### Skip wallpaper

The "Skip and use a still wallpaper for now" link on screen 3 closes
onboarding without setting an animated wallpaper. The system
continues with the default static macOS wallpaper.

### Finish

After Finish, the onboarding window closes and:
1. Selected preset is applied (writes to Performance settings)
2. Selected wallpaper is set on the primary display
3. Settings window does NOT auto-open (user can find it from menu
   bar)
4. A one-time hint balloon appears next to the menu bar status icon:
   "Waraq lives here. Click for controls." Auto-dismisses after 4
   seconds.

### Reset re-entry

When triggered from Diagnostics > Reset, the onboarding starts at
screen 1. Settings are cleared first, then onboarding runs.

## Implementation notes

- Build as a single `OnboardingView` with `@State currentScreen: Int`
- Use `withAnimation(.easeInOut(duration: 0.25))` for transitions
  between screens (slide horizontally)
- Hardware detection in `HardwareInfo.swift` (Core), using:
  - `sysctlbyname("machdep.cpu.brand_string")` for chip name
  - `ProcessInfo.processInfo.physicalMemory` for RAM
  - `ProcessInfo.processInfo.operatingSystemVersion` for macOS
- Battery health via `IOPSCopyPowerSourcesInfo`, look at
  `kIOPSMaxCapacityKey` / `kIOPSDesignCapacityKey` (deprecated but
  still functional on most macOS versions)
- Portable detection: check model identifier prefix
  ("MacBookPro", "MacBook", "MacBookAir") vs others

## Out of scope

- Permissions onboarding (screen recording, notifications) (added
  v1.1; in v1, request these inline as needed)
- Account creation (no accounts in v1)
- Theme selection beyond appearance (v2)

## Changelog
- v1 (2026-05-26): Initial lock.
