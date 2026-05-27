# Waraq v1 Pre-Release Audit Report

Generated: 2026-05-27
Audited commit: 3778aba
Build configuration: Release

## Automated test suite

Test results: **54 passed, 0 failed** (`clean test`, Debug config).

## Release build

Result: **SUCCESS** (`clean build`, Release config).
Built bundle: `~/Applications/Waraq.app` — **8.1 MB** (well under the
100 MB target).
Linked libraries: **no analytics / telemetry / crash-reporting
libraries** (`otool -L` clean — no Sentry/Firebase/Crashlytics/etc.).

Info.plist key values verified:
- CFBundleIdentifier: `com.bahamut.waraq` ✓
- LSMinimumSystemVersion: `14.0` ✓
- LSUIElement: `true` ✓
- NSHumanReadableCopyright: `Copyright (C) 2026 Omar A. Othman. Licensed under GPL v3.` ✓

## Smoke launch

App launched from `~/Applications/Waraq.app`: **PASS** (process running).
Settings window opened via Cmd+,: **PASS** (title "Waraq Settings").

Pane navigation (via `defaults selectedPane` + Settings reopen, Advanced
mode on so Diagnostics is reachable):

| Pane | Result |
|------|--------|
| general | PASS |
| displays | PASS |
| library | PASS |
| gallery | PASS |
| performance | PASS |
| wallpapers | PASS |
| diagnostics | PASS |
| about | PASS |

App survived navigating all 8 panes (no crash).

## File inventory

Swift source files (App/Core/Tests/Scripts/Engines): **75**
Files with GPL v3 header: **65**
Missing headers: **10** — all under `Engines/` (see finding below).

App icon PNGs in `Resources/Assets.xcassets/AppIcon.appiconset/`: 11.
Procedural wallpaper definitions in `ProceduralFactory`: 5 (+ the
built-in animated gradient = 6 built-ins).

Critical files verified present:
- `LICENSE` (canonical GPL v3, 35,149 bytes)
- `README.md` (rewritten Phase 9.12)
- `project.yml`
- `docs/hero.svg` (animated SVG banner)
- `docs/hero-desktop.gif` (live wallpaper demo, ~2.3 MB)
- `docs/screenshots/` (8 captured screenshots)
- `App/WaraqApp.swift`, `Core/DisplayManager.swift`,
  `Core/WallpaperLibrary.swift`

## Known limitations carried into v1

These were accepted scope decisions, not bugs:

- In-app Gallery previews are static thumbnails, not motion. SwiftUI
  `VideoPlayer` crashed during the 9.8a hotfix cycle; motion preview
  deferred to post-v1 (use the desktop engine's AVPlayerLayer).
- Gallery has 3 API sources (Pixabay, Pexels, NASA) plus Browse Web.
  Coverr was removed in 9.10 (API-key approval stalled indefinitely).
- WallpaperLibrary location is hard-coded to
  `~/Library/Application Support/Waraq/`. Configurable location
  (external-drive support via security-scoped bookmarks) is roadmapped
  for post-v1.
- "Yield to GPU-heavy apps" toggle hidden in PerformancePane pending
  detection implementation (Phase 9.9).

## Findings requiring action before release

1. **GPL header missing on `Engines/` (10 files).** Phase 9.12 applied
   the GPL v3 header to `App/`, `Core/`, `Tests/`, and `Scripts/` but
   did not include `Engines/`. The following lack the header:
   `Engines/ImageEngine.swift`, `Engines/GifEngine.swift`,
   `Engines/VideoEngine.swift`, `Engines/GradientWallpaper.swift`,
   `Engines/Procedural/{AuroraView, SynthwaveView, MatrixRainView,
   StarfieldView, NeuralNetworkView, ProceduralFactory}.swift`.
   Not a crash/build/test issue (the build is green), but for a clean
   GPL v3 release the relicense should be complete. **Recommended: a
   quick header pass on `Engines/` (mirroring 9.12) before Phase 10**,
   confirming `.swiftformat`'s `--header ignore` preserves them, then
   rebuild/retest. This audit did NOT modify code (audit-only phase).

No other automated findings. Tests, build, smoke launch, pane
navigation, bundle metadata, and telemetry checks all passed.

## Sign-off

This automated audit confirms the build is technically sound (green
tests, clean Release build, stable smoke launch). The one action item
above (Engines GPL headers) should be resolved before cutting the
public GPL v3 release.

Manual verification of features and UX flows is tracked in
`docs/RELEASE_CHECKLIST.md` and the "v1.0.0 Release Verification"
GitHub Issue.

Phase 10 should not proceed until the Engines header gap is closed and
the manual checklist items are walked through and confirmed.
