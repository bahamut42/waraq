# Phase 0 Handoff: Tasks 1 and 8

This document covers the two tasks that have to happen in Claude Code
on your MacBook, not in chat. Run through them in order. When the final
xcodebuild reports `BUILD SUCCEEDED` and `TEST SUCCEEDED`, Phase 0 is
done.

## Prereqs

```
xcode-select -p
xcodebuild -version    # expect Xcode 16.x
swift --version        # expect 5.10+
brew install swiftlint swiftformat
```

## Task 1: Xcode project structure

Goal: an Xcode project at the repo root called `Waraq.xcodeproj`, with
the folder layout from PLAN.md section 3. Bundle ID
`com.bahamut.waraq`. Deployment target macOS 14.0.

Steps:

1. From an empty repo (with the files I shipped already committed),
   open Xcode and choose File > New > Project.
2. Pick macOS > App. Click Next.
3. Fill in:
   - Product Name: `Waraq`
   - Team: your Apple Developer team (or None for now)
   - Organization Identifier: `com.bahamut`
   - Bundle Identifier: should auto-fill to `com.bahamut.waraq`
   - Interface: SwiftUI
   - Language: Swift
   - Storage: None
   - Tests: checked
4. Save the project into the repo root. When Xcode asks to create a
   git repo, say No (we already have one).
5. In Finder, you should now have `Waraq.xcodeproj`, `Waraq/`, and
   `WaraqTests/`. Close Xcode.
6. Reorganize on disk to match PLAN.md section 3:

```
mkdir -p App Core Engines Library Screensaver Resources Tests Scripts
git mv Waraq/WaraqApp.swift App/WaraqApp.swift
git mv Waraq/ContentView.swift App/ContentView.swift   # delete later
git mv Waraq/Assets.xcassets Resources/Assets.xcassets
git mv Waraq/Preview\ Content Resources/Preview\ Content
git mv WaraqTests/* Tests/
rmdir Waraq WaraqTests
```

7. Open `Waraq.xcodeproj` again. Files will show red. Fix by:
   - Right-click each red group, Delete > Remove Reference.
   - Right-click the project root, Add Files to Waraq, and add the
     new folders (`App`, `Core`, `Engines`, `Library`, `Screensaver`,
     `Resources`, `Tests`) with `Create groups` selected and the
     correct target membership (everything except `Tests` to the
     `Waraq` target, `Tests` to the `WaraqTests` target).
8. In the project settings, target `Waraq`:
   - General > Minimum Deployments: macOS 14.0
   - General > Bundle Identifier: `com.bahamut.waraq`
   - Signing & Capabilities: Sign to Run Locally (or your team)
9. Add the `Screensaver` target later (Phase 6). Skip for now.
10. Commit:

```
git add -A
git commit -m "Phase 0: scaffold Xcode project with PLAN.md layout"
```

## Task 8: Verify the build

From the repo root:

```
xcodebuild \
  -project Waraq.xcodeproj \
  -scheme Waraq \
  -destination 'platform=macOS' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Expect `** BUILD SUCCEEDED **`.

Then tests:

```
xcodebuild \
  -project Waraq.xcodeproj \
  -scheme Waraq \
  -destination 'platform=macOS' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Expect `** TEST SUCCEEDED **` (the default template ships one passing
test stub).

## Push and watch CI

```
git remote add origin git@github.com:OWNER/waraq.git   # replace OWNER
git branch -M main
git push -u origin main
```

Open the Actions tab on GitHub. The `build` workflow should run on the
push, take a few minutes, and go green. The CI badge in README will
flip from grey to green once it does.

## Phase 0 done when

- [ ] `Waraq.xcodeproj` exists at repo root with the section 3 layout
- [ ] Local `xcodebuild build` succeeds
- [ ] Local `xcodebuild test` succeeds
- [ ] `swiftlint` runs with zero errors (warnings OK for now)
- [ ] `swiftformat --lint .` runs clean
- [ ] GitHub Actions `build` workflow goes green on `main`
- [ ] README CI badge is green
- [ ] `OWNER` placeholder is replaced in README and remote URL

Ping me with the repo URL and a screenshot of the green check when
you are there. Then we open Phase 1 and I draft the `WallpaperWindow`
skeleton.
