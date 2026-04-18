# 黑盒 2:Claude Code Hook Protocol

> **狀態**:🟡 Draft(預填已知資訊,待親手實驗)
> **對應 Phase**:4.75 — 逆向工程
> **最後更新**:[實驗完填日期]

---

## 這個黑盒是什麼?

Claude Code CLI 在執行過程中,有特定時刻會「通知」外部程式。例如:
- 要執行 Bash 指令前 → 給使用者機會阻止
- 對話結束 → 讓外部系統做收尾
- 使用者送出訊息 → 可以做 log

這個通知機制叫 **hook**。你寫一個腳本,註冊在 `~/.claude/settings.json`,Claude 遇到那個時刻就呼叫你的腳本。

---

## 最關鍵的三個問題

1. 一共有哪些事件?各自什麼時候觸發?
2. 每個事件傳給 hook 的 JSON 長怎樣?
3. Hook 怎麼「影響」Claude Code?(例如拒絕執行、要求重試)

---

## 已知的事件類型(2025-2026 基準)

> ⚠️ Claude Code 版本會改,以實驗觀察為準。

| 事件 | 觸發時機 | 常見用途 |
|---|---|---|
| `PreToolUse` | Tool 執行「前」 | 權限審批、log |
| `PostToolUse` | Tool 執行「後」 | 通知完成、分析結果 |
| `UserPromptSubmit` | 使用者送出訊息 | 記錄 prompt、觸發外部系統 |
| `Stop` | 對話結束(Claude 不再回應) | 送通知、整理 session |
| `SubagentStop` | 子 agent 結束 | 進階用途 |
| `Notification` | Claude 主動發通知(需要輸入時) | 提示使用者 |
| `SessionStart` | Session 開始 | 初始化、註冊 |
| `SessionEnd` | Session 結束 | 清理 |

---

## Hook 設定的 JSON 格式

`~/.claude/settings.json` 裡大致長這樣:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",   // 只對 Bash tool 觸發,空字串 = 所有 tool
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/your/script.sh"
          }
        ]
      }
    ],
    "PostToolUse": [...]
  }
}
```

- `matcher`:正則或 tool 名稱,空字串表所有 tool
- 一個事件可以有多個 hook,依序執行

---

## Hook 腳本收到什麼?

Claude 會透過 **stdin** 把事件資料(JSON)丟給你的腳本。

### PreToolUse 事件範例(預測結構)

```json
{
  "session_id": "abc-123-uuid",
  "tool_name": "Bash",
  "tool_input": {
    "command": "ls -la",
    "description": "List files"
  },
  "cwd": "/Users/you/project"
}
```

[親手實驗後填] 真實 JSON:
```json
[貼一個你實際攔截到的 PreToolUse JSON]
```

### PostToolUse 事件範例(預測結構)

```json
{
  "session_id": "abc-123-uuid",
  "tool_name": "Bash",
  "tool_input": { ... },
  "tool_response": {
    "stdout": "...",
    "stderr": "...",
    "exit_code": 0
  }
}
```

[親手實驗後填] 真實 JSON:
```json
[貼一個你實際攔截到的 PostToolUse JSON]
```

### 其他事件

[親手實驗後填]

---

## Hook 怎麼「回應」Claude?

三種回應機制,從簡單到複雜:

### 方法 1:Exit Code

最簡單。腳本結束時用不同 exit code:

- `exit 0` → 正常結束,Claude 繼續
- `exit 2` → **阻止**這次 tool call(會把 stderr 內容顯示給 Claude 看)
- 其他非零 → 通常也當失敗處理

### 方法 2:Stdout 輸出 JSON 決定

更強大。Hook 可以輸出結構化 JSON:

```bash
#!/bin/bash
# 拒絕某個危險指令
input=$(cat)  # 讀 stdin
if echo "$input" | grep -q "rm -rf /"; then
    echo '{"decision":"block","reason":"Dangerous command detected"}'
    exit 0
fi
```

[親手實驗後填] 其他可用的 decision 值:
- `"block"`:確認可用
- `"approve"`:[實驗看看]
- `[其他值]`

### 方法 3:阻塞式互動(CodeIsland 的做法)

Hook **不要馬上 return**,而是:
1. 把事件丟給常駐 app(透過 socket)
2. 等 app 顯示 UI、使用者決定
3. 決定結果回傳給 hook
4. Hook 依結果 exit

這樣使用者可以在 GUI 裡按 Allow/Deny,而不是寫死在腳本裡。

---

## 實驗 A:架設「完全攔截器」

這個實驗會記錄 Claude Code 傳給 hook 的每一個事件。

### 步驟 1:備份原設定

```bash
cp ~/.claude/settings.json ~/.claude/settings.json.backup
```

### 步驟 2:建立攔截目錄和腳本

```bash
mkdir -p ~/claude-hook-research/events

cat > ~/claude-hook-research/log-everything.sh <<'EOF'
#!/bin/bash
# 攔截所有 hook 事件,儲存到檔案
EVENT_NAME="${1:-unknown}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S_%N")
FILE="${HOME}/claude-hook-research/events/${TIMESTAMP}_${EVENT_NAME}.json"
cat > "$FILE"
# 靜默 exit,不影響 Claude
exit 0
EOF

chmod +x ~/claude-hook-research/log-everything.sh
```

### 步驟 3:註冊所有事件

```bash
# 生成攔截設定
USER_PATH="$HOME/claude-hook-research/log-everything.sh"
cat > ~/.claude/settings.json <<EOF
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "", "hooks": [{"type": "command", "command": "${USER_PATH} PreToolUse"}]}
    ],
    "PostToolUse": [
      {"matcher": "", "hooks": [{"type": "command", "command": "${USER_PATH} PostToolUse"}]}
    ],
    "UserPromptSubmit": [
      {"matcher": "", "hooks": [{"type": "command", "command": "${USER_PATH} UserPromptSubmit"}]}
    ],
    "Stop": [
      {"matcher": "", "hooks": [{"type": "command", "command": "${USER_PATH} Stop"}]}
    ],
    "SessionStart": [
      {"matcher": "", "hooks": [{"type": "command", "command": "${USER_PATH} SessionStart"}]}
    ]
  }
}
EOF
```

### 步驟 4:用 Claude Code 做幾件事

```bash
claude
```

然後在 Claude 裡試:
- 叫它跑一個 Bash 指令
- 問它一個問題
- 退出對話

### 步驟 5:分析攔截到的資料

```bash
cd ~/claude-hook-research/events
ls -la

# 看每個 JSON
for f in *.json; do
    echo "=== $f ==="
    cat "$f" | jq .
    echo ""
done
```

### 步驟 6:**一定要還原!**

```bash
cp ~/.claude/settings.json.backup ~/.claude/settings.json
```

或如果你要把 CodeIsland 的 hook 加回來,先跑 CodeIsland:
```bash
open ~/Projects/my-island/.build/debug/CodeIsland.app
# CodeIsland 會自動把自己的 hook 加回 settings.json
```

---

## 實驗 B:測試「拒絕」機制

### 寫一個永遠拒絕 Bash 的 hook

```bash
cat > ~/claude-hook-research/always-deny-bash.sh <<'EOF'
#!/bin/bash
echo "Denied by research script" >&2
echo '{"decision":"block","reason":"Research: testing denial"}'
exit 2
EOF
chmod +x ~/claude-hook-research/always-deny-bash.sh
```

設成只對 Bash 觸發:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/你/claude-hook-research/always-deny-bash.sh"
          }
        ]
      }
    ]
  }
}
```

跑 Claude,叫它跑任何 Bash 指令。

**[親手實驗後填]** 觀察:
- Claude 的反應?(訊息長怎樣?)
- Exit code 2 vs 1 的差別?
- `{"decision":"block"}` vs 沒輸出 JSON 的差別?

---

## 實驗 C:閱讀 CodeIsland 的 hook 腳本

```bash
# CodeIsland 跑過後,它的 hook 會在哪
cat ~/.claude/hooks/*.sh 2>/dev/null

# 或 settings 裡直接指向 binary
jq '.hooks' ~/.claude/settings.json
```

[親手實驗後填] CodeIsland 的 hook 做什麼?
```
[貼你看到的 script 或 binary 路徑]
```

觀察重點:
- 它是 shell script 還是 compiled binary?
- 它怎麼「把 stdin 轉給 app」?
- 它有做權限阻塞(方法 3)嗎?

---

## 我的實作計劃

做自己的 app 時:

- [ ] 寫一個 `HookInstaller` 類別負責安裝/移除 hooks
  - [ ] 安裝時先備份 `settings.json`
  - [ ] 移除時還原備份
- [ ] 寫一個 `HookScript` 的 template(shell 或 Swift CLI 都行)
  - [ ] 讀 stdin 的 JSON
  - [ ] 透過 socket 丟給主 app
  - [ ] 等 app 回應
  - [ ] 依回應 exit
- [ ] 主 app 收到事件後,有 routing 邏輯分派給對應 UI component
- [ ] 處理邊界情況:
  - [ ] App 沒開 → hook 應 fail open(exit 0,讓 Claude 繼續)
  - [ ] Socket 連不上 → 同樣 fail open
  - [ ] App 太慢回應 → 設 timeout(5 秒?),timeout 後 fail open

---

## 常見坑

1. **fail open 還是 fail closed?**
   - fail open:app 壞掉不要擋 Claude → 使用者體驗好,但失去 permission 的意義
   - fail closed:app 壞掉就擋住 → 安全但煩
   - CodeIsland 選 fail open,我也建議

2. **Hook 執行時間長會拖慢 Claude**
   - 不要在 hook 裡做重操作
   - 跟 app 的互動要非同步、設 timeout

3. **matcher 空字串的行為**
   - 空字串 = 所有 tool
   - 但有些版本可能需要寫 `.*` 才行,實驗看看

4. **多個 hook 註冊同一事件**
   - 會依序執行,任一個 exit 2 就整個阻止?還是只阻止自己?
   - [親手實驗後填]

---

## 延伸學習資源

- [Claude Code Hooks — 官方文件](https://docs.claude.com/en/docs/claude-code/hooks)(Anthropic 官方,但不完整)
- CodeIsland 的 hook 實作(主骨架)
- claude-island 的 hook 實作(Apache 2.0,可抄)

---

## 完成檢核

- [ ] 實驗 A 成功:攔截並看到 5 種以上事件的 JSON
- [ ] 實驗 B 成功:能用 hook 拒絕 Claude 執行指令
- [ ] 實驗 C 完成:讀懂 CodeIsland 的 hook 做法
- [ ] 把 `~/.claude/settings.json` 還原到正常狀態
- [ ] 能解釋 fail open / fail closed 的取捨
- [ ] 知道 exit code、stdout JSON、阻塞三種回應方式各自的適用場景
