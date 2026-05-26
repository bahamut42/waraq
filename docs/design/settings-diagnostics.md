# Settings: Diagnostics Pane Spec

Status: locked v1 (2026-05-26)
Phase: 7 (final polish)
Implementer: Claude Code (SwiftUI + Core)
Visibility: Advanced mode only

## Intent

The Diagnostics pane holds logging, performance overlay, telemetry,
and reset functionality. It exists for developers, power users, and
bug reporters. It only appears in the sidebar when the global
Advanced toggle is ON.

## Form

Standard Settings content pane. Same layout patterns as other panes.

## Layout

Pane title: "Diagnostics"

Sections in order:
1. Logs
2. On-screen overlay
3. Reports
4. Reset

## Sections

### Logs

Card with four rows.

**Row 1: Log level**
- Popup, default "Warning"
- Options: Error, Warning, Info, Debug, Trace
- Implementation: passes to OSLog / `Logger` API

**Row 2: Keep logs for**
- Popup, default "30 days"
- Options: 7 days, 30 days, 90 days, Forever
- Sublabel: "Older logs are deleted automatically"
- Background task runs daily to prune old logs

**Row 3: Open logs in Finder**
- Title row + button
- Sublabel: "~/Library/Logs/Waraq"
- Button label: "Open" with leading `folder.fill` icon
- Action: `NSWorkspace.shared.open(logsURL)`

**Row 4: Export diagnostic bundle**
- Title row + button
- Sublabel: "Logs, settings, and system info as a zip for bug reports"
- Button label: "Export"
- Action: assembles zip with:
  - Last 7 days of logs
  - `UserDefaults` dump (with secrets redacted)
  - System info (chip, RAM, macOS version, display configurations)
  - Crash report references
  - Saves to user-selected location via NSSavePanel

### On-screen overlay

Card with one row, expandable when toggle is ON.

**Row 1: Show performance overlay**
- Toggle, default OFF
- Sublabel: "FPS, CPU, RAM rendered onto the wallpaper"

Sub-controls (revealed when ON):
- **Position** popup
  - Options: Top left, Top right, Bottom left, Bottom right, Center
  - Default Top right
- **Opacity** slider
  - Range 10 to 100 percent, default 70
  - Label "Opacity" + "{N}%" right-aligned weight 500

Overlay implementation:
- Drawn directly into the wallpaper render pipeline (not a separate
  window)
- Sits on top of the wallpaper, below user apps
- 11 pt monospace font
- Format:
  ```
  FPS: 60 / 60
  CPU: 1.8%
  RAM: 62 MB
  Decoder: HW
  ```
- Background: black @ 0.45, 8 pt corner radius, 8 pt padding

### Reports

Card with two rows.

**Row 1: Send crash reports**
- Toggle, default ON
- Sublabel: "Anonymous. Helps fix the next crash before it hits you"
- Implementation: uses Sparkle's crash reporting or direct sentry-like
  endpoint (v1 may use just system crash logs without external upload)

**Row 2: Share anonymous usage data**
- Toggle, default OFF
- Sublabel: "Which features are used, never which wallpapers or
  content"
- Implementation: if ON, pings a simple analytics endpoint with
  feature usage counts daily
- Data shared: feature uses (e.g., "schedule_enabled", "we_import_run")
  with no personal info, no wallpaper names, no display names

### Reset

Card with three rows.

**Row 1: Re-run hardware setup**
- Title + button (not destructive)
- Sublabel: "Reopens the preset picker for your current Mac"
- Button: "Re-run"
- Action: opens onboarding window at step 2 (hardware preset, see
  onboarding.md). Does not lose any user state.

**Row 2: Reset all settings** (destructive)
- Title in `systemRed` style
- Sublabel: "Restore defaults, keep wallpaper library and profiles"
- Button: "Reset" in destructive style
- Confirmation alert:
  - "Reset Waraq settings to defaults?"
  - Body: "Your wallpaper library and display profiles will be kept."
  - Cancel, Reset (destructive)
- Action on confirm: clear `UserDefaults`, re-run full onboarding

**Row 3: Erase everything** (destructive, nuclear)
- Title in `systemRed` style
- Sublabel: "Settings, profiles, library, cache. Same as a fresh
  install"
- Button: "Erase..." in destructive style
- Confirmation alert:
  - Title: "Erase all Waraq data?"
  - Body: "This deletes your wallpaper library, display profiles,
    settings, and cache. This cannot be undone."
  - Cancel, Erase (destructive)
- Action on confirm:
  - Clear `UserDefaults`
  - Delete `~/Library/Application Support/Waraq/`
  - Delete `~/Library/Caches/com.bahamut.waraq/`
  - Restart app and trigger fresh onboarding

## Behaviors

### Log level switch

Effective immediately. New log calls use the new level. Already-
written log entries are unchanged.

### Overlay live preview

When the overlay toggle is ON, overlay appears on all displays
immediately. When OFF, it disappears. Changing position or opacity
updates within ~100ms.

### Crash report consent

First time Waraq encounters a crash with reports OFF, show a
one-time prompt asking the user if they want to opt in. Respect
their answer.

### Anonymous usage data details

Show a "Learn more" link below the Row 2 toggle that opens a sheet
explaining exactly what is and is not collected. Build trust through
transparency.

## Implementation notes

- Use OSLog / `Logger` API for all logging
- Log files in `~/Library/Logs/Waraq/waraq.{date}.log`
- Diagnostic bundle export is a zip created with `NSFileCoordinator`
  + `Process` running zip CLI
- Performance overlay is rendered as a `CATextLayer` overlay on the
  wallpaper window's `CALayer`
- Reset actions use `RunLoop` to schedule the destructive operations
  after the user closes Settings (avoid crashing the active session)

## Out of scope

- Network bandwidth diagnostics (no cloud features yet)
- Remote logging / log streaming (v2)
- A/B testing infrastructure (v2)

## Changelog
- v1 (2026-05-26): Initial lock.
