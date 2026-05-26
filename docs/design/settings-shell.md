# Settings Window Shell Spec

Status: locked v1 (2026-05-26)
Phase: 2
Implementer: Claude Code (SwiftUI)

## Intent

The Settings window is the configuration hub for Waraq. It uses the
modern macOS 14+ sidebar-navigation pattern (System Settings style),
with a global Basic/Advanced toggle that changes how much depth is
exposed across every pane.

## Form

Native macOS Settings window. Resizable, two-pane layout.

- Default size: 720 × 560 pt
- Min size: 640 × 480 pt
- No max size
- Resizable
- Standard window chrome with traffic lights
- Title: "Settings" (centered, native title bar)
- Style: `NSWindow.Style` with toolbar style `.unified`

## Layout

Two columns side by side, full window height:

```
+-----------+-------------------------------+
|           |                               |
|  Sidebar  |        Content pane           |
|  190 pt   |        flexible width         |
|           |                               |
|           |                               |
+-----------+-------------------------------+
| Advanced  |                               |
| toggle    |                               |
+-----------+-------------------------------+
```

Sidebar: fixed 190 pt wide.
Content: takes remaining width.

## Components

### Sidebar

Background: same `.regularMaterial` as the window, no extra material.
Right border: 0.5 pt `separatorColor`.

#### Search field (top)

- Position: 10 pt top padding, 12 pt horizontal padding
- Height: 26 pt
- Background: `Color.primary.opacity(0.06)`
- Border: 0.5 pt `Color.primary.opacity(0.08)`
- Radius: 6 pt
- Leading icon: `magnifyingglass` at 13 pt, `tertiaryLabelColor`
- Placeholder: "Search" at 12 pt, `tertiaryLabelColor`
- Filters sidebar items by label AND searches into setting names
  across all panes (returns inline result list with deep links)

#### Sidebar nav items

Stack starts 12 pt below the search field. Each item:
- Height: 28 pt
- Horizontal padding: 10 pt
- Internal gap (icon to label): 9 pt
- Radius: 6 pt
- Icon: 15 pt SF Symbol, `secondaryLabelColor` (inactive),
  `systemBlue` (active)
- Label: 13 pt, weight 400 (inactive) or weight 500 (active),
  `labelColor`
- Background: transparent (inactive), `systemBlue` at 18% (active),
  `Color.primary.opacity(0.04)` (hover)

Items in order (basic mode):
1. General (`gearshape`)
2. Displays (`display`)
3. Library (`photo.on.rectangle`)
4. Performance (`speedometer`)
5. Wallpapers (`square.stack.3d.up`)
6. About (`info.circle`)

Item added in advanced mode, between Wallpapers and About:
- Diagnostics (`stethoscope`) with trailing "ADV" pill at 9 pt,
  weight 500, `systemBlue` text on `systemBlue` @ 18% bg, 3 pt
  radius, uppercase

Selection logic:
- Single selection
- Default on first open: General
- Persisted across app launches via UserDefaults
- Keyboard arrows move selection up/down

### Advanced toggle (sidebar footer)

Fixed at the bottom of the sidebar, separated by a top border.

- Background: `systemBlue` @ 6%
- Top border: 0.5 pt `separatorColor`
- Padding: 10 pt vertical, 12 pt horizontal
- Layout: leading icon + label/sublabel, trailing switch

Components:
- Icon: `wrench.and.screwdriver` at 14 pt, `systemBlue`
- Label: "Advanced" / 12 pt / weight 500 / `labelColor`
- Sublabel: "Full depth controls" / 10 pt / `secondaryLabelColor`
- Switch: 30 × 18 pt (small variant of standard toggle)

When toggled ON:
- Diagnostics appears in sidebar
- Every pane shows its advanced-only sections and rows
- Pane titles get an "ADVANCED" badge top-right
- Update channel dropdown reveals Nightly option
- All advanced state persists per launch

When toggled OFF:
- Diagnostics disappears from sidebar (if user was on it, redirect to
  General)
- All panes hide advanced-only sections without animation
- Advanced-only settings revert to safe defaults (no destructive
  reset, just hidden)

### Content pane

Background: same window material.
Padding: 24 pt vertical, 28 pt horizontal.
Scrollable when content exceeds height.

Standard structure for every pane:
1. Pane title row (22 pt / weight 500 + optional Advanced pill)
2. Optional live status banner (see Performance, Wallpapers)
3. Section header (uppercase small caps label + optional right-side
   count or status)
4. Section card (grouped rounded list)
5. Repeat sections as needed

#### Pane title row

- Title: 22 pt / weight 500 / `labelColor` / letter-spacing -0.2 pt
- Right side: "ADVANCED" pill (10 pt / weight 500 / `systemBlue` /
  4 pt radius / 3 pt vertical / 8 pt horizontal / `systemBlue` @ 15%
  bg / uppercase / 0.4 pt letter-spacing) shown only when in
  Advanced mode

#### Section header

- Label: 11 pt / weight 500 / `secondaryLabelColor` / uppercase / 0.5
  pt letter-spacing
- Top margin: 22 pt (8 pt at top of pane)
- Bottom margin: 8 pt
- Horizontal padding: 2 pt
- Right side: optional 11 pt `secondaryLabelColor` / regular weight
  count or status (e.g., "2 saved", "Active" with green dot)

#### Section card

- Background: `Color.primary.opacity(0.04)`
- Border: 0.5 pt `separatorColor`
- Radius: 8 pt
- Internal row divider: 0.5 pt `separatorColor`, no horizontal inset
- Row padding: 11 pt vertical, 14 pt horizontal
- Row layout: label + helper text on left, control on right (default)

## Behaviors

### Window state persistence

- Position, size, selected pane, advanced toggle all persisted via
  `NSWindow.frameAutosaveName` and `UserDefaults`
- On first launch, window centers on the active display

### Live appearance switch

- Mode toggle on the sidebar: instant, no animation. Sidebar items
  (Diagnostics) appear/disappear instantly. Content of the active
  pane updates without re-scrolling.
- System appearance change (light/dark): smooth transition handled
  by NSColor semantic tokens.

### Search behavior

- Filters sidebar nav items if matched in their label
- Filters into setting names across all panes (returns deep-link
  rows below the matching sidebar items)
- Clears with Escape or the X button
- Cmd+F focuses search

### Keyboard

- Cmd+W: close window
- Cmd+, : open settings (from any window)
- Cmd+Up/Down: navigate sidebar items
- Cmd+F: focus search
- Tab: navigate interactive elements within content pane
- Escape: clear search, then close window if search is empty

## Accessibility

- Sidebar items are accessible buttons with labels
- Advanced toggle has VoiceOver label "Advanced settings,
  {state}, toggle"
- Search is a standard accessible search field
- Content panes use accessible section headers
- All toggles, popups, sliders use native controls (accessible by
  default)
- Window respects Reduce Transparency (solid bg fallback)
- Window respects Increase Contrast

## Implementation notes

- Use SwiftUI's `NavigationSplitView` (macOS 13+) for sidebar +
  content split
- `Form` style `.grouped` matches the section card pattern out of
  the box
- For the Advanced toggle in the sidebar footer, override
  NavigationSplitView's default by adding a `safeAreaInset` at
  bottom of sidebar
- Persist advanced state with `@AppStorage("isAdvancedMode")`
- Build pane visibility off `isAdvancedMode` with `if` blocks, NOT
  `.hidden()` modifier (avoids layout flicker)
- Each pane is its own SwiftUI View, kept in `App/Settings/` directory
- Search uses `NSSearchField` wrapped with `NSViewRepresentable` for
  full Cmd+F integration

## Out of scope

- Individual pane contents (see settings-general.md,
  settings-displays.md, etc.)
- Display detail sheet (see settings-displays.md)
- WE import sheet (see settings-library.md)

## Changelog
- v1 (2026-05-26): Initial lock.
