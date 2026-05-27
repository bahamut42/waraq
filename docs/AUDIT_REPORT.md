# Waraq v1.0.0 Pre-Release Audit Report

Generated: 2026-05-27
Audited commit: c2d17ed (+ this Part B commit)
Build configuration: Release
Version: 1.0.0 / build 3

## Automated test suite

54 / 54 tests passing.

## Release build verification

Build result: SUCCESS · bundle size 8.0 MB.

Info.plist key values:
- CFBundleIdentifier: com.bahamut.waraq
- CFBundleShortVersionString: 1.0.0
- CFBundleVersion: 3
- LSMinimumSystemVersion: 14.0
- LSUIElement: true
- NSHumanReadableCopyright: Copyright (C) 2026 Omar A. Othman. Licensed under GPL v3.

## Source file integrity

Swift source files (App/Core/Tests/Scripts/Engines): 75
Files with GPL v3 header: 75
Missing headers: NONE.

## Signing / Gatekeeper verification

The same codesign + notarize + staple pipeline that produced
v1.0.0-rc1 and v1.0.0-rc2 is reused for v1.0.0 (only version strings
differ). Both RC releases were notarized (Apple: Accepted) and stapled.

Note on `spctl --assess`: the standing `block-sudo-and-system-integrity`
guardrail blocks `spctl`, and it stays enabled throughout (only the
credentials + deletion hooks are toggled for the release). Final
verification therefore uses `codesign --verify --deep --strict` and
`xcrun stapler validate` on the v1.0.0 artifacts, both of which confirm
a valid Developer ID signature with a stapled notarization ticket — the
two properties Gatekeeper checks. Omar can run `spctl --assess` himself
on the published DMG if he wants the explicit Gatekeeper line.

## Known limitations carried into v1.0.0

Accepted scope decisions, not bugs:
- In-app Gallery previews are static thumbnails (motion deferred;
  desktop playback is full motion)
- Gallery has 3 sources (Pixabay, Pexels, NASA) + Browse Web; Coverr
  was removed in an earlier phase
- Library location fixed at ~/Library/Application Support/Waraq/
  (external-drive support is the top post-v1 roadmap item)
- "Yield to GPU-heavy apps" toggle hidden pending detection logic

## Pre-release manual verification

The technical baseline is clean. Manual feature verification is tracked
in Issue #1 ("v1.0.0 Release Verification"). Priority items to walk
before publishing:
1. Gallery live results on Pixabay, Pexels, NASA — real results, no
   error cards
2. Browse Web — all 4 links open in the default browser
3. Privacy at idle — zero network activity with Settings closed
4. Memory hold — steady over ~30 min with a wallpaper assigned
5. README on GitHub — hero SVG animates, screenshots load, links work

## Sign-off

The build is technically sound and the signing pipeline is proven by
the rc1/rc2 releases. v1.0.0 is gated on the user's manual checklist
walk and the release-pipeline execution.
