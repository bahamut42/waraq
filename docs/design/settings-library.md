# Settings: Library Pane Spec

Status: locked v1 (2026-05-26)
Phase: 4 (library management and import flow)
Implementer: Claude Code (SwiftUI)

## Intent

The Library pane is the wallpaper collection manager. It shows
imported wallpapers as a thumbnail grid, lets the user search, sort,
filter, and import. In advanced mode, it also exposes library
location management and storage controls.

This is where users spend the most time after the app is set up.

## Form

Standard Settings content pane.

## Layout

Pane title: "Library"

Sections in order:
1. Toolbar (always)
2. Counter line (always)
3. Wallpaper grid (always)
4. Library locations (advanced only)
5. Storage (advanced only)

## Sections

### Toolbar

Single row, 14 pt bottom margin. Layout:
`Search field (flex) | Type filter | Sort button | Import button`

**Search field**
- Flex grow
- Same style as sidebar search (see settings-shell.md)
- Placeholder: "Search wallpapers"

**Type filter** (segmented control)
- Pill style: 6 pt radius, 2 pt internal padding, 4 px gap between
  segments
- Background: `Color.primary.opacity(0.06)`
- Each segment: 11 pt label, 4 pt vertical, 10 pt horizontal padding
- Active segment: `Color.primary.opacity(0.10)` background, weight
  500 label
- Inactive: weight 400, `secondaryLabelColor`
- Segments: All, Video, Web, Image (default: All)

**Sort button** (default style)
- Leading: `arrow.up.arrow.down` at 13 pt
- Label: "Sort" 12 pt
- Trailing: `chevron.down` at 11 pt
- Opens NSMenu with: Recently added, Name, Type, Duration, Size

**Import button** (primary style)
- Leading: `plus` at 13 pt
- Label: "Import" 12 pt weight 500
- Trailing: `chevron.down` at 11 pt
- Opens NSMenu with:
  - From files... (NSOpenPanel)
  - From folder... (NSOpenPanel, directory mode)
  - From Wallpaper Engine... (opens WE import sheet, below)
  - From URL... (modal with URL field)

### Counter line

11 pt `secondaryLabelColor`, 10 pt bottom margin, 2 pt horizontal
padding.
Format: "{N} wallpapers · {total size}"
Updates live.

### Wallpaper grid

3 columns by default (auto-adjusts based on window width:
- ≤640 width: 3 columns
- 641-820: 4 columns
- 821-1000: 5 columns
- 1001+: 6 columns
).
10 pt gap between cards.

Each card:
- Aspect ratio: 16:10 for the thumbnail
- Background: `Color.primary.opacity(0.04)`
- Border: 0.5 pt `separatorColor`
- Radius: 8 pt
- Layout: thumbnail (full width) + footer

Thumbnail:
- Wallpaper accent gradient (read from manifest)
- Top-left pill: type indicator
  - Background: black @ 0.55
  - Padding: 2 pt vertical, 6 pt horizontal
  - Radius: 8 pt
  - Leading icon (9 pt): `play.fill` (Video), `chevron.left.slash.chevron.right`
    (Web), `photo` (Image)
  - Label: 9 pt white "Video" / "Web" / "Image"
- Top-right pill: status (only when relevant)
  - "Active" in `systemBlue` 9 pt weight 500 on `systemBlue` @ full
    bg
  - "WE" in `systemOrange` style on `systemOrange` @ full bg (for
    Wallpaper Engine imports)

Footer (7 pt vertical / 9 pt horizontal padding):
- Title: 12 pt weight 500 `labelColor`, single line, truncate
- Meta: 10 pt `secondaryLabelColor`, format "{duration} · {resolution}"
  or "Still · {resolution}" or "Live · {language}" for web

Selection state:
- Border becomes 2 pt `systemBlue` instead of 0.5 pt `separatorColor`
- Subtle scale up: 1.02 (animated 150ms)

Click action: opens wallpaper detail sheet (configures per-wallpaper
defaults). See "Wallpaper detail sheet" below.

Right-click action: shows context menu with:
- Set as current wallpaper
- Add to favorites
- Show in Finder
- Export as .murmur bundle
- Delete... (red)

### Library locations (advanced only)

Header: "LIBRARY LOCATIONS"

Card with one row per location.

Each row:
- Padding: 10 pt vertical, 14 pt horizontal
- Layout: leading icon + text block + trailing count

Components:
- Leading: `folder` at 16 pt `secondaryLabelColor`
- Text block:
  - Title: 12 pt `labelColor`
  - Path: 10 pt `secondaryLabelColor`, monospace not required
- Trailing: 10 pt `secondaryLabelColor` "{N} items"

Default first row: "Default library" / `~/Library/Application
Support/Waraq/Wallpapers`. Cannot be removed, can be relocated.

Footer: Apple-style + / - segmented buttons:
- Plus: opens NSOpenPanel (directory selection) to add a watched
  folder
- Minus: removes the selected location (with confirmation if it has
  items; only removes the watch, does not delete files)

### Storage (advanced only)

Header: "STORAGE"

Card with two rows.

**Row 1: Cache size**
- Title: 13 pt
- Sublabel: "Thumbnails and decoded frame cache"
- Right side: 12 pt `secondaryLabelColor` "{size}" + "Clear" button
  (default style)
- Clear removes cache without affecting wallpaper files

**Row 2: Max thumbnail resolution**
- Title: 13 pt
- Popup, default "Match display"
- Options: Match display, 4K, 1080p, 720p, 480p

## Wallpaper Engine import sheet

Triggered by Import > From Wallpaper Engine.

### Step 1: Folder selection

Standard NSOpenPanel:
- Title: "Select your Wallpaper Engine workshop folder"
- Default location attempt:
  `~/Library/Application Support/Steam/steamapps/workshop/content/431960`
- Falls back to `~/Library/Application Support/Steam/` if not found
- User can navigate to any folder

### Step 2: Scan and compatibility breakdown

After folder selection, app scans for `project.json` files (WE's
manifest format). Scan typically takes 1 to 5 seconds.

Modal sheet attached to Settings window.

- Size: 520 pt wide, dynamic height (typical 500 pt)
- Material: `.regularMaterial`
- Border: 0.5 pt white @ 0.14
- Corner radius: 12 pt
- Backdrop: black @ 0.55 covering the Settings window content

#### Header

- Padding: 20/24/12/24 pt
- Leading: WE Steam icon in amber-tinted rounded square
  (32 × 32 pt, 7 pt radius, `systemOrange` @ 18% bg)
- Title: "Import from Wallpaper Engine" / 15 pt weight 500
- Path subtitle: 11 pt `secondaryLabelColor`, truncate middle for
  long paths

#### Scan summary banner

- Padding: 0 24 16 24 pt
- Card style: `Color.primary.opacity(0.04)` bg, 0.5 pt
  `separatorColor` border, 8 pt radius, 12 pt 14 pt padding

Layout: text block on left, three count stats on right.

Text block:
- Line 1: 12 pt `labelColor` "Scanned {N} wallpapers in {duration}"
- Line 2: 11 pt `secondaryLabelColor` "Total size: {size} · Will
  convert to .murmur on import"

Stats (right side, three columns, gap 14 pt each):
- Each column: number 16 pt weight 500 colored, "ok"/"partial"/"no"
  11 pt `secondaryLabelColor` below
- ok: `systemGreen`, partial: `systemOrange`, no: `systemRed`

#### Compatibility tiers

Three cards stacked. Each:
- Padding: 0 24 10 24 pt around each (10 pt between cards)
- Internal padding: 10 pt vertical, 14 pt horizontal
- 8 pt radius, 0.5 pt border in matched semantic color at 0.2 alpha
- Background: matched semantic color at 0.08 alpha

Tier 1: Compatible
- Border / bg: `systemGreen`
- Icon: `checkmark.circle.fill` 18 pt `systemGreen`
- Title: "{N} wallpapers will work fully" / 13 pt weight 500
- Sublabel: "MP4, WebM, and static image formats. No compromises."
- Right side: "Select all" checkbox (default checked)

Tier 2: Partial
- Border / bg: `systemOrange`
- Icon: `exclamationmark.triangle.fill` 18 pt `systemOrange`
- Title: "{N} will work with limitations"
- Sublabel: "Web scenes. Audio reactivity and WE-specific APIs will
  not function."
- Right side: "Include" checkbox (default unchecked)
- Expanded details (always visible, not behind expander):
  - Card top border in matched color at 0.15 alpha
  - Padding: 8 pt vertical, 14 pt horizontal
  - Background: black @ 0.15
  - Text: 11 pt `labelColor` opacity 0.7, line height 1.5
  - Two lines:
    - "What works: visuals, animation loops, HTML and CSS rendering,
      basic interactivity."
    - "What does not: microphone or system audio reactivity, WE
      script APIs, Steam Workshop linkage."
  - Labels "What works:" and "What does not:" weight 500

Tier 3: Not supported
- Border / bg: `systemRed`
- Icon: `xmark.circle.fill` 18 pt `systemRed`
- Title: "{N} cannot be imported"
- Sublabel: "Unity scenes and applications. Format is proprietary to
  Wallpaper Engine."
- Right side: 11 pt `secondaryLabelColor` "Skipped" (no checkbox,
  user cannot include these)
- Expanded details:
  - "These wallpapers use Wallpaper Engine's Unity-based scene format
    or run as standalone applications. Waraq cannot host these
    without shipping Wallpaper Engine's runtime, which is not
    redistributable. They will be ignored."

#### Footer

- Padding: 16/24/16/24 pt
- Top border: 0.5 pt `separatorColor`
- Background: black @ 0.15
- Layout: count text on left, Cancel + Import buttons on right

Count text:
- 12 pt
- "{N} wallpapers will be imported" with N in weight 500 `labelColor`,
  the rest `secondaryLabelColor`
- Suffix " · ~{size} after conversion" in `tertiaryLabelColor`

Buttons:
- Cancel: default style
- Import: primary style, label "Import {N}"
- Both right-aligned, 8 pt gap

### Step 3: Import progress

After clicking Import, show progress modal:
- Same sheet style, smaller (380 × 200 pt)
- Title: "Importing wallpapers"
- Progress bar (indeterminate or % if known)
- Status text: "Converting {current} of {total}: {filename}"
- Cancel button

### Step 4: Done

- Title: "Imported {N} wallpapers"
- Body: "{S} added to your library."
- Done button (primary)

## Wallpaper detail sheet (per-wallpaper)

Triggered by clicking a wallpaper card in the grid.

Modal sheet, 520 pt wide, dynamic height (typical 600 pt).

Sections:
1. Preview hero (full width, 16:10, 8 pt radius)
2. Metadata (name, author, type, duration, file size, source)
3. Playback (volume, mute, fit, loop, fps cap)
4. Tags and favorites
5. Footer (Cancel, Save, Set as wallpaper)

## Implementation notes

- Wallpaper data backed by `WallpaperManifest` model (per PLAN.md
  section 3)
- Library locations watched via `DispatchSource.makeFileSystemObjectSource`
- Cache lives in `~/Library/Caches/com.bahamut.waraq/`
- WE import scanner parses `project.json` files from each subfolder
- Conversion to .murmur: copy MP4/WebM/PNG/JPG into .murmur bundle
  with a translated manifest
- Use SwiftUI `LazyVGrid` for the wallpaper grid (handles 100s of
  items without lag)

## Out of scope

- Wallpaper community library / online browse (v2)
- Tagging system (v1.1)
- Favorites system (v1.1, hooks into Wallpapers pane rotation source)

## Changelog
- v1 (2026-05-26): Initial lock.
