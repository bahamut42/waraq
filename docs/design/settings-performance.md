# Settings: Performance Pane Spec

Status: locked v1 (2026-05-26)
Phase: 2 (basic) and 3 (governor logic, advanced controls)
Implementer: Claude Code (SwiftUI + Core)

## Intent

The Performance pane is Waraq's differentiator: every other live
wallpaper app on macOS gets dragged in reviews for battery drain.
The performance governor is the system that prevents this. The pane
exposes it.

In Basic mode, the pane shows three pause toggles and one render
quality popup. In Advanced mode, it exposes the full governor:
exemption lists, sliders for thresholds, per-display FPS caps,
resource limits.

## Form

Standard Settings content pane.

## Layout

Pane title: "Performance"

Sections in order:
1. Live status banner (always)
2. Pause behavior (basic) / Pause triggers (advanced)
3. Quality (basic) / Rendering (advanced)
4. Resource limits (advanced only)

## Sections

### Live status banner

A reassurance and proof element. Shows current resource usage in
real time.

- Card style with `systemGreen` @ 8% background, `systemGreen` @ 20%
  border, 8 pt radius, 10 pt vertical / 12 pt horizontal padding
- Leading: `leaf` icon at 18 pt `systemGreen`
- Text: 12 pt `labelColor` line height 1.4
  - "Waraq is using **{cpu}%** CPU and **{ram} MB** RAM right now."
  - Bold numbers in `systemGreen` (or `systemOrange` if approaching
    limits, `systemRed` if over).
  - Suffix: " Paused on N display(s)." or " Playing on N display(s)."

Updates every 1 second.

Data source:
- CPU: `host_processor_info()` filtered to Waraq process
- RAM: `task_info(TASK_BASIC_INFO)`

### Pause behavior (basic mode)

Card with three rows.

**Row 1: Pause when an app goes fullscreen**
- Toggle, default ON

**Row 2: Pause on battery**
- Toggle, default ON (only visible on portable Macs)
- Replace with "Pause in Power Saver mode" on desktop Macs

**Row 3: Pause in Low Power Mode**
- Toggle, default ON
- Observe `ProcessInfo.processInfo.isLowPowerModeEnabled`

### Pause triggers (advanced mode)

Card with four rows, sub-controls indented under each as relevant.

**Row 1: Pause when an app goes fullscreen**
- Toggle, default ON
- Sub-control (sub-setting indent): "Detect" popup
  - Default "True fullscreen only"
  - Options: True fullscreen only, Any fullscreen window
- Sub-control: "Exempt apps" + Manage button
  - Sublabel: "{N} apps will not trigger pause"
  - Manage button opens exemption list sheet (see below)

**Row 2: Pause on battery** (portable Macs only)
- Toggle, default ON
- Sub-control: "Below" slider 10 to 100 percent
  - Default 35
  - Track shows value, right side shows "{N}%" weight 500

**Row 3: Pause in Low Power Mode**
- Toggle, default ON

**Row 4: Pause on thermal pressure**
- Toggle, default ON
- Sub-control: "Pause at" popup
  - Default "Fair"
  - Options: Nominal, Fair, Serious, Critical (system levels)
  - Source: `ProcessInfo.processInfo.thermalState`

### Exemption list sheet

Triggered by Pause triggers > Pause when an app goes fullscreen >
Manage button.

Modal sheet, 420 pt wide, 480 pt tall.

- Title: "Exempt apps"
- Body: "These apps will not trigger wallpaper pause when fullscreen"
- List of installed applications with checkbox per app
- Search field at top
- Footer: Cancel + Done buttons

Pre-populated suggestions to highlight at top:
- Apps that have been observed going fullscreen
- Games (apps in `/Applications` with names containing game-like
  identifiers)

### Quality (basic mode)

Card with one row.

**Row 1: Render quality**
- Popup, default "Auto"
- Options: Auto, High, Medium, Low

Mapping:
- Auto: adapts based on hardware preset (see onboarding.md)
- High: full-resolution decode, no FPS cap
- Medium: 1080p decode (downscale if higher), 60 fps cap
- Low: 720p decode, 30 fps cap

### Rendering (advanced mode)

Card with four rows.

**Row 1: Render quality**
- Same popup as basic

**Row 2: Decode mode**
- Popup, default "Hardware only"
- Options: Hardware only, Auto, Software fallback
- Sublabel: "Software fallback impacts battery life"
- Implementation: passed to `AVPlayerItem` decoder hint

**Row 3: Cap frame rate per display**
- Toggle, default ON
- Sub-control: one slider per connected display
  - Label: display name (12 pt `secondaryLabelColor`, min-width 96 pt)
  - Slider: 10 to 120 fps range
  - Value: 12 pt weight 500 right-aligned, "{N} fps"
- Vertical gap: 10 pt between displays

**Row 4: Drop frames on heavy load**
- Toggle, default ON
- Sublabel: "Sacrifices smoothness to protect responsiveness"

### Resource limits (advanced mode)

Card with two rows.

**Row 1: Max memory per wallpaper**
- Slider, range 50 to 500 MB, default 250
- Label "Max memory per wallpaper" + "{N} MB" right-aligned weight 500
- Below slider: range labels "50" and "500" at 10 pt
  `secondaryLabelColor`

**Row 2: Yield to GPU-heavy apps**
- Toggle, default OFF
- Sublabel: "Pause when games or 3D apps are active"
- Implementation: detect via `IOServiceMatching("AGXAccelerator")` or
  process list scanning for known GPU-heavy patterns

## Performance governor (Core implementation)

`PerformanceGovernor.swift` (per PLAN.md section 3) observes:

- `NSWorkspace.shared.activeSpaceDidChangeNotification`
- `CGWindowListCopyWindowInfo` for fullscreen detection (poll every
  2s or on space change)
- `NSWindow.occlusionState` per Waraq window
- `ProcessInfo.processInfo.thermalState`
- `ProcessInfo.processInfo.isLowPowerModeEnabled`
- `NSWorkspace.shared.notificationCenter` for screen sleep
- `IOPSCopyPowerSourcesInfo` for battery state and charge level
- Active fullscreen app name vs exemption list

Output: per-display playback state (Play / Pause / Throttle).

Rules priority (highest wins):
1. Display sleeping → Pause
2. App-fullscreen on this display + not in exemption → Pause
3. Thermal Critical → Pause
4. On battery below threshold + battery rule on → Pause
5. Low Power Mode + LPM rule on → Pause
6. Thermal Fair/Serious + thermal rule on → Throttle (FPS / 2)
7. Reduce Motion enabled → freeze on first frame
8. Otherwise → Play at configured fps cap

Governor decisions are emitted to the engine pipeline. Engines
respect Throttle by halving their effective FPS.

## Behaviors

### Live banner updates

- Polls every 1 second when pane is open
- Pauses polling when pane is hidden
- Color shifts:
  - Green: under 50% of configured memory limit, under 5% CPU
  - Orange: 50 to 80% of limits
  - Red: above 80%

### Exemption list

- Persisted to `UserDefaults` (small list, no separate file needed)
- Default suggestions: known game launchers, video apps (Final Cut,
  Premiere)
- User can also right-click any active fullscreen app from the menu
  bar dropdown to add to exemption list (future enhancement)

### Per-display FPS cap response

- When toggled OFF, all displays default to "Match refresh rate"
- When ON, individual sliders are active
- Min 10, max 120 (Waraq does not render above 120fps regardless)
- Changing a slider value applies immediately to that display

### Yield to GPU-heavy apps

- Polls every 5 seconds (cheap)
- Pauses all displays if Waraq detects active GPU-heavy process
- Resumes when GPU-heavy process ends

## Implementation notes

- `PerformanceGovernor` is a singleton observed via Combine
  `@Published` properties
- Engines (Video, Web, Image) subscribe to governor state
- Live status banner is its own SwiftUI view that subscribes to a
  separate `ResourceMonitor` (different from governor, just reports
  usage)
- All thresholds (battery, thermal, memory) stored in `@AppStorage`
- Exemption list stored in `UserDefaults` as `[String]` of bundle IDs

## Out of scope

- Custom render profile per wallpaper type (v1.1)
- GPU memory inspection (private API only, deferred)
- Network bandwidth controls (not applicable until cloud sync)

## Changelog
- v1 (2026-05-26): Initial lock.
