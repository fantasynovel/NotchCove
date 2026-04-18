# 我理解的架構(My Island)

> **這份筆記給誰看?**:只給我自己看的草稿版本。正式對外的架構文件在 `docs/architecture.md`(那個還沒寫,等我真的懂了再寫)。
>
> **怎麼用?**:Phase 4 讀完 CodeIsland 的 code 後,**用我自己的話**把我理解的資料流寫下來。寫不出來就是我沒懂。
>
> **最後更新**:[填日期]

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

**檔案**:`Sources/CodeIsland/App.swift`(或類似,[實際確認])

**做的事**:
- App 啟動時的 bootstrap
- 建立 menu bar icon(如果有)
- 建立瀏海 overlay
- 註冊 hook(第一次啟動)

---

### 2. SessionManager

**檔案**:[實際確認路徑,例如 `Sources/CodeIsland/Services/SessionManager.swift`]

**角色**:整個 app 的「狀態中心」,SwiftUI 的所有 View 都 observe 它。

**維護的資料**:
- 目前有哪些 active session
- 每個 session 的狀態(idle / working / needs approval / done)
- 每個 session 對應的 agent type、terminal type、cwd

```swift
// 預期結構
class SessionManager: ObservableObject {
    @Published var sessions: [Session] = []
    func handleEvent(_ event: HookEvent) { ... }
    func respondToPermission(sessionID: String, allow: Bool) { ... }
}
```

---

### 3. SocketReceiver(名稱可能不同)

**檔案**:[實際確認]

**角色**:監聽 `/tmp/codeisland-xxx.sock`,把進來的 JSON 轉成 `HookEvent`,通知 SessionManager。

---

### 4. HookInstaller

**檔案**:[實際確認]

**角色**:
- 第一次啟動時,把 hook 腳本 install 到 `~/.claude/hooks/` 或改 `~/.claude/settings.json`
- 移除 app 時提供 uninstall 機制
- 處理 Claude Code 更新後 hook 檔案可能壞掉

---

### 5. Bridge CLI

**檔案**:`Sources/codeisland-bridge/` 或類似

**角色**:
- 這是一個**獨立的 executable**,被 hook 呼叫
- 讀 stdin(Claude 傳的 JSON)
- 連 socket,把 JSON 轉發給主 app
- 讀 socket 回應,依回應 exit

**為什麼要獨立 CLI?**:hook 指令必須是一個可執行檔,不能直接呼叫 Swift 函式。

---

### 6. NotchPanel(UI)

**檔案**:[實際確認,可能叫 `NotchWindow`、`IslandPanel`、`OverlayPanel`]

**角色**:
- 繼承 NSPanel
- 常駐瀏海位置
- 收合狀態顯示 icon,展開顯示 session list

---

### 7. TerminalJumper

**檔案**:[實際確認]

**角色**:使用者點「跳回 terminal」時,用 AppleScript / CLI 切換到對應 tab。

---

## 我還不懂的地方

[填寫中發現看不懂的部分]

- [ ] ...
- [ ] ...

**策略**:每個「不懂的地方」→ 開個 research note 或實驗去搞懂。

---

## 關鍵設計決策(我猜的)

### 為什麼要用 Unix socket 不用別的?

我的理解:[用自己的話寫]

### 為什麼要把 bridge 獨立成 CLI?

我的理解:[用自己的話寫]

### Hook 為什麼 fail open?

我的理解:[用自己的話寫]

### 為什麼 UI 用 SwiftUI 不用純 AppKit?

我的理解:[用自己的話寫]

---

## Phase 4 驗收:我能用自己的話解釋這些嗎?

- [ ] 當我在 terminal 按下 Enter 送出 prompt,到瀏海跳出通知,中間發生了哪些事?
- [ ] 使用者按 [Allow] 後,Claude 怎麼知道?
- [ ] App 關掉時,使用者跑 Claude Code 會發生什麼?
- [ ] 如果 socket 檔案被誤刪,app 會自動恢復嗎?
