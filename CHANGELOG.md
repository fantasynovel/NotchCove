# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.0.0] — 2026-04-18

First release of **Notch Cove**, a rebranded and redesigned build of [wxtsky/CodeIsland](https://github.com/wxtsky/CodeIsland).

### Added
- Rebrand to **Notch Cove** across all user-visible surfaces (app name, settings, menu bar, locales).
- **Traditional Chinese locale** (`zh-Hant`) with full translation set; language picker adds "繁體中文" and system-preferred resolution for `zh-TW` / `zh-HK` / `zh-MO`.
- **New app icon + in-app logos** — pre-rendered macOS icon set (`AppIcon.appiconset`) replacing the Liquid Glass composer; dedicated About + notch-header imagesets.
- **Settings typography & a11y overhaul** — site-wide 15pt titles, 12pt `#706F6F` descriptions (~5.5:1 contrast), Form base 14pt, section headers recolored, Picker 2-line labels spaced at 6pt. Removed all `.secondary`/`.tertiary` text and sub-12pt type to meet WCAG AA+.
- **Mascot Lab** settings tab for previewing every pixel character, its animations, and customizing animation parameters.
- **Shortcuts** settings tab for global keyboard shortcuts.
- **Remote** settings tab for receiving events from a remote machine.
- **Compact notch** layout for a tighter collapsed island.
- Dumbbell-curl working animation (replaces the generic typing loader for Claude).
- Out-of-order permission approval — allow / deny any pending request regardless of queue order.
- Live Appearance preview synced with panel styling.
- Restyled inline approval buttons and trimmed session row.
- README (English + Traditional Chinese), NOTICE, and SECURITY policy tailored to this fork.

### Changed
- Default content font size: **11pt → 12pt** (new `12pt_default` picker label across six locales).
- Collapsed-width slider unified at **100%–150%** for both extended and compact layouts.
- Tuned expanded-panel sizing and chat-row colors for better contrast.
- Collapsed island width tightened.
- Finalised chat-row copy.

### Notes
- Ad-hoc signed build. Not notarized. macOS Gatekeeper will block the app on first launch; see README install instructions for the unblock steps.
- Internal Swift target names (`CodeIsland`, `CodeIslandCore`, `codeisland-bridge`) and bundle id (`com.codeisland.app`) are kept from upstream to preserve existing users' data, permissions, and keychain entries. A full code-level rename is planned for a future release.
- See [NOTICE](./NOTICE) for full attribution.
