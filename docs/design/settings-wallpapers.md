# Settings: Wallpapers Pane Spec

Status: locked v1 (2026-05-26)
Phase: 4 (rotation, schedule, transitions)
Implementer: Claude Code (SwiftUI + Core)

## Intent

The Wallpapers pane is the rules and defaults pane. It defines what
new wallpapers inherit, how wallpapers rotate, and time-based
scheduling. This is separate from the Library pane (which manages
the collection itself).

The schedule feature (time-of-day wallpaper switching) is a flagship
feature.

## Form

Standard Settings content pane.

## Layout

Pane title: "Wallpapers"

Sections in order:
1. Live status banner (always)
2. Defaults for new wallpapers (always)
3. Rotation (always)
4. Schedule (advanced only)
5. Transitions (advanced only)

## Sections

### Live status banner

Card with `systemBlue` @ 7% bg, `systemBlue` @ 22% border, 8 pt
radius, 10 pt vertical / 12 pt horizontal padding.

- Leading: 32 × 20 pt mini wallpaper thumbnail (3 pt radius, 0.5 pt
  white @ 15% border)
- Text: 12 pt `labelColor` line height 1.4
  - Format: "**{wallpaper name}** · {slot name if schedule} ·
    changes at {time}" OR " · next rotation in {duration}"
  - Bold for wallpaper name (weight 500)

### Defaults for new wallpapers

Card with three rows.

**Row 1: Default volume**
- Slider, range 0 to 100, default 0 (muted)
- Layout: label + value display ("Muted" or "{N}%") on top, slider
  with mute/loud icons flanking on second line
- When value is 0, show "Muted" instead of "0%"
- Leading icon: `speaker.slash.fill` 13 pt `tertiaryLabelColor`
- Trailing icon: `speaker.wave.2.fill` 13 pt `tertiaryLabelColor`

**Row 2: Default fit mode**
- Popup, default "Fill"
- Options: Fill, Fit, Stretch, Center

**Row 3: Loop video by default**
- Toggle, default ON
- Sublabel: "Or play once and freeze on last frame"

### Rotation

Card. Layout depends on whether schedule is active.

**Row 1: Rotate wallpapers automatically**
- Toggle, default OFF
- Sublabel:
  - When schedule is OFF: no sublabel
  - When schedule is ON: "Disabled while a schedule is active"
  - When this toggle is ON and schedule is OFF: no sublabel

If rotation is ON and schedule is OFF, reveal sub-controls:
- **Rotate every** popup
  - Options: 5 minutes, 10 minutes, 30 minutes, 1 hour, Daily
  - Default 30 minutes
- **Source** popup
  - Options: Entire library, Favorites, Custom set
  - Default Entire library
  - "Custom set" prompts a sheet to pick wallpapers
- **Shuffle order** toggle, default OFF
  - Sublabel: "Random instead of sequential"

If rotation is ON but schedule is also ON: sub-controls visible but
at 50% opacity (inactive), with the "Disabled while a schedule is
active" message on the parent row.

### Schedule (advanced only)

Header: "SCHEDULE" with right-side status:
- 5 pt green dot + "Active" 10 pt `secondaryLabelColor` when ON
- Plain "Inactive" when OFF

Card with three rows + time slot rows.

**Row 1: Switch wallpapers by time of day**
- Toggle, default OFF
- Sublabel: "Overrides rotation while active"

If toggled ON, reveal time slot rows.

#### Time slot rows

Each slot row:
- Padding: 10 pt vertical, 14 pt horizontal
- Layout: time range / thumbnail / wallpaper info / row indicator

Components:
- Time range block (min-width 130 pt):
  - Time-of-day icon (sunrise / sun / sunset / moon) at 14 pt warm
    color (sunrise: warm orange, sun: yellow, sunset: orange-red,
    moon: blue-ish)
  - Range text in monospace 12 pt: "{HH:MM} → {HH:MM}"
- Thumbnail: 36 × 22 pt with wallpaper gradient, 3 pt radius, 0.5 pt
  white @ 15% border
- Wallpaper info (flex):
  - Title: 12 pt, weight 500 if this slot is currently active, 400
    otherwise, single line truncate
  - Slot label: 10 pt `secondaryLabelColor`, e.g., "Morning slot",
    "Daytime slot"

Active slot styling:
- Background: `systemBlue` @ 6%
- Left 2 pt border in `systemBlue` (no border on other sides)
- Title weight bumps to 500
- Inline pill: "NOW" 9 pt weight 500 `systemGreen` on `systemGreen`
  @ 15% bg

Default schedule (when toggle first enabled):
1. 06:00 → 12:00 Morning (sunrise icon)
2. 12:00 → 18:00 Daytime (sun icon)
3. 18:00 → 23:00 Evening (sunset icon)
4. 23:00 → 06:00 Night (moon icon, wraps midnight)

User can override the wallpaper assigned to each slot by clicking
the slot row (opens a wallpaper picker sheet).

Footer below schedule card: Apple-style + / - segmented buttons
(see design-tokens.md):
- Plus: opens a time slot editor sheet (start time, end time,
  wallpaper)
- Minus: removes the selected slot
- Minimum 2 slots required (user cannot delete down to 1)
- Slots must collectively cover all 24 hours; editor enforces this

### Transitions (advanced only)

Card with three rows.

**Row 1: Crossfade between wallpapers**
- Toggle, default ON
- Sublabel: "Smooth transitions during rotation and schedule changes"
- Implementation: `CABasicAnimation` on alpha for the AVPlayerLayer
  during swap

**Row 2: Fade duration**
- Slider, range 0 to 3 seconds, default 1.5
- Label: "Fade duration", value "{N} s" right-aligned weight 500
- Below: "0" and "3s" range labels at 10 pt
- Disabled (50% opacity) if Row 1 is OFF

**Row 3: Transition style**
- Popup, default "Mac fade" (per user request)
- Options:
  - Mac fade (the system-standard wallpaper switch fade)
  - Crossfade (linear A-to-B blend)
  - Fade to black (A fades out, then B fades in)
  - Cut (instant, no transition)

## Behaviors

### Schedule vs rotation precedence

If schedule is ON: rotation is paused. User toggling rotation while
schedule is ON gets a tooltip on first attempt: "Rotation is paused
while a schedule is active. Disable the schedule to use rotation."

If both are conceptually compatible (within a schedule slot,
rotating between several wallpapers), this is deferred to v1.1 via
"Source" being a curated set.

### Time slot wrap at midnight

Slots can cross midnight (e.g., 23:00 → 06:00). The schedule engine
treats this as a single contiguous slot.

### Currently-active slot detection

- Computed every minute (60s poll)
- Active slot highlighted with blue accent + NOW pill
- When the active slot changes, trigger wallpaper switch with the
  configured transition

### Schedule wallpaper picker (sub-sheet)

Triggered by clicking a slot row.

Sheet content:
- Title: "{Slot name} slot ({time range})"
- Body: wallpaper grid (same style as Library pane grid, scaled
  down) with current selection highlighted
- Optionally: "Pick from current library" vs "Pick from favorites"
- Footer: Cancel + Done

### Mac fade implementation

`AVPlayerLayer` fade-out (0.3s typical) over the outgoing wallpaper,
then fade-in over the new wallpaper. Mirrors what macOS does when
the system wallpaper changes. Used as the default transition for
maximum native feel.

## Implementation notes

- Schedule state stored in `UserDefaults` as a `[ScheduleSlot]`
- ScheduleSlot model: start (HH:MM), end (HH:MM), wallpaper ID,
  label (optional)
- Time slot evaluation in `ScheduleManager.swift`
- Rotation timer uses `Timer.scheduledTimer` with configured interval
- Transitions: AVPlayerLayer alpha animation via CALayer animation
- Default Mac fade is matched by reading the system wallpaper
  transition behavior (it is roughly 0.3s ease-in-out crossfade)

## Out of scope

- Audio reactivity (v1.1)
- Location-based wallpaper switching (e.g., "office wallpaper at
  Wi-Fi {SSID}") (v2)
- Calendar-event-based switching (v2)
- Per-day-of-week schedules (v1.1; v1 uses same schedule every day)

## Changelog
- v1 (2026-05-26): Initial lock.
