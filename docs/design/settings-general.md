# Settings: General Pane Spec

Status: locked v1 (2026-05-26)
Phase: 2
Implementer: Claude Code (SwiftUI)

## Intent

The General pane is the landing pane when Settings opens. It holds
broad app-level preferences: startup, behavior, updates, appearance.

## Form

Standard Settings content pane (see settings-shell.md). Scrollable
vertical list of section cards.

## Layout (basic mode)

Pane title: "General"

Sections in order:
1. Startup
2. Behavior
3. Updates
4. Appearance

## Sections

### Startup

Card with two rows.

**Row 1: Launch Waraq at login**
- Toggle, default ON
- Sublabel: "Starts in the background, no Dock icon"
- Implementation: `LaunchAtLogin` package (per PLAN.md section 8)

**Row 2: Show in menu bar**
- Toggle, default ON
- Sublabel: "Disable to hide the status icon"
- Implementation: `NSStatusItem` show/hide

### Behavior

Card with three rows (basic), five rows (advanced).

**Row 1: Pause when screen is locked**
- Toggle, default ON
- No sublabel

**Row 2: Resume on wake**
- Toggle, default OFF
- No sublabel

**Row 3: Show notification when wallpaper changes**
- Toggle, default OFF
- No sublabel
- Sends user notification via `UNUserNotificationCenter`

**Row 4 (advanced only): Pause when Focus mode is active**
- Toggle, default ON
- Observe `NSWorkspace.shared.notificationCenter` for focus changes

**Row 5 (advanced only): Pause when sharing the screen**
- Toggle, default ON
- Observe `CGScreenIsCaptured()` or screen capture notifications

### Updates

Card with two rows (basic), four rows (advanced).

**Row 1: Update channel**
- Popup, default "Stable"
- Options:
  - Basic mode: Stable, Beta
  - Advanced mode: Stable, Beta, Nightly
- Implementation: Sparkle 2 feed URL switches based on selection

**Row 2 (advanced only): Check frequency**
- Popup, default "Daily"
- Options: Hourly, Daily, Weekly, On launch only, Never

**Row 3 (advanced only): Auto-install minor updates**
- Toggle, default OFF
- Sublabel: "Patches install silently, you are notified after"

**Row 4: Check for updates**
- Two-line text + button
- Text: "Waraq {version}, up to date" or "Update available: {version}"
- Sublabel: "Last checked {time ago}"
- Button: "Check now" (default style)

### Appearance

Card with one row (basic), two rows (advanced).

**Row 1: App appearance**
- Popup, default "Match system"
- Options: Match system, Light, Dark
- Sublabel: "Wallpaper rendering is unaffected"

**Row 2 (advanced only): UI density**
- Popup, default "Comfortable"
- Options: Compact, Comfortable, Spacious
- Affects internal padding of section card rows globally

## Behaviors

### Mode-dependent visibility

When the global Advanced toggle is OFF, hide all advanced-only rows
without animation. When ON, reveal them.

### Settings reset

The Reset button lives in the Diagnostics pane, not General. See
settings-diagnostics.md. Reset triggers the full onboarding flow
again, see onboarding.md.

### Update channel switch

Switching from Stable to Beta or Nightly does NOT immediately
download a beta build. The next scheduled check uses the new feed.
Show a brief toast notification: "Update channel: {new channel}".

## Implementation notes

- Wrap all rows in SwiftUI `Form` with `.formStyle(.grouped)` (or
  `.formStyle(.columns)` if column layout fits better)
- Use `@AppStorage` for all toggle/popup state
- Update channel switch must invalidate Sparkle's cached feed
- Match the row layout pattern from settings-shell.md exactly:
  label + sublabel on the left, control trailing right

## Out of scope

- Reset functionality (see settings-diagnostics.md)
- Onboarding flow (see onboarding.md)

## Changelog
- v1 (2026-05-26): Initial lock.
