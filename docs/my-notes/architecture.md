# 我理解的架構(My Island)

> **這份筆記給誰看?**:只給我自己看的草稿版本。正式對外的架構文件在 `docs/architecture.md`(那個還沒寫,等我真的懂了再寫)。
>
> **怎麼用?**:Phase 4 讀完 CodeIsland 的 code 後,**用我自己的話**把我理解的資料流寫下來。寫不出來就是我沒懂。
>
> **最後更新**:2026-04-18(做完 Notch Cove 1.0.0 發版前的大整理後回填)

---

## 整體資料流(我的理解)

用簡單文字畫:

```
                     我正在跑 Claude Code

    ┌──────────────────────────┐
    │  Terminal 裡              │
    │  $ claude                 │
    │  > 請幫我改 code          │
    │  Claude: 我要跑 Bash...   │
    └───────────┬───────────────┘
                │ 觸發 PreToolUse hook
                ▼
    ┌──────────────────────────┐
    │  ~/.claude/hooks/xxx.sh  │
    │  (CodeIsland 裝的)       │
    │  收 stdin 的 JSON        │
    └───────────┬───────────────┘
                │ 透過 Unix socket
                │ /tmp/codeisland-501.sock
                ▼
    ┌──────────────────────────┐
    │  My Island app           │
    │  (在瀏海常駐)            │
    │                          │
    │  ① Socket listener 收到  │
    │  ② Parse JSON            │
    │  ③ 更新 SessionManager   │
    │  ④ SwiftUI 重畫瀏海      │
    └───────────┬──────────────┘
                │
                │ 使用者按 [Allow]
                ▼
    ┌──────────────────────────┐
    │  Socket 寫回給 hook      │
    │  {"decision":"approve"}  │
    └───────────┬──────────────┘
                │
                ▼
    ┌──────────────────────────┐
    │  Hook exit 0             │
    │  Claude 繼續跑 Bash      │
    └──────────────────────────┘
```

---

## 核心 Components(我觀察到的)

### 1. 進入點

**檔案**:`Sources/CodeIsland/CodeIslandApp.swift` + `Sources/CodeIsland/AppDelegate.swift`

**做的事**:
- `@main struct CodeIslandApp: App` 是 SwiftUI 進入點,實際初始化邏輯走 `AppDelegate.applicationDidFinishLaunching`
- `StatusItemController`(`StatusItemController.swift`)建選單列 icon + 右鍵選單(設定/退出/檢查更新/匯出診斷/Hooks)
- `PanelWindowController`(`PanelWindowController.swift`)建瀏海 NSPanel overlay、掛 `NotchPanelView`
- `ConfigInstaller`(`ConfigInstaller.swift`)在啟動時自動偵測已安裝的 CLI 並修補 hook

---

### 2. AppState(= 我原本猜的 SessionManager)

**檔案**:`Sources/CodeIsland/AppState.swift`(約 2900 行,整個 app 最大的一個檔)

**角色**:整個 app 的「狀態中心」,`ObservableObject`,SwiftUI 所有 View 都 `@ObservedObject`/`@EnvironmentObject` 它。實務上是 Session、pending approval、pending question、surface、settings cache 等各種狀態的大集合。

**維護的資料**:
- `sessions: [String: Session]`(dict,key 是 session UUID)
- `pendingPermission`、`pendingQuestion`、`pendingCompletion`
- `surface: IslandSurface`(UI 當前 surface,`IslandSurface.swift` 定義)
- 以及一堆每個 CLI 的 metadata 映射

不是單一職責,功能滿肥,但集中管理 avoid 散到各處的 race condition。

---

### 3. HookServer(Socket 監聽)

**檔案**:`Sources/CodeIsland/HookServer.swift`

**角色**:用 SwiftNIO 在 `/tmp/codeisland-<uid>.sock` 開 Unix domain socket,監聽 bridge 送來的 JSON,解析成 event 後丟給 `AppState`。同時支援 bridge 主動關 socket 的 EOF 讀取(fail-open 設計的一環)。

---

### 4. ConfigInstaller(Hook 安裝)

**檔案**:`Sources/CodeIsland/ConfigInstaller.swift`

**角色**:
- 自動安裝 hook 到 `~/.claude/hooks/`、`~/.codex/config.toml`、`~/.cursor/...` 等各家 CLI 的設定
- 每個 CLI 一個專屬 template,注入 bridge 呼叫行
- 版本標記寫在 hook 裡(`# Notch Cove hook v2`),下次啟動比對版本決定是否自動升級
- 有「清理舊 scalar hooks」的遷移邏輯(早期版本留的)

---

### 5. Bridge CLI

**檔案**:`Sources/CodeIslandBridge/main.swift`(**還是叫 CodeIslandBridge,沒改名**,保留相容性)

**角色**:
- **獨立的 executable**,打包在 `Notch Cove.app/Contents/Helpers/codeisland-bridge`
- 被 hook 呼叫時讀 stdin(Claude/Codex/Cursor 傳的 JSON)
- 連 `/tmp/codeisland-<uid>.sock`,把 JSON 轉發給主 app
- 讀 socket 回應(approve/deny/skip),依回應 exit code 決定讓 CLI 繼續或中止

**為什麼要獨立 CLI?**:hook 指令必須是 executable,且 CLI 的生命週期比主 app 短,獨立 binary 好重啟、好 debug,main app 掛了也不會卡 CLI。

---

### 6. NotchPanel(UI)

**檔案**:`Sources/CodeIsland/NotchPanelView.swift`(2000+ 行)+ `PanelWindowController.swift`

**角色**:
- `PanelWindowController` 建 NSPanel、設 floating level、管瀏海位置 + 螢幕切換
- `NotchPanelView` 是 SwiftUI root,依 `isCompactLayout`、`shouldShowExpanded`、`showIdleIndicator` 切換多種佈局(Compact wings / CompactNotchContent / IdleIndicatorBar / Expanded surface)
- `panelWidth` computed property 依狀態動態算寬度(我寫過一份清單在 PR 對話裡)

---

### 7. TerminalActivator

**檔案**:`Sources/CodeIsland/TerminalActivator.swift` + `TerminalVisibilityDetector.swift`

**角色**:
- `TerminalActivator`:使用者點會話 → AppleScript 切 iTerm/Ghostty/Terminal.app 的對應 tab、或啟動 VSCode/Cursor 視窗
- `TerminalVisibilityDetector`:背景偵測「Agent 所在 tab 是否在前景」,配合 Smart Suppress 設定決定要不要自動展開面板

---

## 我還不懂的地方

- [ ] `AppState` 那 2900 行內部的 event loop 順序——目前我只知道大概,還沒追過每個 `@Published` 的 mutation 路徑
- [ ] `HookServer` 的 SwiftNIO 錯誤處理(EventLoop 掛掉後會重建嗎?socket 檔案被刪會自動 recover 嗎?)
- [ ] 多 session 同時需要審批時的 UI queue 邏輯——compact notch 模式下到底怎麼堆疊?
- [ ] `MascotLab.swift` 的動畫參數調整是 live 存 UserDefaults 還是 in-memory?關掉 lab 視窗後 app 會保留嗎?
- [ ] `TerminalVisibilityDetector` 在多螢幕環境下的正確率——改 `AppleScript` 還是 `CGWindowListCopyWindowInfo` 比較可靠?

**策略**:每個「不懂的地方」→ 開個 research note 或實驗去搞懂。

---

## 關鍵設計決策(我猜的)

### 為什麼要用 Unix socket 不用別的?

我的理解:hook 是短命行程,每次 CLI 觸發就開一個新 process。要跟常駐 app 通訊必須是 IPC。候選有 named pipe / TCP localhost / HTTP / Unix socket。Unix socket 的優點:
- 不佔 port(macOS 使用者裝別的 localhost server 不會撞)
- 權限綁檔案系統(權限 `srwx------`,只有使用者自己能連)
- 比 HTTP 快、沒 TCP 三次握手

### 為什麼要把 bridge 獨立成 CLI?

我的理解:hook 指令寫死在 CLI 設定檔裡,必須是 executable。不可能讓 `~/.claude/hooks/xxx.sh` 裡寫 `swift run CodeIsland --event ...`——Swift Package Manager 的啟動成本要 500ms+。獨立 compile 過的 bridge 只要 20ms 左右、binary 才 86KB、冷啟動很便宜。

### Hook 為什麼 fail open?

我的理解:hook 掛掉(找不到 bridge、socket 關著、JSON 解析失敗)時 **`exit 0` 讓 CLI 繼續跑**。反過來 fail closed 會讓 Claude 卡住。原則是「通知系統掛掉 ≠ 要擋住使用者工作」。

### 為什麼 UI 用 SwiftUI 不用純 AppKit?

我的理解:瀏海面板要大量動畫 + 狀態驅動的重繪(approval 卡片、mascot、tool status 動畫、收合/展開轉場),SwiftUI 的 `@State` + `withAnimation` 比 AppKit 的 `CAAnimation` 好寫一個數量級。壞處是 NSPanel 本身還是要走 AppKit(`PanelWindowController`),邊界地方要小心 sizing。

### 為什麼 Settings 用 Form 而不是手寫 VStack?

我自己做 a11y 整理時才體會到:macOS Form grouped 會自動處理 row 高度、分隔線、hover highlight、accessibility label,自己寫全部要重做一次。典型樣式用 Form 省力很多,只有 Mascot Lab 那種高自訂度 UI 才必須手刻。

---

## Phase 4 驗收:我能用自己的話解釋這些嗎?

- [x] 當我在 terminal 按下 Enter 送出 prompt,到瀏海跳出通知,中間發生了哪些事?
  → CLI 觸發 hook(~/.claude/hooks/xxx)→ hook 呼叫 `codeisland-bridge`,把 JSON 從 stdin 餵它 → bridge 連 `/tmp/codeisland-<uid>.sock` → `HookServer` 讀進 JSON,解析後丟給 `AppState` → `AppState` 更新 `@Published`,SwiftUI 重繪 `NotchPanelView`。
- [x] 使用者按 [Allow] 後,Claude 怎麼知道?
  → `AppState.respondToPermission(...)` 把決定寫回 socket(bridge 那端還在 blocking read 等著)→ bridge 依回應 exit code → hook 把 exit code 回給 Claude Code → Claude 繼續跑(或中止)。
- [x] App 關掉時,使用者跑 Claude Code 會發生什麼?
  → bridge 連 socket 失敗 → exit 0(fail open)→ Claude 照常跑,只是瀏海沒通知。
- [ ] 如果 socket 檔案被誤刪,app 會自動恢復嗎?(還沒測,`HookServer` 裡有重建邏輯但我沒驗過真刪 socket 的情境)

---

## 今日(2026-04-18)真正碰過的修改範圍筆記

- 新增 zh-Hant:改 `L10n.swift` 加字典、改 `SettingsView` picker
- 全站 typography + a11y:`SettingsView.swift` 加 `settingsTitle()`/`settingsDesc()` helper、Form 底 `.font(size: 14)` cascade、14 個 Section 轉 explicit header form 上色
- Rebrand(顯示名稱層):`Info.plist` CFBundleName、`build.sh` 拆 APP_NAME/BINARY_NAME、`SettingsView` 側欄 + About、`StatusItemController` tooltip、`L10n.swift` 裡所有語系字串
- 不動的(避免破壞既有使用者):CFBundleIdentifier、Swift target name `CodeIsland`、binary name `CodeIsland`、hook script 裡的 `# CodeIsland hook` 標記、`~/.codeisland/` 檔名
- 新 app icon:從 Xcode 26 `AppIcon.icon` composer 換成傳統 `AppIcon.appiconset`(7 個 PNG 尺寸)
- 新 in-app logo:`AppLogoView` 從 Canvas 手繪改讀 `AboutLogo`/`NotchLogo` imageset
- build-dmg.sh:補 ad-hoc 簽章分支、對齊新的 asset catalog 路徑
