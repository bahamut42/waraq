# Waraq Design Specs

Status: v1.0 locked (2026-05-26)
Project: Waraq (formerly Murmur), native macOS animated wallpaper app
Repo: github.com/Niiro92Othman/waraq

## Purpose

This folder is the design source of truth for Claude Code to implement
the v1 UI. Each spec covers one surface or system. Specs lock the
visual language, behaviors, dimensions, colors, accessibility, and
implementation hints so Claude Code does not have to guess.

When starting any phase from PLAN.md section 6, include the relevant
spec(s) below in the kickoff prompt so Claude Code reads them before
writing SwiftUI.

## Index

| File | Surface | Phase |
|---|---|---|
| `design-tokens.md` | Global colors, typography, spacing, modes | all |
| `app-icon.md` | App icon (dark + light), menu bar template, SVG source | 7 |
| `menubar.md` | Menu bar dropdown popover | 2 |
| `settings-shell.md` | Settings window, sidebar nav, Advanced toggle | 2 |
| `settings-general.md` | General pane | 2 |
| `settings-displays.md` | Displays pane, display profiles | 2 / 4 |
| `settings-library.md` | Library grid, WE import sheet | 4 |
| `settings-performance.md` | Performance pane, governor controls | 2 / 3 |
| `settings-wallpapers.md` | Defaults, rotation, schedule, transitions | 4 |
| `settings-diagnostics.md` | Logs, overlay, reports, reset | 7 |
| `settings-about.md` | About pane, credits, links, PayPal | 7 |
| `onboarding.md` | First-launch flow, hardware preset detection | 7 |

## Global rules (apply to every spec)

1. **Dark mode is not optional.** Every surface renders correctly in
   both modes and switches live without relaunch.
2. **System fonts only.** No bundled fonts. SF Pro Text via
   `-apple-system`.
3. **NSColor semantic tokens.** Never hardcoded hex except for brand
   accents inside content (preview images, icon, etc).
4. **Native materials.** `.regularMaterial` or `.thinMaterial` on
   popovers, sheets, sidebars.
5. **No em dashes** in any docs, comments, or UI copy. Period.
6. **Sentence case** in all UI strings. Never Title Case.
7. **Reset behavior**: any Reset action triggers the onboarding flow
   again. See `onboarding.md`.

## Modes

Two global UI modes set via a toggle at the bottom of the Settings
sidebar:

- **Basic**: Apple-clean defaults, minimal options, opinionated.
- **Advanced**: full depth across every pane, plus the Diagnostics
  pane appears in the sidebar.

Specs note which sections are basic-only, advanced-only, or both.

## How to use a spec

1. Read the spec end to end before writing any SwiftUI.
2. Components, layout, colors, and behaviors are non-negotiable. If
   you need to deviate, ask the user in chat first.
3. SF Symbol names are the source of truth for icons. Tabler icons
   appear in mockups but never in shipped code.
4. The Implementation notes section gives Claude Code specific Swift
   hints (which framework, which API, common pitfalls).

## Changelog

- 1.0 (2026-05-26): Initial lock. All twelve specs first published.
