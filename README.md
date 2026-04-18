# My Island

> **⚠️ 這是一份模板**:將 `[方括號]` 內容換成你自己的。`[實際 app 名]` 改成你決定的名字(例:My Island、Dev Notch 等)。

**Real-time AI coding agent status in your MacBook notch**

[![Release](https://img.shields.io/github/v/release/你的handle/my-island?style=flat-square)](https://github.com/你的handle/my-island/releases)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/你的handle/my-island/releases)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](./LICENSE)

[Install](#install) · [Features](#features) · [Supported Tools](#supported-tools) · [Build](#build-from-source)

[English] | [中文](./README.zh-TW.md)

---

## What is My Island?

My Island lives in your MacBook's notch area and shows you what your AI coding agents are doing — in real time. No more switching windows to check if Claude is waiting for approval or if Codex finished its task.

It connects to multiple AI coding tools via Unix socket IPC, displaying session status, tool calls, permission requests, and more — all in a compact panel that slides out of the notch.

![Screenshot](docs/images/screenshot.png)

---

## Features

- **Notch-native UI** — Expands from the MacBook notch, collapses when idle
- **Multiple AI agents supported** — Claude Code, Codex, Cursor, Gemini CLI, [...你加的 agent]
- **Live status tracking** — See active sessions, tool calls, and AI responses in real time
- **One-click permission approval** — Approve or deny tool permissions directly from the panel
- **Interactive Q&A** — Respond to agent questions without switching to terminal
- **Precise terminal jump** — Click a session to jump to its terminal tab or IDE window
- **Auto hook install** — Automatically configures hooks for all detected CLI tools
- **Multi-display** — Works with external monitors, graceful fallback on non-notch Macs
- **[你的特色功能 1]** — [描述]
- **[你的特色功能 2]** — [描述]

---

## Supported Tools

| AI Agent | Events | Terminal Jump | Status |
|---|---|---|---|
| Claude Code | 13 | Terminal tab | Full |
| Codex | 3 | Terminal | Basic |
| Cursor | 10 | IDE | Full |
| [...] | ... | ... | ... |

| Terminal | Detection | Jump-to-Tab |
|---|---|---|
| iTerm2 | Auto | ✅ Tab level |
| Ghostty | Auto | ✅ Window level |
| Terminal.app | Auto | ✅ Tab level |
| VS Code | Auto | ✅ Folder level |
| Cursor | Auto | ✅ Folder level |
| [...] | ... | ... |

---

## Install

### Download (Recommended)

1. Go to [Releases](https://github.com/你的handle/my-island/releases)
2. Download `MyIsland.dmg`
3. Open the DMG and drag My Island to `Applications`
4. Launch — it will automatically install hooks for detected AI tools

**First launch**: macOS may show a security warning if the app is not notarized.
Right-click My Island → **Open** → **Open** in the dialog.

Or run once in Terminal:
```bash
xattr -dr com.apple.quarantine "/Applications/My Island.app"
```

### Homebrew (coming soon)

```bash
# 未來有 tap 再填
# brew install --cask 你的handle/tap/my-island
```

### Build from Source

**Requirements**:
- macOS 14.0+
- Xcode 15+ with Command Line Tools
- Swift 5.9+

```bash
git clone https://github.com/你的handle/my-island.git
cd my-island

# Development build
swift build && open .build/debug/MyIsland.app

# Release build
./build.sh
open .build/release/MyIsland.app
```

詳見 [docs/packaging.md](./docs/packaging.md) 中的打包與簽章流程。

---

## First-Time Setup

當 app 第一次啟動,會做這些事:

1. **安裝 hooks** 到 `~/.claude/hooks/`(Claude Code 會用)
2. **請求權限**:
   - **Accessibility** — 讓 app 能切換 terminal tab
   - **Automation → iTerm2 / Ghostty / ...** — AppleScript 控制 terminal
   - **Notifications** — 顯示通知(可選)
3. **建立 Unix socket** 於 `/tmp/myisland-{UID}.sock` 監聽事件

如果你拒絕了某些權限,功能會降級但 app 仍可運作。可以之後在 系統設定 → 隱私權 補開。

---

## How It Works

```
AI Tool (Claude/Codex/Cursor/...)
  → Hook event triggered
    → myisland-bridge (Swift binary)
      → Unix socket → /tmp/myisland-<uid>.sock
        → My Island app receives event
          → Updates notch panel UI in real time
```

My Island 在每個 AI tool 的設定裡裝輕量 hook。當 tool 觸發事件(session 開始、tool call、permission 請求等),hook 會把 JSON 訊息透過 Unix socket 送給 my-island app,app 就即時更新瀏海面板。

更多細節見 [docs/architecture.md](./docs/architecture.md)。

---

## Settings

My Island 提供 [N] 個設定分頁:

- **General** — 語言、登入時啟動、預設螢幕
- **Behavior** — 自動收起、聰明抑制、session 清理
- **Appearance** — 面板高度、字型大小、AI 回覆顯示行數
- **Sound** — 通知音效
- **Hooks** — 查看 CLI 安裝狀態,重裝或卸載 hooks
- **[你加的分頁]** — [描述]
- **About** — 版本資訊

---

## Privacy

My Island **完全 local-first**:

- ✅ 所有資料存在你 Mac 上
- ✅ 沒有帳號系統
- ✅ 沒有遙測 / 分析
- ✅ 不傳送對話內容到任何伺服器

(如果你之後加了 iPhone 同步功能,記得來更新這段,並新增 [PRIVACY.md](./PRIVACY.md))

---

## Acknowledgments

My Island 是從 [wxtsky/CodeIsland](https://github.com/wxtsky/CodeIsland) 修改而來,向原作者的工作致敬。

CodeIsland 受啟發於 [farouqaldori/claude-island](https://github.com/farouqaldori/claude-island)。

在此一併感謝這些開源先驅:
- [@wxtsky](https://github.com/wxtsky) — CodeIsland
- [@farouqaldori](https://github.com/farouqaldori) — 最早把 AI agent 狀態帶進瀏海的原創概念

See [NOTICE](./NOTICE) for full attribution.

---

## Contributing

歡迎參與!見 [CONTRIBUTING.md](./CONTRIBUTING.md)。

- 回報 bug:[Open an issue](https://github.com/你的handle/my-island/issues/new?template=bug_report.md)
- 功能建議:[Open an issue](https://github.com/你的handle/my-island/issues/new?template=feature_request.md)
- 程式碼貢獻:Fork → branch → PR

---

## License

[MIT](./LICENSE)

---

## Star History

<!-- 有一些 stars 後可以加這個 -->
<!-- [![Star History](https://api.star-history.com/svg?repos=你的handle/my-island&type=Date)](https://star-history.com/#你的handle/my-island&Date) -->

---

## FAQ

**Q: 這跟 CodeIsland 有什麼不同?**
A: [你的差異化點]

**Q: 為什麼不直接用 CodeIsland?**
A: [你的動機]

**Q: 支援 Linux 嗎?**
A: 不支援。App 深度依賴 macOS 的 NSPanel、AppleScript、notch 偵測。

**Q: 支援 Windows 嗎?**
A: 不支援,同上。

**Q: App 沒開會不會影響 Claude Code?**
A: 不會。Hook 設計成 fail open — app 沒在跑時,hook 直接放行,Claude Code 正常運作。

**Q: 為什麼每次 build 都要重新給權限?**
A: 這是 macOS TCC 的限制。見 [docs/research/05-macos-permissions.md](./docs/research/05-macos-permissions.md)。
