<h1 align="center">
  <img src="logo.png" width="48" height="48" alt="NotchCove Logo" valign="middle">&nbsp;
  NotchCove
</h1>
<p align="center">
  <b>Real-time AI coding agent status in your MacBook notch</b><br>
  <a href="#install">Install</a> •
  <a href="#features">Features</a> •
  <a href="#supported-tools">Supported Tools</a> •
  <a href="#build-from-source">Build</a><br>
  English | <a href="README.zh-TW.md">繁體中文</a>
</p>

<p align="center">
  <a href="https://github.com/fantasynovel/NotchCove/releases"><img src="https://img.shields.io/github/v/release/fantasynovel/NotchCove?style=flat-square" alt="Release"></a>
  <a href="https://github.com/fantasynovel/NotchCove/releases"><img src="https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple" alt="macOS"></a>
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License"></a>
</p>

---

<p align="center">
  <img src="docs/images/notch-panel.png" width="700" alt="NotchCove Panel Preview">
</p>

## What is NotchCove?

> This project is a modified build of [wxtsky/CodeIsland](https://github.com/wxtsky/CodeIsland), with substantial changes to layout, typography, accessibility (WCAG), Traditional Chinese localization, and mascot / animation work.

NotchCove lives in your MacBook's notch area and shows you what your AI coding agents are doing — in real time. No more switching windows to check if Claude is waiting for approval or if Codex finished its task.

It connects to multiple AI coding tools via Unix socket IPC, displaying session status, tool calls, permission requests, and more — all in a compact pixel-style panel that slides out of the notch.

---

## Features

- **Notch-native UI** — Expands from the MacBook notch, collapses when idle
- **Compact notch mode** — Extra-tight collapsed layout for minimalist workflows
- **11 AI tools supported** — Claude Code, Codex, Gemini CLI, Cursor, Copilot, Trae/TraeCli, Qoder, Factory, CodeBuddy, OpenCode, Kimi Code CLI
- **Live status tracking** — See active sessions, tool calls, and AI responses in real time
- **Out-of-order permission approval** — Approve or deny tool permissions in any order, directly from the panel
- **Interactive Q&A** — Respond to agent questions without leaving the notch
- **Pixel mascots + Mascot Lab** — Each AI tool has its own animated pixel mascot; preview and tune them in the dedicated Mascot Lab tab, including customizable mascot animation parameters
- **Working animations** — Playful loaders (e.g. dumbbell curls for Claude) instead of generic spinners
- **Precise terminal jump** — Click a session to jump to its exact terminal tab or IDE window
- **Smart notification suppression** — Tab-level detection: only suppresses notifications when you're actually looking at that session's tab
- **Auto hook install** — Automatically configures hooks for all detected CLI tools, with auto-repair and version tracking
- **Keyboard shortcuts** — Dedicated Shortcuts settings tab for global hotkeys
- **Remote panel** — Receive events from a remote machine via the Remote tab
- **Bilingual UI** — Traditional Chinese + English, follows system language
- **Multi-display** — Works with external monitors, graceful fallback on non-notch Macs
- **Sound effects** — Optional 8-bit style audio cues

---

## Supported Tools

| | Tool | Events | Jump | Status |
|:---:|------|--------|------|--------|
| <img src="docs/images/mascots/claude.gif" width="28"> | <img src="Sources/CodeIsland/Resources/cli-icons/claude.png" width="16"> Claude Code | 13 | Terminal tab | Full |
| <img src="docs/images/mascots/codex.gif" width="28"> | <img src="Sources/CodeIsland/Resources/cli-icons/codex.png" width="16"> Codex | 3 | Terminal | Basic |
| <img src="docs/images/mascots/gemini.gif" width="28"> | <img src="Sources/CodeIsland/Resources/cli-icons/gemini.png" width="16"> Gemini CLI | 6 | Terminal | Full |
| <img src="docs/images/mascots/cursor.gif" width="28"> | <img src="Sources/CodeIsland/Resources/cli-icons/cursor.png" width="16"> Cursor | 10 | IDE | Full |
| <img src="docs/images/mascots/trae.gif" width="28"> | <img src="Sources/CodeIsland/Resources/cli-icons/traecli.png" width="16"> TraeCli | 10 | Terminal | Full |
| <img src="docs/images/mascots/qoder.gif" width="28"> | <img src="Sources/CodeIsland/Resources/cli-icons/qoder.png" width="16"> Qoder | 10 | IDE | Full |
| | <img src="Sources/CodeIsland/Resources/cli-icons/copilot.png" width="16"> Copilot | 6 | Terminal | Full |
| <img src="docs/images/mascots/factory.gif" width="28"> | <img src="Sources/CodeIsland/Resources/cli-icons/factory.png" width="16"> Factory | 10 | IDE | Full |
| <img src="docs/images/mascots/codebuddy.gif" width="28"> | <img src="Sources/CodeIsland/Resources/cli-icons/codebuddy.png" width="16"> CodeBuddy | 10 | App/Terminal | Full |
| | <img src="Sources/CodeIsland/Resources/cli-icons/kimi.png" width="16"> Kimi Code CLI | 10 | Terminal | Full |
| <img src="docs/images/mascots/opencode.gif" width="28"> | <img src="Sources/CodeIsland/Resources/cli-icons/opencode.png" width="16"> OpenCode | All | App/Terminal | Full |

| Terminal | Detection | Jump-to-Tab |
|----------|-----------|-------------|
| iTerm2 | Auto | Tab level |
| Ghostty | Auto | Window level |
| Terminal.app | Auto | Tab level |
| VS Code | Auto | Folder level |
| Cursor | Auto | Folder level |

---

## Install

### Manual Download

1. [Download the latest release](https://github.com/fantasynovel/NotchCove/releases/latest) (`NotchCove.dmg`)
2. Open the DMG and drag **Notch Cove** into **Applications**
3. Double-click to launch — on first open, macOS will show a security warning ⚠️. **Don't send it to the trash!**

This build is not Apple Developer–signed (Apple Developer Program costs $99 USD/year). Unblock it one of two ways:

**Option A:** Go to **System Settings → Privacy & Security**, scroll down to "Notch Cove was blocked" and click **Open Anyway**.

**Option B:** Open Terminal and run:

```bash
xattr -dr com.apple.quarantine "/Applications/Notch Cove.app"
```

Once unblocked, launching Notch Cove will auto-install hooks for every detected AI tool.

### Build from Source

**Requirements:** macOS 14.0+, Xcode 15+, Swift 5.9+

```bash
git clone https://github.com/fantasynovel/NotchCove.git
cd NotchCove

# Development build
swift build && ./.build/debug/CodeIsland

# Release build (universal binary: Apple Silicon + Intel)
./build.sh
open ".build/release/Notch Cove.app"
```

> Note: the Swift target is still named `CodeIsland` internally from the original fork. A full code-level rename to `NotchCove` is planned for a future release.

---

## First-Time Setup

On first launch, NotchCove will:

1. **Install hooks** into `~/.claude/hooks/` (and the equivalent paths for other AI tools)
2. **Request permissions:**
   - **Accessibility** — so the app can switch terminal tabs
   - **Automation → iTerm2 / Ghostty / …** — AppleScript control for terminals
   - **Notifications** — optional, for system notifications
3. **Create a Unix socket** at `/tmp/codeisland-<UID>.sock` to listen for events

If you deny any permission, related features degrade gracefully and can be re-enabled later in **System Settings → Privacy & Security**.

---

## How It Works

```
AI Tool (Claude/Codex/Gemini/Cursor/...)
  → Hook event triggered
    → codeisland-bridge (native Swift binary, ~86KB)
      → Unix socket → /tmp/codeisland-<uid>.sock
        → NotchCove app receives the event
          → Notch panel updates in real time
```

NotchCove installs lightweight hooks in each AI tool's config. When a tool fires an event (session start, tool call, permission request, …), the hook sends a JSON message over a Unix socket. NotchCove listens on that socket and updates the notch panel immediately.

**OpenCode** uses a JS plugin that talks to the socket directly — no bridge binary needed.

More details in [docs/research/02-hook-protocol.md](./docs/research/02-hook-protocol.md) and [docs/research/03-unix-socket.md](./docs/research/03-unix-socket.md).

---

## Settings

NotchCove ships with 9 settings tabs:

- **General** — Language, launch at login, preferred display
- **Behavior** — Auto-hide, smart suppression, session cleanup
- **Appearance** — Panel height, font size, chat-row colors, live preview
- **Mascots** — Mascot Lab: preview every pixel character and its animations
- **Sound** — 8-bit style audio notifications
- **Shortcuts** — Global keyboard shortcuts
- **Remote** — Receive events from a remote machine
- **Hooks** — Installation status per CLI, reinstall or uninstall
- **About** — Version info and links

---

## Privacy

NotchCove is **local-first**:

- All data stays on your Mac
- No account system
- No telemetry, no analytics
- No conversation content is sent anywhere

---

## Acknowledgments

NotchCove is a fork of [wxtsky/CodeIsland](https://github.com/wxtsky/CodeIsland), with credit to the original author.

CodeIsland was itself inspired by [farouqaldori/claude-island](https://github.com/farouqaldori/claude-island).

Thanks to:
- [@wxtsky](https://github.com/wxtsky) — CodeIsland
- [@farouqaldori](https://github.com/farouqaldori) — the original concept of surfacing AI agent state in the notch

See [NOTICE](./NOTICE) for full attribution.

---

## Contributing

- Report a bug: [Open an issue](https://github.com/fantasynovel/NotchCove/issues/new?template=bug_report.md)
- Suggest a feature: [Open an issue](https://github.com/fantasynovel/NotchCove/issues/new?template=feature_request.md)
- Code contributions: fork → branch → PR

---

## License

[MIT](./LICENSE)

---

## FAQ

**Q: How is this different from CodeIsland?**
A: NotchCove focuses on a more compact notch layout, revised chat styling, a Mascot Lab for pixel characters, out-of-order permission approval, keyboard shortcuts, and a Remote panel.

**Q: Does NotchCove work without running?**
A: Hooks are designed to fail open — when the app isn't running, they silently pass through, and your AI tools keep working normally.

**Q: Linux / Windows support?**
A: No. The app depends heavily on macOS NSPanel, AppleScript, and notch detection.

**Q: Why do permissions re-prompt on every rebuild?**
A: macOS TCC ties permissions to a signed binary identity. Unsigned dev builds get a new identity each time. See [docs/research/05-macos-permissions.md](./docs/research/05-macos-permissions.md).
