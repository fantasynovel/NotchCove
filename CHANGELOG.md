# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **Mascot Lab** settings tab for previewing every pixel character and its animations
- **Shortcuts** settings tab for global keyboard shortcuts
- **Remote** settings tab for receiving events from a remote machine
- **Compact notch** layout for a tighter collapsed island
- Dumbbell-curl working animation (replaces generic typing loader for Claude)
- Out-of-order permission approval — Allow / Deny any pending request regardless of queue order
- Live Appearance preview synced with panel styling
- Restyled inline approval buttons and trimmed session row

### Changed
- Tuned expanded-panel sizing and chat-row colors for better contrast
- Collapsed island width tightened
- Finalised chat-row copy

---

## [0.1.0] — Unreleased

### Added
- Initial fork from [wxtsky/CodeIsland](https://github.com/wxtsky/CodeIsland).
- Rebranded as NotchCove.
- Traditional Chinese README (`README.zh-TW.md`).
- NOTICE and SECURITY policy tailored to this fork.

### Notes
- This is a development-focused pre-release. Not yet signed or notarized.
- Internal Swift target names (`CodeIsland`, `CodeIslandCore`, `codeisland-bridge`) and bundle id (`com.codeisland.app`) are kept from upstream for this release; a full code-level rename is planned.
- See [NOTICE](./NOTICE) for attribution.
