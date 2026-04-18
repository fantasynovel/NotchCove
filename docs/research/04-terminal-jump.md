# 黑盒 4:「跳回那個 Terminal Tab」魔法怎麼做到的?

> **狀態**:🟡 Draft(預填已知資訊,待親手實驗)
> **對應 Phase**:4.75 — 逆向工程
> **最後更新**:[實驗完填日期]

---

## 這個黑盒是什麼?

你開 10 個 terminal tab,其中一個在跑 Claude Code。瀏海 UI 顯示「這個 session 需要審批」,你點一下──**螢幕直接切到那個特定 tab**。

這背後是兩層魔法:

1. 怎麼操控 terminal 切換 tab / 視窗?
2. 怎麼**認出**「我要切換到哪個 tab」?

---

## 為什麼這是黑盒?

- macOS 沒有「跳到指定 terminal tab」的統一 API
- 每個 terminal app(iTerm2、Ghostty、cmux、VS Code terminal)作法完全不同
- 「Claude session 跟 terminal tab 的對應關係」沒有天然綁定,要想辦法建立

---

## 白話解釋

### 問題 A:怎麼「操控」別的 app?

macOS 內建一個自動化協定叫 **AppleScript**。你可以寫 AppleScript,**命令另一個 app** 做事:

```applescript
tell application "iTerm2"
    activate
    -- 切換到某個 tab...
end tell
```

大部分有做事功能的 app 都支援 AppleScript(叫 scripting dictionary)。

### 問題 B:怎麼「認出」目標 tab?

兩種思路:

**思路 1:比對工作目錄(cwd)**

Claude session 知道自己的 working directory(你在哪個資料夾啟動它)。你問 terminal:「你的哪個 tab 現在在 `/Users/you/projects/foo`?」,找到就切過去。

**思路 2:讀 process 的環境變數**

如果 Claude 跑在特殊的 shell 環境(例如 cmux workspace),那個環境會設特定的環境變數(如 `CMUX_WORKSPACE_ID`)。App 可以讀 Claude process 的環境,拿到這個 ID,直接叫 cmux 切換。

MioIsland 對 cmux 就是這種做法,**比 cwd 比對更精準**。

---

## 各 terminal 的支援方法(整理表)

| Terminal | 操控方式 | 認 tab 的方法 | 能做到的精度 |
|---|---|---|---|
| iTerm2 | AppleScript 豐富 | `session.path` 變數(cwd) | Tab 級 ✅ |
| Ghostty | AppleScript 有限 | Working directory | Window 級 |
| cmux | cmux CLI | `CMUX_WORKSPACE_ID` env var | Workspace 級 ✅ |
| Terminal.app | AppleScript | tty / cwd | Tab 級 ✅ |
| WezTerm | CLI (`wezterm cli`) | Pane ID | Pane 級 ✅ |
| Alacritty | 不支援 AppleScript | 沒辦法認 tab | 只能 activate app |
| Warp | 不支援 AppleScript | 沒辦法認 tab | 只能 activate app |
| VS Code | URL scheme `vscode://` | Folder path | 檔案級 |
| Cursor | URL scheme | Folder path | 檔案級 |
| Zed | URL scheme | Folder path | 檔案級 |
| Kitty | `kitty @ focus-tab` | Tab title | Tab 級 |
| Hyper | 不支援 AppleScript | 沒辦法 | 只能 activate |

---

## 實驗 A:親手跑 AppleScript

### 準備

打開一個 iTerm2,在裡面:

```bash
cd /tmp
```

### 另開任一 terminal,跑這個

```bash
osascript <<'EOF'
tell application "iTerm2"
    activate
    repeat with w in windows
        repeat with t in tabs of w
            set s to current session of t
            set p to variable of s named "session.path"
            log "Found tab with cwd: " & p
            if p contains "/tmp" then
                select t
                return "Switched!"
            end if
        end repeat
    end repeat
    return "Not found"
end tell
EOF
```

你的 iTerm2 應該會切到剛剛那個 `/tmp` tab。

[親手實驗後填] 觀察:
- 成功切換嗎?
- 有多個在 `/tmp` 的 tab 時會怎樣?
- 你平常用的 terminal(Ghostty/WezTerm)類似作法嗎?

---

## 實驗 B:看 Claude Code 的 process 環境

Claude Code 跑起來時會有一些環境變數。開個 Claude session:

```bash
# Terminal 裡
claude
```

**另開** terminal:

```bash
# 找 claude process 的 PID
pgrep -fl claude

# 讀它的環境變數(macOS 用 ps -E)
ps -E -p <PID>
# 或用 launchctl(比較新)
# 或寫個 C 程式讀 /proc(macOS 沒 /proc,這招不能用)
```

[親手實驗後填]
```
看到的環境變數:
  CLAUDE_... = ...
  CMUX_... = ...(如果你用 cmux)
  [其他]
```

這些 env var 就是「認 process 對應到 tab」的線索。

---

## 實驗 C:iTerm2 的 scripting dictionary

```bash
# 開啟 AppleScript Editor(macOS 內建)
open -a "Script Editor"
```

選單:**File → Open Dictionary → iTerm2** → 選 Open。

這會打開 iTerm2 **所有可用的 AppleScript 指令**清單。

[親手實驗後填] 最重要的指令:
- `select` of `tab` — 切換到 tab
- `current session` of `tab` — 拿到 session 物件
- `variable` of `session` named `X` — 讀 iTerm 的 session 變數

### iTerm2 常用 session variables

- `session.path`:當前工作目錄
- `session.name`:tab 的名稱
- `session.hostname`:host 名稱(判斷 SSH)
- `session.tty`:tty 路徑

[親手實驗後填] 你發現的其他 variables:
- ...

---

## 實驗 D:VS Code 的 URL scheme

VS Code 支援這種 URL:

```bash
# 打開專案
open "vscode://file/Users/you/projects/foo"

# 打開特定檔案
open "vscode://file/Users/you/projects/foo/main.swift"

# 打開特定行
open "vscode://file/Users/you/projects/foo/main.swift:42"
```

這是 VS Code(跟 Cursor/Zed 家族)的標準協定。你的 app 要跳 VS Code 就用 `NSWorkspace.shared.open(url)`。

---

## 實驗 E:看 CodeIsland / MioIsland 的實作

```bash
cd ~/Projects/my-island/Sources
grep -rn "osascript\|NSAppleScript\|tell application" --include="*.swift"
grep -rn "vscode://\|cursor://\|zed://" --include="*.swift"
grep -rn "CMUX_\|workspace" --include="*.swift"
```

[親手實驗後填] 你觀察到的:
```
iTerm2 實作:[貼 code 片段或檔案路徑]
Ghostty 實作:...
cmux 實作:...
VS Code 實作:...
```

---

## 實作核心邏輯(規劃)

你的 `TerminalJumper` 大致會這樣長:

```swift
enum TerminalType {
    case iterm2, ghostty, terminalApp, cmux
    case vsCode, cursor, zed, jetbrains
    case wezterm, alacritty, kitty
    case unknown
}

struct SessionContext {
    let cwd: String              // 工作目錄
    let pid: pid_t?              // Claude process ID
    let envVars: [String: String]? // 環境變數(如果讀得到)
}

class TerminalJumper {
    func jump(to context: SessionContext) {
        let terminalType = detectTerminal(pid: context.pid)
        switch terminalType {
        case .iterm2:
            jumpIterm2(cwd: context.cwd)
        case .cmux:
            if let wsId = context.envVars?["CMUX_WORKSPACE_ID"] {
                jumpCmux(workspaceId: wsId)
            }
        case .vsCode:
            openVSCode(path: context.cwd)
        // ...
        case .unknown:
            activateFrontmostTerminal()  // 降級方案
        }
    }

    private func jumpIterm2(cwd: String) {
        let script = """
        tell application "iTerm2"
            activate
            repeat with w in windows
                repeat with t in tabs of w
                    set s to current session of t
                    if (variable of s named "session.path") is "\(cwd)" then
                        select t
                        return
                    end if
                end repeat
            end repeat
        end tell
        """
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }

    private func jumpCmux(workspaceId: String) {
        let task = Process()
        task.launchPath = "/usr/local/bin/cmux"
        task.arguments = ["focus", "--workspace", workspaceId]
        try? task.run()
    }
}
```

---

## 偵測使用者目前在哪個 terminal

這是「不打擾」功能的基礎 — 如果使用者已經在看那個 tab,不要 popup。

```swift
// 讀當前 focus 的 app
let frontmostApp = NSWorkspace.shared.frontmostApplication
let bundleID = frontmostApp?.bundleIdentifier
// 例如 "com.googlecode.iterm2" / "com.mitchellh.ghostty"
```

進階:還要讀那個 app 當前 tab 是不是我們的目標 session。這要每個 terminal 單獨處理。

---

## 常見坑

1. **AppleScript 要權限**
   - 第一次跑會跳「允許 MyIsland 控制 iTerm2?」
   - 使用者拒絕就永遠不能用
   - 在 `Info.plist` 加 `NSAppleEventsUsageDescription` 說明原因

2. **Session path 不一定是 Claude 的 cwd**
   - 使用者可能後來 cd 到別的目錄
   - 比對時要同時考慮「session 啟動時」和「當前」的 path

3. **多個 tab 在同個 cwd**
   - 比對 cwd 會找到很多個
   - 用進階條件:找包含 `claude` process 的那個 tab

4. **SSH 遠端連線**
   - tab 顯示的 cwd 是遠端的
   - 你的 app 如果想追 remote 要先想清楚 scope

5. **AppleScript 很慢**
   - 一次查詢 iTerm2 所有 windows/tabs 可能要 100ms+
   - 快取結果,不要每次點擊都重跑

---

## 我的實作優先順序

先支援最多人用的,不要一次做全部:

- [ ] P0(必做):iTerm2 + Terminal.app(內建)
- [ ] P1(重要):Ghostty + VS Code URL scheme
- [ ] P2(加分):cmux + WezTerm
- [ ] P3(邊緣):Kitty + Alacritty(沒 AppleScript 只能 activate)
- [ ] 不支援(告知使用者):Hyper、Warp

---

## 延伸學習資源

- [Apple — AppleScript Language Guide](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/)
- [iTerm2 AppleScript 文件](https://iterm2.com/documentation-scripting.html)
- [VS Code URL scheme 官方文件](https://code.visualstudio.com/docs/getstarted/settings#_working-with-the-command-line)

---

## 完成檢核

- [ ] 實驗 A 跑成功:osascript 能切換 iTerm2 tab
- [ ] 實驗 B 完成:知道 Claude Code process 有哪些 env vars
- [ ] 實驗 C 完成:看過 iTerm2 的 scripting dictionary
- [ ] 實驗 D 完成:VS Code URL scheme 試過
- [ ] 實驗 E 完成:看懂主 repo 的 TerminalJumper 邏輯
- [ ] 能列出各 terminal 的支援精度
- [ ] 知道 `Info.plist` 要加哪個 UsageDescription
