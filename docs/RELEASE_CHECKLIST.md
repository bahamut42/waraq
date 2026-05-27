# Waraq v1.0.0 Release Verification Checklist

This checklist walks through every feature, setting, and action in
Waraq. Work through each section and check items off as you verify them.

Click the checkboxes in GitHub's web UI to track your progress (state
persists in GitHub Issues, not in the file view — for persistent
tracking use the "v1.0.0 Release Verification" Issue).

> **Status legend:**
> - [x] Verified working
> - [ ] Not yet checked
> - ~~strikethrough~~ Known limitation, accepted for v1

---

## 0. Action items from the automated audit (Phase 9.13)

- [ ] **GPL header added to all 10 `Engines/` Swift files** (Phase 9.12
  omitted `Engines/`; relicense currently 65/75 files — see
  `docs/AUDIT_REPORT.md`). Resolve before release.

## 1. Launch and basic lifecycle

- [ ] App launches from ~/Applications/Waraq.app without crashing
- [ ] App launches from Finder double-click
- [ ] Menu bar icon (wallpaper roll) appears in top-right corner
- [ ] No dock icon appears (Waraq is LSUIElement)
- [ ] Right-click on menu bar icon shows Settings, Quit, etc.
- [ ] Clicking "Quit Waraq" from menu bar quits the app cleanly
- [ ] Force-quitting via Activity Monitor doesn't corrupt library.json
- [ ] App relaunches successfully after first quit

## 2. Settings window

- [ ] Cmd+, opens Settings from anywhere when Waraq is active
- [ ] Clicking menu bar icon offers Settings option
- [ ] Settings window has title "Waraq Settings"
- [ ] Settings window can be moved, resized, minimized
- [ ] Settings window closes via Cmd+W
- [ ] Reopening Settings remembers the last-selected pane

## 3. General pane

- [ ] General pane displays without errors
- [ ] All visible toggles respond to clicks
- [ ] Setting changes persist across app relaunch

## 4. Displays pane

- [ ] All connected physical displays appear as rows
- [ ] Each display row shows resolution (e.g. 5,120 x 1,440)
- [ ] Display hardware name is shown (e.g. AG493US3R4)
- [ ] LIVE / OFF status indicator is accurate
- [ ] Toggle per display turns wallpaper on/off
- [ ] "MAIN" badge appears on the Waraq Primary display
- [ ] Right-click on a display row shows context menu
- [ ] "Set as Waraq Primary" context menu option works
- [ ] After setting Primary, MAIN badge moves to that display
- [ ] Currently-Primary display shows "Currently Primary" (disabled) in menu
- [ ] Configure button on each row opens display config sheet
- [ ] "Show Numbers" button flashes a number on each physical screen
- [ ] "When a known display connects" dropdown works
- [ ] "When a new display connects" dropdown works
- [ ] Display profiles persist across app relaunch
- [ ] Disconnecting and reconnecting same monitor restores its config
- [ ] Connecting a brand-new monitor triggers the "new display" behavior
- [ ] Advanced toggle reveals/hides advanced controls

## 5. Display configuration sheet

- [ ] Configure button opens sheet centered on the parent window
- [ ] Sheet shows current wallpaper assignment
- [ ] Wallpaper picker grid displays available wallpapers
- [ ] Thumbnails render for procedural wallpapers
- [ ] Thumbnails render for imported wallpapers
- [ ] Selecting a wallpaper applies it to that display immediately
- [ ] Fit mode selector works (Fill, Fit, Stretch, Tile)
- [ ] Mute/Volume controls work
- [ ] Loop behavior toggle works
- [ ] Sheet closes via Done button or Cmd+W
- [ ] Changes persist across app relaunch

## 6. Library pane

- [ ] Library pane lists all imported wallpapers
- [ ] Library shows the 6 built-in procedural wallpapers
- [ ] Thumbnails generate for all wallpapers (no broken images)
- [ ] Drag-drop MP4 file from Finder onto Library imports it
- [ ] Drag-drop GIF file from Finder onto Library imports it
- [ ] Drag-drop multiple files imports all of them
- [ ] Add menu offers File / Folder / GIF URL options
- [ ] Right-click wallpaper shows context menu
- [ ] "Set custom thumbnail" works
- [ ] "Reset to auto thumbnail" works
- [ ] "Show in Finder" reveals the wallpaper file (for non-procedural)
- [ ] Delete from library removes it (with confirmation)
- [ ] Library data persists across app relaunch

## 7. Gallery - Pixabay

- [ ] Pixabay tab loads without error
- [ ] "Add API key" button works if no key set
- [ ] After adding key, "Change API key" appears
- [ ] Search bar accepts input
- [ ] Search returns results within a few seconds
- [ ] Result grid shows thumbnails
- [ ] Hovering over a result highlights it
- [ ] Clicking a result opens preview
- [ ] Preview shows attribution (creator name + Pixabay)
- [ ] "Add to Library" button downloads the video
- [ ] Downloaded video appears in Library tab
- [ ] Downloaded video plays correctly when assigned
- [ ] Repeating same search returns cached results quickly

## 8. Gallery - Pexels

- [ ] Pexels tab loads without error
- [ ] API key flow works (with a real Pexels API key)
- [ ] Search returns results
- [ ] No error card appears (post-9.10 schema fix verified)
- [ ] Results show thumbnails
- [ ] Add to Library works end-to-end

## 9. Gallery - NASA

- [ ] NASA tab loads without error (no API key needed)
- [ ] Search returns results
- [ ] No error card appears (post-9.10 URL prediction fix)
- [ ] Results show NASA thumbnails
- [ ] Add to Library works end-to-end
- [ ] Downloaded NASA video plays correctly

## 10. Gallery - Browse Web

- [ ] Browse Web tab appears beside the Online Sources tab
- [ ] 4 cards display: MotionBGs, MoeWalls, MyLiveWallpapers, Wallsflow
- [ ] Each card shows icon, name, description, category tags
- [ ] "Open in Browser" launches default browser to correct URL
- [ ] Footer "How it works" text is readable
- [ ] After downloading from external site manually, drag-drop into Library still works

## 11. Performance pane

- [ ] Performance pane loads without error
- [ ] "Pause when on battery" toggle works
- [ ] "Pause in Low Power Mode" toggle works
- [ ] "Pause on thermal pressure" toggle works
- [ ] "Pause at" severity level selector works
- [ ] "Render quality" selector works (Auto, Low, Medium, High)
- [ ] "Decode mode" selector works (Hardware only, etc.)
- [ ] "Cap frame rate per display" toggle works
- [ ] "Drop frames on heavy load" toggle works
- [ ] "Max memory per wallpaper" slider works
- ~~"Yield to GPU-heavy apps" toggle visible~~ (hidden in 9.9, pending detection)
- [ ] All performance settings persist across relaunch

## 12. Wallpapers (built-ins)

- [ ] All 6 procedural wallpapers appear in the Library
- [ ] Animated Gradient renders correctly
- [ ] Aurora Borealis renders correctly
- [ ] Matrix Rain renders correctly
- [ ] Synthwave Drive renders correctly
- [ ] Starfield renders correctly
- [ ] Neural Network renders correctly
- [ ] Each procedural has a generated thumbnail
- [ ] Switching between procedurals on the same display is smooth

## 13. Onboarding

- [ ] First launch (after defaults reset) shows the wizard
- [ ] Wizard window has 5 steps: Welcome / Displays / Wallpaper / Performance / Finish
- [ ] Welcome step displays correctly
- [ ] Displays step shows connected monitors
- [ ] Wallpaper step lets the user pick a starter wallpaper
- [ ] Performance step has launch-at-login toggle
- [ ] Finish step has a clear completion action
- [ ] Skip / Back / Next navigation works at each step
- [ ] Completing the wizard sets hasCompletedOnboarding
- [ ] Subsequent launches don't show the wizard again
- [ ] About pane has "Run Setup Again" button that re-opens it

## 14. About pane

- [ ] About pane displays Waraq version (currently 0.1.0 - bump for v1)
- [ ] App icon displayed
- [ ] GPL v3 license card shown
- [ ] Link to gnu.org/licenses/gpl-3.0.html works
- [ ] GitHub link works (opens browser to repo)
- [ ] "Run Setup Again" button works
- [ ] Copyright string shows "Omar A. Othman"

## 15. Privacy and network

- [ ] App makes ZERO network requests at launch (verify with Little
      Snitch, lsof, or Activity Monitor's Network tab)
- [ ] App makes zero network requests after closing Settings
- [x] No analytics, telemetry, or crash-reporting libraries in the
      bundle (audit confirmed via `otool -L` — clean)
- [ ] Only network activity happens when user explicitly clicks Search
      in Gallery (then only to the relevant API host)
- [ ] Browse Web tab opens external URLs in default browser without
      Waraq fetching any content from those sites
- [ ] API keys stored in macOS UserDefaults, never transmitted outside
      the relevant API call

## 16. Build, packaging, and licensing

- [x] Release build produces working .app (audit: SUCCESS)
- [x] App bundle is < 100 MB (audit: 8.1 MB)
- [x] CFBundleIdentifier = com.bahamut.waraq (audit verified)
- [x] LSMinimumSystemVersion = 14.0 (audit verified)
- [x] LSUIElement = 1 (audit verified)
- [x] NSHumanReadableCopyright mentions GPL v3 (audit verified)
- [ ] App icon renders correctly in Finder, Dock (when shown), Spotlight
- [ ] **Every Swift source file has the GPL v3 header** — currently
      FAILING: 10 `Engines/` files lack it (see section 0 / AUDIT_REPORT)
- [x] LICENSE is canonical GPL v3 text (audit: 35,149 bytes)
- [x] No COPYING duplicate (removed in 9.12)
- [x] GitHub detects "GPL-3.0" as the repo license badge

## 17. README and documentation

- [ ] README renders correctly on GitHub
- [ ] Animated SVG hero plays on the README page
- [ ] hero-desktop.gif loops correctly
- [ ] All screenshot embeds load (no broken image links)
- [ ] License badge shows blue GPLv3
- [ ] Release badge shows "no releases yet" or the latest tag
- [ ] All section headings render correctly
- [ ] All hyperlinks work (Pixabay, Pexels, NASA, external sites, GPL link, PayPal)
- [ ] "What Waraq does / doesn't do" sections are accurate
- [ ] Privacy section is accurate
- [ ] Build-from-source instructions work on a clean clone

## 18. Performance and resource usage

- [ ] CPU usage idle (wallpaper running, Settings closed): < 5%
- [ ] CPU usage while paused (fullscreen app or battery): ~0%
- [ ] Memory usage per wallpaper window: reasonable for video size
- [ ] GPU usage is non-zero only when wallpapers are actively rendering
- [ ] Multi-monitor doesn't double or triple CPU/GPU usage linearly
- [ ] Switching wallpapers doesn't leak memory (run 30 min, switch a few times, check memory holds)
- [ ] Sleep/wake cycle restores wallpapers correctly
- [ ] Display sleep restores wallpapers correctly when monitors wake

## 19. Edge cases and resilience

- [ ] Corrupt MP4 file: shows error instead of crashing
- [ ] Missing file referenced in library.json: graceful handling
- [ ] No displays connected then unplugged: doesn't crash
- [ ] App update / replace .app while running: graceful behavior
- [ ] Quitting during a Gallery download: doesn't leave partial files
- [ ] Network unavailable during Gallery search: shows error card, not silent empty grid
- [ ] Invalid API key: shows error card with API's actual message
- [ ] Very large MP4 file (>1 GB): doesn't OOM the system

## 20. CI / repository hygiene

- [ ] GitHub Actions CI is green on main
- [ ] No uncommitted changes
- [ ] No leftover Waraq.xcodeproj in tracked files (it's gitignored)
- [ ] No leftover DerivedData paths in tracked files
- [ ] No personal info leaked in commits (API keys, paths, etc.)
- [ ] `.gitignore` is comprehensive

## 21. Ready for release

Once everything above is checked and any issues fixed (or accepted as
known limitations), this section gates the Phase 10 release execution.

- [ ] Section 0 action item (Engines GPL headers) resolved
- [ ] All P0 items above are checked or explicitly accepted
- [ ] Version number bumped from 0.1.0 to v1 release number (e.g. 1.0.0)
- [ ] Release notes draft prepared
- [ ] Developer ID Application cert confirmed valid:
      `security find-identity -v -p codesigning` shows it
- [ ] Notary profile confirmed:
      `xcrun notarytool history --keychain-profile waraq-notary` succeeds
- [ ] Ready to run Phase 10

---

When you're ready to ship, hand the Phase 10 prompt to Claude Code.
Phase 10 will: codesign the Release build, notarize via Apple's notary
service, build a DMG, write release notes, and cut a GitHub Release with
the DMG attached.
