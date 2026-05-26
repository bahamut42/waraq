# Waraq

Native macOS animated wallpaper app. Lightweight, GPU accelerated, open source.

![status](https://img.shields.io/badge/status-pre--alpha-orange)
[![build](https://github.com/OWNER/waraq/actions/workflows/build.yml/badge.svg)](https://github.com/OWNER/waraq/actions/workflows/build.yml)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

## What it is

Waraq runs animated content (video, web scenes, image sequences) as your desktop background, with an optional matching screensaver. Designed to stay out of the way: hardware decoded video, per display pause when an app goes fullscreen, near zero CPU on a still frame.

See `docs/PLAN.md` for the full project plan, scope, and roadmap.

## Status

Pre-alpha. Phase 0 (bootstrap) in progress. Not yet usable.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16 or later
- Swift 5.10

## Build

Clone and open the project in Xcode:

```
git clone https://github.com/OWNER/waraq.git
cd waraq
open Waraq.xcodeproj
```

Or build from the command line:

```
xcodebuild \
  -project Waraq.xcodeproj \
  -scheme Waraq \
  -destination 'platform=macOS' \
  -configuration Debug \
  build
```

Run tests:

```
xcodebuild \
  -project Waraq.xcodeproj \
  -scheme Waraq \
  -destination 'platform=macOS' \
  test
```

## Project layout

```
App/          Menu bar app entry point
Core/         Shared engine: window, displays, governor, manifest
Engines/      Content engines: video, web, image
Library/      Wallpaper picker UI
Screensaver/  Companion .saver bundle
Resources/    Default wallpapers and icons
Tests/        Unit and integration tests
Scripts/      Build, sign, notarize helpers
docs/         Project plan and design notes
```

## Tooling

- SwiftLint (`.swiftlint.yml`) for linting
- SwiftFormat (`.swiftformat`) for formatting
- GitHub Actions (`.github/workflows/build.yml`) for CI

Install the local tools once:

```
brew install swiftlint swiftformat
```

Run them from the repo root:

```
swiftlint
swiftformat .
```

## License

MIT. See `LICENSE`.
