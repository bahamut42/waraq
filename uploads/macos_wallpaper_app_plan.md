# macOS Animated Wallpaper App: Project Plan

## 1. Vision

A native, lightweight macOS app that displays animated content as the desktop background, with an optional matching screensaver. Open source toolchain end to end. Target footprint: under 80 MB RAM at idle, under 3% CPU on a still frame, hardware-decoded video, zero impact when any app goes fullscreen.

### In scope
- Animated desktop wallpaper (video, web, image sequence)
- Multi-monitor support with per-display content
- Companion screensaver bundle (.saver)
- Menu bar control app
- Local wallpaper library (no cloud sync in v1)
- Per-wallpaper config (volume, playback speed, fit mode)

### Out of scope (v1)
- Lock screen wallpaper (Apple does not expose APIs for this; lock screen falls back to a still frame from the active wallpaper)
- Steam Workshop equivalent online store (deferred to v2)
- Unity/3D engine scenes (deferred; Wallpaper Engine's "scene" format is the heaviest part and least used)
- Audio reactivity (deferred to v1.1)
- Windows/Linux ports

### Naming
Pitching three options that fit your brand aesthetic:
- **Waraq** (a flock of crows in motion, ties to your raven identity)
- **Roost** (where the flock gathers, simpler)
- **Nightfall** (atmospheric, dark fantasy lean)

Pick one or propose your own.

---

## 2. Tech Stack (open source / free)

| Layer | Choice | Why |
|---|---|---|
| Language | Swift 5.10+ | Native, fast, zero runtime overhead |
| UI | SwiftUI + AppKit interop | SwiftUI for menu bar/settings, AppKit for the desktop window trick |
| Rendering | Metal via CAMetalLayer | GPU-accelerated, lowest CPU overhead |
| Video | AVFoundation (AVPlayerLayer) | Hardware HEVC/H.264 decode |
| Web scenes | WKWebView | Sandboxed, built in |
| Build | Xcode 16 + Swift Package Manager | Free, standard |
| Source control | Git + GitHub | Free public repos |
| CI/CD | GitHub Actions | Free for public repos |
| Auto-update | Sparkle 2 | The standard for non-MAS macOS apps, MIT license |
| Login item | LaunchAtLogin (Sindre Sorhus) | MIT, battle-tested |
| Code signing | Apple Developer ID | $99/yr, required for notarization |
| Distribution | Direct download + Homebrew Cask | No App Store restrictions |

No Electron. No cross-platform frameworks. No game engines. Lightweight wins by saying no.

---

## 3. Repo Structure

```
waraq/
├── App/                          # Main menu bar app
│   ├── WaraqApp.swift
│   ├── AppDelegate.swift
│   └── MenuBarController.swift
├── Core/                         # Shared engine
│   ├── WallpaperWindow.swift     # NSWindow desktop layer
│   ├── DisplayManager.swift      # Multi-monitor coordination
│   ├── PerformanceGovernor.swift # Fullscreen/battery/occlusion
│   └── WallpaperManifest.swift   # JSON wallpaper format
├── Engines/                      # Content engines
│   ├── VideoEngine.swift         # AVPlayerLayer
│   ├── WebEngine.swift           # WKWebView
│   └── ImageEngine.swift         # Static or sequence
├── Library/                      # Wallpaper picker UI
│   ├── LibraryView.swift
│   ├── WallpaperGridCell.swift
│   └── ImportFlow.swift
├── Screensaver/                  # Separate .saver bundle target
│   └── WaraqSaverView.swift
├── Resources/                    # Default wallpapers, icons
├── Tests/
└── Scripts/                      # Build, sign, notarize scripts
```

---

## 4. Architecture Overview

```
+--------------------------------------------------+
|                Menu Bar App (UI)                 |
|   Settings, Library Picker, Per-Display Config   |
+----------------------+---------------------------+
                       |
                       v
+--------------------------------------------------+
|              DisplayManager (Core)               |
|   Watches NSScreen.screens, creates one          |
|   WallpaperWindow per active display             |
+----------------------+---------------------------+
                       |
        +--------------+--------------+
        v              v              v
  +-----------+  +-----------+  +-----------+
  | Wallpaper |  | Wallpaper |  | Wallpaper |
  |  Window 1 |  |  Window 2 |  |  Window N |
  +-----+-----+  +-----+-----+  +-----+-----+
        |              |              |
        v              v              v
  +-----------+  +-----------+  +-----------+
  |  Engine   |  |  Engine   |  |  Engine   |
  | (Video /  |  | (Video /  |  | (Video /  |
  |  Web /    |  |  Web /    |  |  Web /    |
  |  Image)   |  |  Image)   |  |  Image)   |
  +-----------+  +-----------+  +-----------+
        |              |              |
        +------+-------+------+-------+
               |              |
               v              v
       +----------------+ +------------------+
       | Performance    | | Wallpaper        |
       | Governor       | | Manifest Loader  |
       | (pause/resume) | | (.waraq bundle) |
       +----------------+ +------------------+
```

The Performance Governor is the secret sauce. It listens for:
- `NSWorkspace.activeSpaceDidChangeNotification`
- Fullscreen app detection via `CGWindowListCopyWindowInfo`
- `NSWindow.occlusionState`
- `ProcessInfo.thermalState` and `isLowPowerModeEnabled`
- Display sleep notifications

Any window-level trigger pauses rendering on the affected display only, not globally.

---

## 5. Wallpaper Bundle Format (.waraq)

A simple zip-based format, like .saver or .vsix:

```
my_wallpaper.waraq/
├── manifest.json
├── preview.jpg           # Thumbnail for library
└── content/
    └── scene.mp4         # or index.html, or frames/*.png
```

`manifest.json`:
```json
{
  "schema": 1,
  "id": "com.author.wallpapername",
  "name": "Black Temple Reverie",
  "author": "Bahamut",
  "type": "video",
  "entry": "content/scene.mp4",
  "preview": "preview.jpg",
  "config": {
    "fit": "fill",
    "loop": true,
    "muted": true,
    "fps_cap": 30
  }
}
```

Future-proof: bumping `schema` lets us add fields without breaking older bundles. Community packs become a folder of `.waraq` files.

---

## 6. Phased Roadmap

### Phase 0: Bootstrap (1 day)
Goal: empty project, repo, CI building.

- [ ] Create GitHub repo, push initial Xcode project
- [ ] Configure GitHub Actions: build, test, archive on push
- [ ] Add SwiftLint, SwiftFormat
- [ ] Decide name, register bundle ID
- [ ] Generate Developer ID cert and notarytool credentials

Deliverable: a green CI badge on an empty app.

### Phase 1: Desktop Window Proof of Concept (2-3 days)
Goal: a video loops behind your desktop icons on one monitor.

- [ ] Implement `WallpaperWindow` (NSWindow at desktop icon level - 1)
- [ ] Hardcode a test MP4 file path
- [ ] Set up AVPlayerLayer in the window's contentView
- [ ] Verify icons render on top, clicks fall through to the desktop
- [ ] Handle window resize on resolution change

Deliverable: looping video behind icons, one monitor.

### Phase 2: Multi-Monitor + Menu Bar (3-4 days)
Goal: each display gets its own wallpaper, controllable from a menu bar icon.

- [ ] DisplayManager observes screen changes
- [ ] Menu bar app with NSStatusItem
- [ ] Right-click menu: pick wallpaper per display, quit, preferences
- [ ] Settings window (SwiftUI) with display list

Deliverable: usable v0.1 for personal use.

### Phase 3: Performance Governor (2-3 days)
Goal: the app should feel free.

- [ ] Fullscreen detection (pause that display)
- [ ] Battery / Low Power Mode awareness
- [ ] Occlusion-based pause
- [ ] Per-display FPS cap matching refresh rate
- [ ] Thermal throttling response

Deliverable: Activity Monitor shows near-zero CPU when any app is fullscreen.

### Phase 4: Wallpaper Library (3-5 days)
Goal: import, browse, manage `.waraq` bundles.

- [ ] WallpaperManifest parser
- [ ] Library view with thumbnail grid
- [ ] Drag-and-drop import
- [ ] Per-wallpaper config UI (volume, fit, fps cap)
- [ ] Local library folder at `~/Library/Application Support/Waraq/`

Deliverable: real product feel.

### Phase 5: Web Engine + Image Engine (2-3 days)
Goal: support more than just video.

- [ ] WebEngine with WKWebView, sandboxed
- [ ] Allow shader playgrounds (Shadertoy-style)
- [ ] ImageEngine for static + APNG/GIF sequences

Deliverable: feature parity with Plash plus video.

### Phase 6: Screensaver Bundle (2-3 days)
Goal: matching screensaver that uses the same content.

- [ ] Separate `.saver` target
- [ ] Shares engines via internal framework
- [ ] Reads same wallpaper library

Deliverable: pick once, applies to both desktop and screensaver.

### Phase 7: Polish + Distribution (3-5 days)
Goal: shipping the public v1.0.

- [ ] Sparkle integration for auto-update
- [ ] LaunchAtLogin
- [ ] Onboarding flow (3 default wallpapers bundled)
- [ ] Notarization in CI
- [ ] Landing page (static HTML on GitHub Pages, fits your GOBLIN_M0D3 ecosystem)
- [ ] Homebrew Cask submission
- [ ] README, CONTRIBUTING, LICENSE (MIT or GPL, your call)

Deliverable: public v1.0 release.

### Total: 4-6 weeks of focused evenings.

---

## 7. How We Use the Claude Kit

### Claude Code (terminal, your MacBook Pro)
The primary build tool. Once we lock the plan, you run Claude Code in the repo and it writes Swift, runs tests, iterates on builds. Best for:
- Implementing each phase's checklist
- Refactoring across files
- Writing unit tests
- Debugging build errors
- Running `xcodebuild` and parsing output

### Claude.ai chat (here)
For things that benefit from back-and-forth and where I can see the whole picture. Best for:
- Architecture decisions before you commit code
- Reviewing tricky Swift patterns (Metal pipelines, NSWindow level hacks)
- Debugging weird macOS behavior
- Reading and explaining Apple docs or Plash source
- Drafting README, marketing copy, release notes

### Artifacts (in this chat)
For visual exploration:
- Mock the settings window before building it in SwiftUI
- Design the wallpaper library grid layout
- Prototype the menu bar dropdown
- Build a landing page mockup

### Claude in Chrome (if you have it)
- Pull Plash source code while we discuss it
- Apple Developer docs lookups
- Live debugging when something works in Safari but not WKWebView

### Skills (in this chat)
- Generate a polished README.md
- Draft CONTRIBUTING.md
- Build the press kit PDF
- Generate the landing page

### Workflow per phase
1. Discuss the phase in chat, lock the design
2. I produce any spec docs, mockups, or code stubs as artifacts/files
3. You move to Claude Code in your terminal to implement
4. Bring back blockers, weird errors, or design questions to chat
5. End-of-phase review here before moving on

---

## 8. Open Source Dependencies (locked list)

Keep this list small. Every dependency is a tax.

- **Sparkle** (MIT): auto-update framework
- **LaunchAtLogin** (MIT): login item registration
- **Defaults** (MIT, Sindre Sorhus): typed UserDefaults wrapper (optional)
- **SwiftLint** (MIT, dev only): linting

Apple frameworks (free, no dependency cost):
- AppKit, SwiftUI, AVFoundation, WebKit, Metal, Combine, ScreenSaver

Reference projects to study (not depend on):
- [Plash](https://github.com/sindresorhus/Plash) (MIT): web wallpaper, similar window trick
- [WowWow](https://github.com/rwv/wowwow) (MIT): video wallpaper
- [Aerial](https://github.com/JohnCoates/Aerial) (MIT): screensaver patterns

---

## 9. Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Apple changes NSWindow level behavior in next macOS | Medium | Wrap in compat layer, test against macOS 14/15/26 betas |
| Notarization rejection | Low | Use only public APIs, no Mach injection, no private frameworks |
| Battery drain complaints | High if we slack on this | Performance Governor is Phase 3, not skippable |
| User wants lock screen wallpaper | High (you will get this request) | Document the Apple limitation in the README and FAQ |
| Wallpaper Engine community wants Workshop port | Medium | Plan migration tool for v2, not v1 |
| Single-developer burnout (you) | Real | Phases are sized for evenings, not weekends |

---

## 10. Phase 0 Kickoff Checklist

When you are ready to start, do these in order:

1. Pick the name
2. Create the GitHub repo (public, MIT license recommended)
3. Open Xcode, new macOS App, SwiftUI lifecycle, bundle ID `com.bahamut.<name>`
4. `git init`, push to GitHub
5. Add `.github/workflows/build.yml` for CI
6. Send me the repo URL and we go to Phase 1

I will draft the GitHub Actions workflow, the initial folder structure, and the first WallpaperWindow.swift skeleton whenever you say go.

---

## 11. Open Questions for You

Answer these before Phase 1 so we do not redo work later:

1. **Name**: Waraq, Roost, Nightfall, or your own?
2. **License**: MIT (most permissive, fastest community adoption) or GPLv3 (forces forks to stay open)?
3. **Min macOS version**: 14 (Sonoma) or 15 (Sequoia)? Lower = more users, higher = newer APIs.
4. **Free or paid**: Open source can still ship a paid binary on a website while keeping the repo public. Wallpaper Engine charges. Plash is free. Your call.
5. **Apple Developer account**: do you already have one, or do we need to factor in the $99 setup?
