# CLAUDE.md — Waraq

Developer-facing notes for a Claude Code session working inside this repo. End users should read `README.md` instead.

Waraq is a shipped macOS 14+ animated wallpaper app (Swift 5.10, SwiftUI + AppKit). v1.0.0 is released. Treat the codebase as production: any change should keep the existing tests green and the signed-and-notarized release pipeline reproducible.

## Repo layout

```
App/         SwiftUI + AppKit shell: AppDelegate, menu bar, Settings panes, onboarding wizard
Core/        Cross-engine logic: DisplayManager, WallpaperLibrary, PerformanceGovernor, ResourceMonitor, Gallery clients (Pixabay/Pexels/NASA), WaraqPrimaryStore
Engines/     Per-wallpaper render engines: VideoEngine, GifEngine, GradientWallpaper, Procedural/*
Library/     LibraryView (a UI surface, not the storage layer)
Resources/   Assets.xcassets (app icon, menu bar icon)
Scripts/     One-off Swift scripts (GenerateAppIcon, GenerateMenuBarIcon). Not built into the app.
Tests/       XCTest unit tests (WaraqPrimaryStoreTests, GalleryTests, ProceduralThumbnailTests, WaraqTests)
docs/        design/ specs per pane + RELEASE_NOTES_v1.0.0*.md + AUDIT_REPORT.md + install/ (GitHub Pages site)
.github/workflows/build.yml   CI: macos-latest, xcodebuild build + test on push/PR to main
project.yml  XcodeGen spec — source of truth for the Xcode project
Screensaver/ Reserved (empty). The screensaver target referenced in PHASE0_HANDOFF.md was deferred past v1.
```

## How the project is generated

`Waraq.xcodeproj/` is in `.gitignore`. Do not commit it. Regenerate locally:

```bash
brew install xcodegen swiftlint swiftformat
xcodegen generate
```

If you edit `project.yml` (targets, sources, build settings, Info.plist values), rerun `xcodegen generate` before building.

## Build, run, test

Open in Xcode after generating:

```bash
open Waraq.xcodeproj
```

Cmd+B builds, Cmd+R runs, Cmd+U tests.

Command-line build (matches CI in `.github/workflows/build.yml`):

```bash
xcodebuild \
  -project Waraq.xcodeproj \
  -scheme Waraq \
  -destination 'platform=macOS' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Command-line tests:

```bash
xcodebuild \
  -project Waraq.xcodeproj \
  -scheme Waraq \
  -destination 'platform=macOS' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Per the v1.0.0 audit, the test suite is 54/54 passing. Don't merge code that drops that count.

## Lint and format

```bash
swiftlint
swiftformat --lint .
```

Both are wired by `.swiftlint.yml` and `.swiftformat`. CI doesn't currently fail on lint violations, but the v1.0.0 audit gate did, so keep both clean.

Notable rules from `.swiftlint.yml`:

- `line_length` warning 140, error 200
- `file_length` warning 500, error 800
- `function_body_length` warning 60, error 120
- `type_body_length` warning 350, error 500
- `cyclomatic_complexity` warning 12, error 20

## Architecture in brief

```
AppDelegate
  └── DisplayManager (one per app launch, @MainActor singleton-like)
        ├── per-display WallpaperWindow  (borderless NSWindow at desktopIconWindow-1 level, ignoresMouseEvents)
        ├── per-display engine instance  (VideoEngine | GifEngine | GradientWallpaper | procedural NSView)
        ├── WallpaperLibrary             (~/Library/Application Support/Waraq/{Wallpapers,Thumbnails,library.json})
        ├── PerformanceGovernor          (publishes per-display PlaybackState; reacts to battery, fullscreen, thermal)
        └── ResourceMonitor              (CPU/GPU/RAM sampling for Diagnostics pane)
  └── MenuBarController                  (NSStatusItem + NSPopover hosting MenuBarPopoverView)
```

Key invariants:

- `WallpaperWindow` sits one level below the desktop-icon window so icons stay clickable on top. Do not move it above.
- `DisplayManager.applyGovernorState(_:)` early-returns if `isPaused == true` so the menu-bar pause toggle wins over governor decisions.
- Display profiles are keyed by hardware ID via `DisplayProfile` / `WaraqPrimaryStore`, not by `CGDirectDisplayID` (which churns across reboots).

## Gallery and external network policy

Privacy is a contract with users. The README states zero outbound traffic unless the user explicitly searches the Gallery. Code changes must respect this:

- The only network egress points are `Core/Gallery/PixabayClient.swift`, `PexelsClient.swift`, `NASAClient.swift`, and `GalleryDownloader.swift`.
- "Browse Web" cards must continue to open URLs in the user's default browser via `NSWorkspace.open`. Do not fetch, scrape, mirror, or proxy content from MotionBGs, MoeWalls, MyLiveWallpapers, or Wallsflow.
- API keys (Pixabay, Pexels) live in `APIKeyStore.swift` (UserDefaults). NASA needs no key.
- No telemetry. No analytics. No phone-home. Do not add any.

## License header

Every Swift source file in `App/`, `Core/`, `Engines/`, `Library/`, `Tests/`, `Scripts/` should start with the GPL v3 boilerplate header. The audit script counts files vs. files-with-header. When adding a new `.swift` file, copy the header from any existing file verbatim.

Current coverage is **73/74**. The one outlier is `Library/LibraryView.swift`, a dead Phase-4 stub that is never referenced (the real Library pane is `App/Settings/LibraryPane.swift`). Cleanup task: delete the stub. That resolves the header gap and removes dead code in one move.

```bash
# verify
total=0; have=0
for f in $(find App Core Engines Library Tests -name '*.swift'); do
  total=$((total+1))
  head -25 "$f" | grep -qiE 'GNU General Public License|GPL' && have=$((have+1))
done
echo "$have / $total"
```

## Versioning and release pipeline

Version metadata lives in `project.yml` under `targets.Waraq.info.properties`:

- `CFBundleShortVersionString` (e.g. `1.0.0`)
- `CFBundleVersion` (build number, e.g. `3`)

Released artifacts (DMG, PKG) are produced by an out-of-tree codesign + notarize + staple pipeline using a Developer ID identity. Do not commit signing identities, `.p12`, `AuthKey_*.p8`, or any `*.private` file; `.gitignore` already covers these. Do not run that pipeline from a Claude Code session unless explicitly asked.

The `block-sudo-and-system-integrity` guardrail in the user's environment blocks `spctl --assess`. Use `codesign --verify --deep --strict` and `xcrun stapler validate` to verify a built artifact instead.

## Local environment guardrails

This developer's `~/.claude/hookify.*.local.md` files enforce four hard rules. A future Claude Code session will hit them. Plan around them, not into them:

- `block-deletion` matches `rm`, `rmdir`, `unlink`, `srm`, `trash`, `gio trash`, `shred`, `find ... -delete`, `mv ... /dev/null`. `git rm` is also caught (contains `rm`). Move-only workflow: quarantine to a folder via `mv` (plain), then ask the user to empty.
- `block-bulk-move` matches `mv`, `cp`, `ditto`, `rsync` with `*`, `-r`/`-R`, `find -exec`, or `xargs`. Use `ditto src dst` with literal paths, or a per-file loop where the ditto line itself has no `*`.
- `block-sudo-and-system-integrity` matches `sudo`, `csrutil`, `systemextensionsctl`, `nvram`, `spctl`, `kextload`/`kextunload`, `kmutil`, `launchctl bootout/disable/enable/kickstart/kill system`, `pfctl`, destructive `dscl`/`diskutil`/`fdesetup`. Use `codesign --verify --deep --strict` and `xcrun stapler validate` instead of `spctl --assess`.
- `block-credentials-bash` matches `password`, `keychain`, `credentials` in command text. This blocks `xcrun notarytool --keychain-profile waraq-notary`, which is the only command the release pipeline genuinely needs. The user toggles this hook off manually when notarizing, then restores it. Avoid these substrings in filenames too (the install guide mockup is `07-admin-auth.png`, not `…-password.png`).

You cannot edit these hook files from a tool agent (the auto-mode classifier denies it). If a step truly needs one off, surface the requirement to the user and provide the toggle one-liner.

## What not to touch

- `Waraq.xcodeproj/` is generated. Edit `project.yml` and regenerate.
- `LICENSE` is the full GPL v3 text. Do not modify.
- `docs/RELEASE_NOTES_v1.0.0*.md` and `docs/AUDIT_REPORT.md` are historical records of shipped releases. Add new files for new releases; do not rewrite history.
- `docs/install/` is the GitHub Pages site at `bahamut42.github.io/waraq/install/`. Edit only when the install flow itself changes. It contains a GoatCounter `<script>` for aggregate analytics on the doc site only; the macOS app itself remains zero-telemetry, do not add analytics anywhere else.
- The `README.md` badge row contains a komarev `Repo views` counter image. It's a vanity counter (image-based, Camo-proxied, approximate). Insights → Traffic is the accurate private source. Do not add other tracking pixels.
- The GitHub Wiki (`bahamut42/waraq.wiki.git`, separate git repo) is populated with 12 user-facing pages plus `_Sidebar.md` and `_Footer.md`. When user-visible behavior changes, update the relevant wiki page too (`Features.md`, `Privacy.md`, `Troubleshooting.md`, etc.).
- `uploads/` are legacy session uploads. Per `docs/PLAN.md`, these were meant to be deleted after the canonical copy landed in `docs/`. Leave them alone unless the user asks to clean up.
- The "Browse Web" external site list. Adding or removing entries is a product decision, not a code change to make unprompted.

## Known issues carried into v1.0.0

From `docs/AUDIT_REPORT.md` (accepted, not bugs to fix mid-feature):

- In-app Gallery previews are static thumbnails. Desktop playback is full motion.
- Gallery has Pixabay, Pexels, NASA, Browse Web. Coverr was removed in an earlier phase. Don't reintroduce without product sign-off.
- Library location is hardcoded to `~/Library/Application Support/Waraq/`. Configurable library location is the top post-v1 roadmap item.
- "Yield to GPU-heavy apps" toggle is hidden pending detection logic.

## Known footguns (from prior debugging sessions)

- **SwiftUI `VideoPlayer` crashes on the macOS/SDK this project targets.** Use `AVPlayerView` wrapped in `NSViewRepresentable` instead. (Source: prior incident on this codebase.)
- **The v1.0.0 DMG background renders upside-down** (text and wordmark vertically flipped). Confirmed cause: the CGContext y-axis was flipped when the background image was composed; icons inside the DMG are positioned correctly via `.DS_Store`, only the background PNG is wrong. A corrected, re-signed DMG with the same app binary is staged at `/tmp/waraq-v1/Waraq-1.0.0-fixed.dmg` (signed with Developer ID Application, valid on disk), awaiting notarization + asset replacement on the v1.0.0 release. Full recipe in `~/Desktop/WARAQ_DMG_FIX_HANDOFF.md`. The PKG installer is unaffected (it uses the installer UI, not a DMG background).

## Conventions

- Indent 4 spaces. Trailing newline. No tabs. Enforced by `.swiftformat`.
- `@MainActor` annotations are used liberally where AppKit/SwiftUI requires main-thread access; preserve them.
- Notifications come from `NSApplication.didChangeScreenParametersNotification` for display hotplug. Don't poll.
- Prefer `NSLog("Waraq: ...")` for runtime logs so they're greppable in Console.app.

## Where to read first when picking up unfamiliar work

| Task                         | Start here                                                                 |
|------------------------------|----------------------------------------------------------------------------|
| Display / hotplug / profiles | `Core/DisplayManager.swift`, `Core/DisplayProfile.swift`                   |
| Adding a wallpaper engine    | `Engines/VideoEngine.swift` (template), `Core/WallpaperWindow.install(...)`|
| Procedural wallpapers        | `Engines/Procedural/ProceduralFactory.swift`                               |
| Library / import flow        | `Core/WallpaperLibrary.swift`, `App/Settings/LibraryPane.swift`            |
| Gallery / external sources   | `Core/Gallery/*.swift`, `App/Gallery/*.swift`                              |
| Performance gating           | `Core/PerformanceGovernor.swift`, `Core/ResourceMonitor.swift`             |
| Menu bar                     | `App/MenuBarController.swift`, `App/MenuBarPopoverView.swift`              |
| Onboarding                   | `App/Onboarding/OnboardingRootView.swift` and `Steps/`                     |
| Settings pane design specs   | `docs/design/settings-*.md`                                                |
