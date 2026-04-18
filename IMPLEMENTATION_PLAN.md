# 打造你自己的 Notch Island App — 實作計劃

> **起點**:fork [wxtsky/CodeIsland](https://github.com/wxtsky/CodeIsland)(MIT License)
> **目標**:換品牌、加 agent/終端整合、加 iPhone 同步
> **程度設定**:Swift 新手,每步附完整指令,可貼著做
> **預估時間**:全部做完約 4–8 週的晚上時間(看你每晚投入多久)

---

## 目錄

- [Phase 0 — 心理建設與概念地圖](#phase-0)
- [Phase 1 — 環境準備](#phase-1)
- [Phase 2 — Fork 與第一次 Build](#phase-2)
- [Phase 3 — Swift 最小必備速成](#phase-3)
- [Phase 4 — 理解 CodeIsland 架構](#phase-4)
- [Phase 4.5 — 參考專案使用指南](#phase-4-5)
- [Phase 4.75 — 逆向工程:拆解 5 個技術黑盒](#phase-4-75)
- [Phase 5 — 換品牌(UI/名字)](#phase-5)
- [Phase 6 — 擴充 Agent 或終端整合](#phase-6)
- [Phase 7 — iPhone 同步架構](#phase-7)
- [Phase 8 — 打包、簽章、發佈](#phase-8)
- [Phase 9 — 長期維護](#phase-9)
- [附錄 A — 除錯手冊](#附錄-a)
- [附錄 B — 有用指令速查](#附錄-b)

---

<a id="phase-0"></a>
## Phase 0 — 心理建設與概念地圖

### 你要做的東西長這樣

```
┌─────────────────────────────────────────────────────────┐
│  MacBook 瀏海                                           │
│  ┌──────┐                                               │
│  │ 🐱 ✨│  ← 你的 app 會住在這裡                        │
│  └──────┘                                               │
│                                                         │
│  展開後會變成一個浮動面板,顯示:                        │
│  ┌─────────────────────────────┐                        │
│  │ Claude Code session #1      │                        │
│  │ ▸ 正在執行 Bash             │                        │
│  │ [Allow] [Deny]              │                        │
│  └─────────────────────────────┘                        │
└─────────────────────────────────────────────────────────┘
```

### 這個 App 怎麼運作(高層次)

```
      你的 terminal 裡跑著           你的 Mac 上的 app
  ┌─────────────────────┐      ┌─────────────────────────┐
  │ Claude Code         │      │                         │
  │ 要執行一個 tool call│──┐   │  ┌───────────────────┐  │
  │ 會先觸發 hook       │  │   │  │ 瀏海 UI           │  │
  └─────────────────────┘  │   │  │  ↑ 即時顯示事件   │  │
                           │   │  └───────────────────┘  │
                           └──▶│  監聽 Unix socket       │
                               │  /tmp/codeisland.sock   │
                               └─────────────────────────┘
```

- **Hook**:Claude Code 支援的事件鉤子(有 `PreToolUse`、`PostToolUse`、`Stop` 等)
- **Unix socket**:Mac 上的本機「管道」,像個無名檔案讓不同程式講話
- **瀏海 UI**:用 SwiftUI 畫的視窗,定位在瀏海區域

**不懂也沒關係**,後面 Phase 4 會再講一次。

### 三個差異化目標的依賴關係

你選了三件事,要按這個順序做不然會互相擋:

```
  換品牌/UI ──▶ 加 agent 整合 ──▶ iPhone 同步
   (簡單)       (中等)           (最難,需要有 server)
   1–3 天        1–2 週           2–4 週
```

**建議**:前兩個做完再碰 iPhone。iPhone 需要開 Apple Developer 帳號、寫後端、搞 APNs,如果前面就卡住會很挫折。

---

<a id="phase-1"></a>
## Phase 1 — 環境準備

### 1.1 檢查你的 Mac

```bash
sw_vers
```

你應該看到類似 `ProductVersion: 14.x` 或 `15.x`。**CodeIsland 需要 macOS 14 以上**,低於就沒辦法。

### 1.2 安裝 Xcode

1. 打開 **App Store** → 搜尋 **Xcode** → 安裝(約 10GB,會跑很久)
2. 裝完第一次打開,會要你同意授權 → 按 Agree
3. 在 terminal 跑:
   ```bash
   xcode-select --install
   xcodebuild -version
   ```
   看到 `Xcode 15.x` 或更新代表 OK。

### 1.3 安裝 Homebrew(如果還沒有)

```bash
# 看看有沒有
which brew
```

沒有就跑:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 1.4 安裝開發工具

```bash
brew install git gh swiftlint swiftformat jq
```

- `git`、`gh`:版本控制 + GitHub CLI
- `swiftlint`、`swiftformat`:Swift 程式碼風格檢查
- `jq`:debug JSON 會用到

### 1.5 設定 GitHub

```bash
gh auth login
```

照提示選 `GitHub.com` → `HTTPS` → `Login with a web browser`,把跳出的代碼貼進瀏覽器。

### 1.6 裝個 GUI 編輯器(可選但推薦)

Xcode 寫程式 OK,但看架構用 VS Code 比較舒服:

```bash
brew install --cask visual-studio-code
code --install-extension sswg.swift-lang
```

### ✅ 驗收

```bash
sw_vers && xcodebuild -version && brew --version && git --version && gh auth status
```

五個都有輸出,沒紅字。

---

<a id="phase-2"></a>
## Phase 2 — Fork 與第一次 Build

### 2.1 Fork CodeIsland 到你的帳號

**用 GitHub CLI 最快**:

```bash
# 先想好你的專案英文名(全小寫,建議用連字號),例如:
# - my-island
# - dev-notch
# - agentbar
# 假設你決定叫 my-island,下面會用這個當範例

cd ~
mkdir -p Projects && cd Projects

gh repo fork wxtsky/CodeIsland --clone --fork-name my-island
cd my-island
```

這個指令會:
1. 在 GitHub 上把 wxtsky/CodeIsland fork 到你帳號,名字改成 `my-island`
2. 把 fork 下來的版本 clone 到 `~/Projects/my-island`

### 2.2 看看檔案結構

```bash
ls -la
```

應該看到:
```
LICENSE          ← MIT license,要保留這個檔案
README.md
README.zh-CN.md
Package.swift    ← Swift 的「package.json」,定義依賴和 target
Info.plist       ← macOS app 的 metadata(名字、版本、權限)
build.sh         ← 打包腳本
Sources/         ← 所有 Swift 程式碼
docs/
logo.svg
.gitignore
```

### 2.3 第一次 Build(什麼都先別改)

```bash
swift build
```

第一次會跑比較久(下載依賴、編譯)。看到 `Build complete!` 就成功。

**跑起來看看**:
```bash
open .build/debug/CodeIsland.app
```

- 如果 macOS 跳「無法驗證開發者」,去 **系統設定 → 隱私權與安全性** → 底下找到被擋的 app → 點「仍要打開」
- 看瀏海區域應該有東西出現了

**⚠️ 注意**:這時候點進去它可能會試著安裝 hook 到你的 `~/.claude/settings.json`。如果你在用 Claude Code 的正式環境,先備份:

```bash
cp ~/.claude/settings.json ~/.claude/settings.json.backup
```

### 2.4 保留 MIT License 的正確做法(**很重要,不要跳過**)

MIT license 允許你閉源,但**要求你保留原作者版權聲明**。做法:

```bash
# 1. 看原 LICENSE 內容
cat LICENSE
```

你會看到類似:
```
MIT License

Copyright (c) 2025 wxtsky
...
```

**絕對不要刪掉或改掉** `Copyright (c) 2025 wxtsky`。

**正確做法**:多加一行你自己的:

```
MIT License

Copyright (c) 2025 wxtsky
Copyright (c) 2026 [你的名字或 handle]

Permission is hereby granted, free of charge, to any person obtaining a copy
...
```

用編輯器打開 `LICENSE`,在原 `Copyright` 下面加你自己的就好。

### 2.5 第一次 commit

```bash
git add LICENSE
git commit -m "chore: add my copyright notice to LICENSE"
git push
```

### ✅ 驗收

- [ ] `swift build` 成功
- [ ] App 能打開,瀏海有東西
- [ ] LICENSE 保留了原作者 + 加了你的
- [ ] GitHub 上看到 `Copyright` 更新那筆 commit

---

<a id="phase-3"></a>
## Phase 3 — Swift 最小必備速成

你不需要精通 Swift,但以下這些概念看到不能慌。**每個花 5 分鐘讀一次就夠**。

### 3.1 變數

```swift
var name = "Claude"        // 可改,像 JS 的 let
let version = "1.0"        // 不可改,像 JS 的 const
let count: Int = 5         // 加型別標註
```

### 3.2 Optional(最容易卡的)

Swift 嚴格區分「可能是 nil」跟「一定不是 nil」。

```swift
let a: String = "hello"    // 一定有
let b: String? = nil       // 可能有可能沒有,叫 Optional

// 從 b 取值要「解開」
if let unwrappedB = b {
    print(unwrappedB)      // 這裡 unwrappedB 保證不是 nil
}

// 或用 ?? 給預設值
let result = b ?? "default"
```

看到 `?` 就是 Optional,看到 `!` 就是「我保證不是 nil 強制解開」(出錯會 crash)。

### 3.3 函式

```swift
func greet(name: String) -> String {
    return "Hello, \(name)"    // \(xxx) 是字串插值
}

let msg = greet(name: "World")   // 呼叫時參數名通常要寫出來
```

### 3.4 Class vs Struct

```swift
// struct:值型別,複製一份
struct Point {
    var x: Int
    var y: Int
}

// class:參考型別,共用同一個
class Session {
    var id: String = ""
    var status: String = "idle"
}
```

SwiftUI 的 View 都是 struct,app 狀態通常是 class。

### 3.5 SwiftUI 最核心概念

```swift
import SwiftUI

struct MyView: View {          // View 永遠是 struct
    @State var count = 0        // @State:本地狀態,改變時 UI 自動重畫

    var body: some View {       // body 回傳 UI 內容
        VStack {                // 垂直排列
            Text("Count: \(count)")
            Button("加一") {
                count += 1
            }
        }
    }
}
```

**關鍵 property wrapper**(看到記得是什麼就好):
- `@State`:本地簡單狀態(Int、String 這種)
- `@StateObject`:本地複雜物件(Class)
- `@ObservedObject`:從外面傳進來的物件
- `@Published`:class 裡面要通知 UI 的屬性
- `@Binding`:父給子的「雙向繫結」

### 3.6 Async / Await

```swift
func fetchData() async throws -> String {
    // 會等待非同步操作
    let data = try await URLSession.shared.data(from: url)
    return String(data: data.0, encoding: .utf8) ?? ""
}

// 呼叫
Task {
    let result = try await fetchData()
    print(result)
}
```

### ✅ 驗收

不要求你會寫,**看到以上語法能認出來就好**。卡住時隨時回來查。

**推薦補充資源**(都是官方 / 業界標準):
- Apple 的 [Swift Tour](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/guidedtour/) — 1 小時讀完
- [100 Days of SwiftUI](https://www.hackingwithswift.com/100/swiftui) 前 10 天 — 如果你想更紮實

---

<a id="phase-4"></a>
## Phase 4 — 理解 CodeIsland 架構

改任何東西前,先搞懂它怎麼運作。**這 Phase 不寫 code,只讀**。

### 4.1 走一遍目錄

```bash
cd ~/Projects/my-island
tree Sources -L 3
```

沒裝 `tree` 先 `brew install tree`。

你會看到類似(實際可能略有差異):
```
Sources/
├── CodeIsland/            ← 主 app
│   ├── App.swift          ← 進入點
│   ├── AppDelegate.swift  ← app 生命週期
│   ├── Views/             ← SwiftUI 畫面
│   ├── Models/            ← 資料結構
│   ├── Services/          ← 商業邏輯(socket、hook 管理)
│   └── Resources/         ← 圖片、sound
└── codeisland-bridge/     ← hook 呼叫的 CLI binary
```

### 4.2 讀這幾個關鍵檔案(新手先讀 signature 和 comment,不用讀懂每行)

**優先順序**:

1. `Package.swift` — 先看這個,了解有幾個 target、有哪些依賴
2. `Sources/CodeIsland/App.swift` — app 進入點
3. `Sources/CodeIsland/Services/` 裡面關於 socket / hook 的檔案 — 這是整個 app 的核心
4. `Sources/codeisland-bridge/main.swift`(或類似)— 了解 hook 怎麼把訊息丟給 app

```bash
# 用 VS Code 開整個專案
code .

# 或在 Xcode 開
open Package.swift
```

### 4.3 畫一張你自己的心智圖

開個新檔 `docs/my-notes/architecture.md`,用自己的話寫下你理解的資料流:

```bash
mkdir -p docs/my-notes
```

```markdown
# 我理解的資料流(自己寫)

1. Claude Code 要執行 `Bash` tool
2. 觸發 `~/.claude/hooks/pre_tool_use.sh`(或類似)
3. Hook 執行 codeisland-bridge,把 JSON 資料丟給它
4. bridge 把 JSON 透過 Unix socket 丟到 `/tmp/codeisland-XXX.sock`
5. 我的 app 監聽這個 socket,收到後:
   - 更新 SessionManager(Swift class)的 @Published 屬性
   - SwiftUI 瀏海 View 因為 @ObservedObject 自動重畫
6. 使用者按 Allow/Deny 後:
   - View 呼叫 SessionManager 的函式
   - 函式透過 socket 寫回 bridge
   - bridge 用特定 exit code 回應 hook
   - Claude Code 收到決定,繼續執行或取消
```

不用寫得很精準,**寫的過程會強迫你讀懂**。

### 4.4 動手實驗:看 hook 長什麼樣

```bash
# 第一次執行 app 時它裝的 hook
cat ~/.claude/settings.json | jq '.hooks'
```

應該看到一些 `PreToolUse`、`PostToolUse` 之類的條目,指向 `~/.claude/hooks/xxx.sh`(或類似)。

```bash
# 實際 hook 腳本
cat ~/.claude/hooks/*.sh  # 看你裝了什麼
```

### 4.5 跑實況除錯

```bash
# 終端 1:跑你的 app 並看 log
swift run 2>&1 | tee /tmp/my-island.log

# 終端 2:用 Claude Code 做點事,觀察 log
# 你應該能看到 hook event 的蹤跡
```

### ✅ 驗收

- [ ] 能在 `docs/my-notes/architecture.md` 用自己的話寫出資料流
- [ ] 知道 hook 裝在哪、socket 檔案在哪
- [ ] 改變一個 Claude Code 的行為時,log 裡看得到事件

---

<a id="phase-4-5"></a>
## Phase 4.5 — 參考專案使用指南

在動手改之前,先搞清楚其他幾個同類專案怎麼用。**用錯方式會害你的 codebase license 被污染,或浪費時間抄錯邏輯**。

### 4.5.1 三類參考專案與各自定位

你手上有四個可以參考的 repo,但**只有一個是主骨架**,其他三個是不同用途的「靈感庫」:

| 專案 | License | 角色 | 你可以做什麼 |
|---|---|---|---|
| **wxtsky/CodeIsland** | MIT | 🏗️ **主骨架** | 所有程式碼都建立在這之上 |
| **farouqaldori/claude-island** | Apache 2.0 | 📘 **原型參考** | 複製程式碼、抄架構,只要保留 NOTICE |
| **Octane0411/open-vibe-island** | GPL v3 | 🔍 **只看不抄** | 讀架構設計、讀 docs,**絕對不複製程式碼** |
| **MioMioOS/MioIsland** | CC BY-NC 4.0 | 🔍 **只看不抄** | 看截圖和 README 找 UX 靈感,**絕對不複製程式碼** |

這個分類背後的邏輯,下面逐一說明。

---

### 4.5.2 為什麼有些「只能看不能抄」?

你的專案是 MIT(從 wxtsky/CodeIsland 繼承來的),意思是你保有閉源/商用/重新授權的彈性。一旦你複製了不相容 license 的程式碼,整個 codebase 就被綁定:

**GPL v3 的污染路徑**:
```
  你 copy 一個 function 從 open-vibe-island
              ↓
  這個 function 就是 GPL v3
              ↓
  包含它的整個 binary 都變成 GPL v3
              ↓
  你散佈 app 就必須開源全部程式碼
              ↓
  你原本想保留的閉源/商用彈性 = 沒了
```

**CC BY-NC 4.0 的污染路徑**:
```
  你 copy 一段 code 從 MioIsland
              ↓
  那段 code 禁止商業使用
              ↓
  你整個 app 不能賣錢、不能放進付費產品
              ↓
  甚至連靠 sponsorship / Patreon 都有法律風險
```

**Apache 2.0(claude-island)比較友善**:
- 可以直接 copy 程式碼進你的 MIT 專案
- 只要在 `NOTICE` 檔或 LICENSE 裡聲明哪些部分來自 Apache 2.0、保留原 copyright
- 你的整體 license 可以維持 MIT(或自選)

**結論**:
- 🟢 claude-island → 可以 copy,記得加 NOTICE
- 🔴 open-vibe-island → 只看設計,不 copy code
- 🔴 MioIsland → 只看 UX,不 copy code

---

### 4.5.3 「只看不抄」具體該怎麼做?(clean-room 原則)

法律上有個概念叫 **clean-room implementation**:看別人的想法(想法不受著作權保護),但用自己的方式重寫程式碼。

**✅ 可以做**:
- 讀 README、docs、architecture 文件
- 讀程式碼的 commit message 和 issue 討論
- 看截圖理解 UX 是怎麼運作的
- 把你讀到的東西**用自己的話**寫在筆記裡
- 看完後**關掉那個 repo**,隔一天再動手寫自己的版本

**❌ 不能做**:
- 複製程式碼片段,即使只是一個 function
- 邊看邊寫,逐行抄寫後改變數名
- 把整個檔案下載下來「參考著改」
- 把 GPL / NC 的 code 丟進 AI 叫它「重寫」(AI 產出仍可能保留結構性相似)

**實務建議工作流**:

```bash
# 當你想「這個功能 MioIsland 是怎麼做的?」
mkdir -p docs/my-notes/research

# 開新分頁看 MioIsland,邊看邊用自己的話記
cat > docs/my-notes/research/mioisland-buddy-system.md <<'EOF'
# MioIsland 的 Buddy 系統(我觀察到的)

## 外觀
- 16x16 pixel art
- 顯示在 session list 每個 row
- 會根據狀態切換表情(idle / working / error)

## 猜測的技術
- 應該是從 Claude Code 的 ~/.claude.json 讀 buddy 資料
- 用 Bun.hash + Mulberry32 生成種子
- 可能是 Canvas 或 SwiftUI Shape 繪製

## 我的實作方向(不 copy 他們的)
- 先不要 copy,先自己看 Claude Code buddy 的原始碼
- 用 SF Symbols + 動畫做個陽春版
- 之後再考慮 pixel art
EOF
```

**一個具體的例子**:

❌ 錯誤做法:
```
開 MioIsland 的 BuddyView.swift → 複製 200 行 → 改改變數名 → 你的 BuddyView.swift
```
這就污染了,不管你改了多少變數名。

✅ 正確做法:
```
1. 看 MioIsland 的 BuddyView 畫面與行為(不看 code)
2. 讀他們的 README 描述
3. 關掉那個視窗
4. 開 docs/my-notes/buddy-plan.md 用自己的話寫「我想做什麼」
5. 從 Apple 官方文件查 SwiftUI 怎麼做那件事
6. 自己從零寫
```

---

### 4.5.4 Apache 2.0 專案(claude-island)的正確抄法

這個可以大方 copy,但有義務:

**Step 1**:在你的專案根目錄建立 `NOTICE` 檔:

```bash
cat > NOTICE <<'EOF'
My Island
Copyright (c) 2026 [你的名字]

This product includes software developed by wxtsky
(https://github.com/wxtsky/CodeIsland), licensed under MIT.

Portions of this software are derived from claude-island
by farouqaldori (https://github.com/farouqaldori/claude-island),
licensed under Apache License 2.0.
EOF
```

**Step 2**:在 copy 過來的檔案開頭加 header:

```swift
// Originally from claude-island (github.com/farouqaldori/claude-island)
// Licensed under Apache License 2.0
// Modified by [你的名字] in 2026
```

**Step 3**:如果你改了程式碼,依 Apache 2.0 第 4 條要標註「修改了什麼」:
```swift
// Modified: 2026-04-18 — adapted for multi-agent event routing
```

**Step 4**:把 Apache 2.0 的全文放到 `LICENSES/Apache-2.0.txt`(附屬 license 資料夾是好習慣)。

---

### 4.5.5 這幾個專案各自最值得學什麼

**farouqaldori/claude-island — 最小可用原型**
- 看它怎麼用**最少的程式碼**做出瀏海 UI、hook、permission approval
- 適合你在 Phase 4 理解「最小核心」是什麼
- 914 stars、23 個 commit,所以 code 量小、容易讀通
- **對你最有用的檔案**:App 進入點、SessionManager、NotchView

**Octane0411/open-vibe-island — 架構設計**
- 讀 `docs/architecture.md` 就好,**不要讀程式碼**
- 它有完整的 hook protocol 設計、bridge server 設計
- 學它怎麼分層(App / Core / HooksCLI / BridgeServer 四個 target)
- 學 SSH remote 偵測的思路
- **對你最有用的資源**:它 repo 裡的 `docs/` 資料夾(純文件,沒有 code 污染風險)

**MioMioOS/MioIsland — UX 與產品靈感**
- 看它的 marketing 截圖、產品網站
- 看它的 plugin marketplace 怎麼運作(對 Phase 9 後期有啟發)
- 看它的 iOS 配套 app(Code Light)UX 設計
- **對你最有用的素材**:README 裡的功能表格、示範截圖、WeChat 社群經營方式

---

### 4.5.6 一個實戰場景範例

假設你做到 Phase 6,要加 Cursor 的整合,不知道怎麼開始:

```
1. 先看 wxtsky/CodeIsland 自己 repo 的 Cursor 實作(主骨架已支援)
   → 你已經是它的 fork,直接讀 Sources/ 裡的相關檔案

2. 如果發現 wxtsky 的實作有缺陷(例如不支援 workspace jump)
   → 開 claude-island(Apache 2.0)看有沒有更好的做法
   → 有就 copy 過來,加 NOTICE

3. 如果 claude-island 也沒有
   → 開 open-vibe-island 看它 docs 怎麼描述 Cursor 整合
   → 關掉視窗,用自己的話寫計劃,自己寫 code

4. 最後卡在 UX 設計(button 要放哪、icon 顏色)
   → 開 MioIsland 看截圖找靈感
   → 自己重新設計
```

---

### 4.5.7 建立你的「參考 repo」本地資料夾(可選)

如果你常常要讀這幾個 repo 的 docs,先 clone 一份到本地查方便:

```bash
mkdir -p ~/Projects/references
cd ~/Projects/references

# 這三個都 clone(但不是要 build,只是要讀)
git clone https://github.com/farouqaldori/claude-island.git
git clone https://github.com/Octane0411/open-vibe-island.git
# MioMioOS/MioIsland 的 code 你不會 copy,clone 只是方便看 docs
git clone https://github.com/MioMioOS/MioIsland.git

# 給自己的提醒
cat > README.md <<'EOF'
# 參考專案

## ⚠️ 注意事項

- claude-island (Apache 2.0) — 可以 copy 程式碼,記得加 NOTICE
- open-vibe-island (GPL v3) — 只讀 docs/,不 copy code!
- MioIsland (CC BY-NC 4.0) — 只看截圖找 UX 靈感,不 copy code!

如果你要做的功能在後兩者有參考,先用自己的話寫計劃,
至少隔一天再回到主 repo 實作,避免不小心抄到結構。
EOF
```

把這個資料夾加進你主 repo 的 `.gitignore`(如果你 clone 在主 repo 內的話),避免不小心 commit 進去。

---

### ✅ 驗收

- [ ] 理解四個 repo 各自的角色(主骨架 / 可抄 / 只看 docs / 只看 UX)
- [ ] 知道為什麼 GPL 和 NC 不能 copy
- [ ] `NOTICE` 檔已建立(等到真的 copy Apache 2.0 code 時再填內容)
- [ ] 有一個地方可以看到這些 repo 的 docs(本地 clone 或網頁收藏)
- [ ] 把這個 Phase 4.5 的內容也寫進自己的 `docs/my-notes/references.md`,自己再複述一次

---

<a id="phase-4-75"></a>
## Phase 4.75 — 逆向工程:拆解 5 個技術黑盒

### 為什麼要做這個 Phase?

到目前為止,你對這套系統的理解都是「看別人怎麼做」。但**「照著抄」和「真的懂」差很多**:

- 照著抄 → 改一點就出 bug,不知道為什麼壞
- 真的懂 → 可以改任何東西,甚至做別人沒做的功能

**逆向工程**(reverse engineering)聽起來很玄,其實就是:**拿到一個已經做好的東西,把它拆開看裡面怎麼運作**。像小時候拆遙控器、拆手錶那樣。

這 Phase 我們拆 5 個「黑盒子」。每個黑盒都會:
1. 白話解釋它是什麼、為什麼是黑盒
2. 給你實驗步驟,讓你親自驗證它怎麼運作
3. 告訴你拆完能得到什麼技能

**這 Phase 做完,後面每個 Phase 都會快很多**。

### 準備:建立你的研究筆記庫

```bash
cd ~/Projects/my-island
mkdir -p docs/research
```

每個黑盒拆完都寫一份筆記到 `docs/research/`。這些筆記會是你**最寶貴的資產**,比 code 還值錢——因為 code 會改、筆記會留下來。

---

### 🔬 黑盒 1:App 怎麼「住」在瀏海裡?

#### 這是什麼?
瀏海(notch)就是 MacBook 螢幕頂部那塊黑色凹槽(放相機的地方)。macOS **沒有官方功能**讓 app 住在瀏海裡,但 CodeIsland / MioIsland 做到了。這是怎麼辦到的?

#### 為什麼是黑盒?
- Apple 官方文件根本不講這件事
- 不同 MacBook 型號瀏海大小不一樣(Air M2、Pro 14、Pro 16 各不同)
- 外接螢幕沒瀏海,怎麼「降級」?

#### 白話講大概怎麼做
1. App 建立一個**「浮動視窗」**(類似小工具那種,不是正常 app 視窗)
2. 把視窗**強制放到螢幕最上層**(比選單列還高的層級)
3. 用**程式畫一個和瀏海一樣形狀的遮罩**蓋上去
4. 偵測你的螢幕型號 → 查表拿到那台 MacBook 的瀏海尺寸 → 對齊

#### 怎麼驗證(實際動手)

**實驗 A:看看它用什麼視窗類型**

```bash
cd ~/Projects/my-island/Sources
grep -rn "NSPanel\|NSWindow\|windowLevel\|screenSaver" --include="*.swift" | head -20
```

你會看到類似:
```swift
let panel = NSPanel(...)
panel.level = .screenSaver    // ← 這就是「強制放到最上層」
panel.isFloatingPanel = true  // ← 浮動視窗
panel.backgroundColor = .clear // ← 透明背景
```

記下來你觀察到的:

```bash
cat > docs/research/01-notch-positioning.md <<'EOF'
# 黑盒 1:App 怎麼住在瀏海裡

## 我觀察到的技術

1. 用了 `NSPanel` 而不是 `NSWindow`
   - NSPanel 是「面板」,比一般視窗更輕量
2. `windowLevel = .screenSaver`
   - 這個層級比選單列、Dock 都高
3. 背景透明 → 看起來像是瀏海本身在變化

## 下一個問題
- 怎麼偵測螢幕有沒有瀏海?
- 瀏海寬度怎麼抓?
EOF
```

**實驗 B:找螢幕瀏海尺寸的偵測邏輯**

```bash
grep -rn "safeAreaInsets\|auxiliaryTopLeftArea\|notch\|NSScreen" Sources/ --include="*.swift" | head -20
```

macOS 14 後有個 API 叫 `NSScreen.safeAreaInsets`,會告訴你螢幕的「安全區」(避開瀏海的範圍)。如果 top inset > 0,代表有瀏海。

```swift
// 你應該會看到類似
if let screen = NSScreen.main {
    let topInset = screen.safeAreaInsets.top  // 瀏海高度
    // 通常是 38 或 42,看機型
}
```

**實驗 C:瀏海寬度硬編碼還是動態抓?**

```bash
grep -rn "notchWidth\|notch.*200\|notch.*180" Sources/ --include="*.swift"
```

很多 app 其實是**查表的**:根據螢幕解析度或 Mac 型號,去查預設寬度。原因是 macOS 沒直接給你「瀏海寬度」這個 API。

#### 拆完你學到什麼
- 如何創建「住在特殊位置」的浮動視窗
- 如何偵測螢幕硬體特徵
- 如何處理「各種機型尺寸不同」這種碎片化問題

#### 自己實驗的進階題
如果你想更深入,試試看:
```bash
# 把你的 Mac 接外接螢幕,跑 app
# 觀察 app 行為——它應該會「降級」到螢幕頂部中央
# 拔掉外接螢幕,看它會不會自動回到瀏海
# 筆記到 docs/research/01-notch-positioning.md
```

---

### 🔬 黑盒 2:Claude Code 的 Hook 到底怎麼溝通?

#### 這是什麼?
Claude Code 會在某些時刻「通知外部程式」——例如要執行 Bash 指令前、執行完後、整個對話結束時。這個「通知」機制叫 **hook**。

CodeIsland 就是用這些 hook 接收事件、顯示在瀏海。

#### 為什麼是黑盒?
- Anthropic 的官方文件寫了 hook 機制,但**沒寫 JSON 裡每個欄位是什麼**
- 不同事件(Tool use 前、Tool use 後、對話結束)傳的資料不一樣
- 怎麼「回覆」Claude Code(例如拒絕 permission)?有點玄學

#### 白話講大概怎麼做

```
1. 你在 ~/.claude/settings.json 註冊 hook
   告訴 Claude:"當發生 X 事件時,執行我這個腳本"

2. Claude Code 遇到該事件時
   執行你的腳本,把事件資料透過 stdin(標準輸入)丟給你

3. 你的腳本接收事件後
   可以:
   - 直接結束(什麼都不做)
   - 輸出訊息到 stdout(Claude 可能會看)
   - 用特定 exit code 告訴 Claude 「拒絕」或「通過」
```

**最厲害的是 PermissionRequest**:Claude 問「我可以跑 Bash 嗎?」時,hook 可以**卡住**讓使用者決定,決定後再讓 Claude 繼續。

#### 怎麼驗證(實際動手)

**實驗 A:攔截真實事件**

寫一個「攔截器」腳本,把 Claude Code 傳給 hook 的所有內容都記下來:

```bash
# 先備份原本的 hooks 設定
cp ~/.claude/settings.json ~/.claude/settings.json.backup

# 寫一個攔截腳本
mkdir -p ~/claude-hook-research
cat > ~/claude-hook-research/log-everything.sh <<'EOF'
#!/bin/bash
# 把 stdin 內容連同時間戳記下來
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
EVENT_NAME="${1:-unknown}"
cat > ~/claude-hook-research/events/${TIMESTAMP}_${EVENT_NAME}.json
# 原樣 pass-through(不影響 Claude 正常運作)
EOF
chmod +x ~/claude-hook-research/log-everything.sh
mkdir -p ~/claude-hook-research/events
```

接著**暫時修改** `~/.claude/settings.json`,把所有 hook 都指到這個腳本:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/你的username/claude-hook-research/log-everything.sh PreToolUse"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/你的username/claude-hook-research/log-everything.sh PostToolUse"
          }
        ]
      }
    ]
  }
}
```

用 Claude Code 做點事,然後:

```bash
ls ~/claude-hook-research/events/
# 應該看到一堆 JSON 檔
cat ~/claude-hook-research/events/*.json | jq .
```

**你會看到真實的 hook JSON 長什麼樣**,有哪些欄位。

**實驗 B:測 exit code 的效果**

寫一個永遠「拒絕」的 hook:

```bash
cat > ~/claude-hook-research/always-deny.sh <<'EOF'
#!/bin/bash
echo '{"decision":"block","reason":"research test"}'
exit 2
EOF
chmod +x ~/claude-hook-research/always-deny.sh
```

設到 `PreToolUse`,用 Claude Code 叫它跑指令,觀察反應。

**實驗 C:看 CodeIsland 的 hook 腳本做什麼**

```bash
# 研究完上面,還原你的 settings
cp ~/.claude/settings.json.backup ~/.claude/settings.json

# 打開 CodeIsland 讓它重新裝 hook
open ~/Projects/my-island/.build/debug/CodeIsland.app

# 看它的 hook 腳本
cat ~/.claude/hooks/*.sh  # 或其他路徑
# 或
jq '.hooks' ~/.claude/settings.json
```

你會發現它的 hook **就是把 stdin 丟給一個 Unix socket**(下個黑盒會講)。

#### 筆記要寫什麼

```bash
cat > docs/research/02-hook-protocol.md <<'EOF'
# 黑盒 2:Claude Code Hook Protocol

## 事件類型(從實驗觀察到的)

| 事件名 | 觸發時機 | JSON 重點欄位 |
|---|---|---|
| PreToolUse | Tool 執行前 | tool_name, tool_input, session_id |
| PostToolUse | Tool 執行後 | tool_name, tool_input, tool_response |
| Stop | 對話結束 | session_id |
| UserPromptSubmit | 使用者送出訊息 | prompt |

## Permission 控制流程

1. Claude 想跑 Bash → 觸發 PreToolUse hook
2. Hook 可以:
   - exit 0 → 放行
   - exit 2 + JSON → 拒絕
   - 阻塞等待(透過 socket 問使用者)

## CodeIsland 的做法
- Hook script 是個薄殼
- 真正邏輯是把 stdin 透過 socket 丟給 app
- App 顯示 UI 讓使用者決定
- 決定透過 socket 回傳 → exit code 傳給 Claude
EOF
```

#### 拆完你學到什麼
- Claude Code 事件系統的完整 schema(會幫你做多 agent 整合超省時)
- 如何寫 hook 攔截任何 Claude 行為
- Permission flow 的完整邏輯,之後你想做更進階的權限管理(例如白名單、自動批准某些指令)就有底氣

---

### 🔬 黑盒 3:Unix Socket——兩個程式怎麼對話?

#### 這是什麼?
「你的 App」和「Hook 腳本」是兩個**完全不同的程式**。Hook 腳本跑一下就結束了,你的 App 要長時間跑著。它們怎麼互傳訊息?

答案:**Unix socket**(Unix 網域通訊端)。

#### 為什麼是黑盒?
聽起來很專業,其實就是:**一個假裝成檔案的「管道」,兩邊都可以往裡面寫東西、讀東西**。

#### 白話講是怎麼回事

想像一個**傳話筒**:

```
  Hook 腳本                 管道                    App
  (寫入)      ────────▶  /tmp/xxx.sock  ◀────────  (讀取)
              "Claude 要跑 Bash"                    收到後顯示在瀏海

  Hook 腳本                 管道                    App
  (讀取)    ◀────────   /tmp/xxx.sock   ────────▶  (寫入)
            "拒絕!"                                 使用者按了 Deny
```

**為什麼不用網路 socket(TCP)?** 因為:
1. Unix socket **只在本機有效**,不會被外人連進來
2. 更快(不用經過網路協定堆疊)
3. 可以用「檔案權限」保護(只有你的使用者能讀寫)

#### 怎麼驗證(實際動手)

**實驗 A:看 socket 檔案長怎樣**

先確保 App 在跑,然後:

```bash
# 找所有 socket 檔
ls -la /tmp/*.sock
# 你應該看到 codeisland-XXXX.sock

# 注意檔案類型是 "s"(socket),不是一般檔案 "-"
# srwx------  1 you staff  0 Apr 18 10:00 /tmp/codeisland-501.sock
```

**實驗 B:手動跟 socket 對話**

用 `nc`(netcat)可以直接跟 socket 互動:

```bash
# 開一個終端,讀 socket 的訊息
nc -U /tmp/codeisland-$(id -u).sock
```

然後用 Claude Code 做點事,觸發 hook。**你應該會看到 hook 傳來的 JSON 在這個 nc 裡跳出來**——因為你「截胡」了。

⚠️ 注意:這樣做會打斷 App 的正常運作,實驗完殺掉 nc。

**實驗 C:寫個自己的 echo 伺服器**

這是學 socket 最快的方法——自己寫一個:

```bash
# Python 版,寫在 ~/test-socket/server.py
mkdir ~/test-socket && cd ~/test-socket
cat > server.py <<'EOF'
import socket, os
path = "/tmp/test-echo.sock"
if os.path.exists(path):
    os.unlink(path)
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.bind(path)
s.listen()
print(f"Listening on {path}")
while True:
    conn, _ = s.accept()
    data = conn.recv(1024)
    print(f"Received: {data.decode()}")
    conn.send(b"echo: " + data)
    conn.close()
EOF

# 跑起來
python3 server.py &

# 另一個終端
echo "hello" | nc -U /tmp/test-echo.sock
# 會看到 "echo: hello"

# 記得清理
kill %1
rm /tmp/test-echo.sock
```

恭喜,你剛剛就自己做了一個 App 跟 Hook 之間的**傳話筒**。CodeIsland 做的本質上就是這樣,只是訊息內容更結構化。

#### 筆記要寫什麼

```bash
cat > docs/research/03-unix-socket.md <<'EOF'
# 黑盒 3:Unix Socket 通訊

## 概念
- 像「假裝成檔案的管道」
- 兩個程式透過同一個檔案路徑對話
- 只在本機有效,比 TCP 快

## CodeIsland 的實作
- Socket 檔位置:/tmp/codeisland-{UID}.sock
- UID 是使用者 ID,多使用者不會打架
- 訊息格式:JSON(從黑盒 2 學來的 schema)

## 權限控制
- 檔案 mode 應該是 600(只有 owner 可讀寫)
- 不然其他使用者可以偽造事件

## 斷線處理
- App 重啟會刪掉舊 socket 檔
- Hook 遇到 socket 不存在 → 應該「失敗靜默」(fail open)
  不要讓 app 沒開就擋住 Claude Code 運作
EOF
```

#### 拆完你學到什麼
- Unix socket 的概念和使用
- 為何「本機兩個程式對話」要用 socket 不用檔案或網路
- App 和 CLI 協作的通用模式(很多 macOS app 都是這樣)

---

### 🔬 黑盒 4:「跳回那個 Terminal Tab」魔法怎麼做到的?

#### 這是什麼?
你有 10 個 terminal tab 開著,其中一個在跑 Claude Code。App 的瀏海裡看到這個 session 需要你處理,點一下——**螢幕直接切到那個 tab**。這是怎麼做到的?

#### 為什麼是黑盒?
- iTerm2、Ghostty、Terminal.app、VS Code 的 terminal 各自完全不同
- macOS 沒有統一的「切換到指定 tab」API
- 特別詭異的是:怎麼知道「這個 Claude session」對應「哪個 tab」?

#### 白話講是怎麼回事

有兩個問題要解:

**問題 A:怎麼操控 terminal 切換 tab?**
→ 用 **AppleScript**(macOS 內建的自動化語言,可以遠端遙控其他 app)

**問題 B:怎麼知道哪個 tab 對應這個 Claude session?**
→ 最可靠的方法是**比對「工作目錄」**(working directory)
- 你在 `~/projects/foo` 開 terminal 跑 Claude
- Claude session 記錄了 cwd = `~/projects/foo`
- App 問 iTerm2:「你的哪個 tab 現在在 `~/projects/foo`?」
- iTerm2 回報 → App 命令它切過去

#### 怎麼驗證(實際動手)

**實驗 A:親手用 AppleScript 遙控 iTerm2**

打開一個 iTerm2(或 Terminal.app,都行):

```bash
# 在這個 terminal 裡 cd 到一個特別的目錄
cd ~/Documents
```

另開一個 terminal 或在 Script Editor(macOS 內建)跑:

```applescript
tell application "iTerm2"
    activate
    set allWindows to windows
    repeat with w in allWindows
        repeat with t in tabs of w
            repeat with s in sessions of t
                if variable of s named "session.path" contains "Documents" then
                    select s
                    return "Found!"
                end if
            end repeat
        end repeat
    end repeat
end tell
```

**實際**也可以用 `osascript` 從 shell 跑:

```bash
osascript <<'EOF'
tell application "iTerm2"
    activate
end tell
EOF
```

**實驗 B:看 CodeIsland 怎麼寫 AppleScript**

```bash
grep -rn "osascript\|NSAppleScript\|tell application" Sources/ --include="*.swift" | head
```

你應該會看到類似:
```swift
let script = """
tell application "iTerm2"
    ...
end tell
"""
let appleScript = NSAppleScript(source: script)
appleScript?.executeAndReturnError(nil)
```

**實驗 C:用 Ghostty 和 cmux 研究更進階的作法**

MioIsland 對 cmux 特別強,它用的是 **環境變數**:

```bash
# cmux 啟動的 Claude 會有這些環境變數
ps -E -p $(pgrep claude) 2>/dev/null | head
# 看得到 CMUX_WORKSPACE_ID=xxx CMUX_SURFACE_ID=yyy
```

App 就是讀這些變數,知道「這個 Claude process 對應哪個 cmux workspace」。**這個技巧很巧妙**——不靠 AppleScript,靠 process 本身的 environment variables。

#### 筆記要寫什麼

```bash
cat > docs/research/04-terminal-jump.md <<'EOF'
# 黑盒 4:Terminal 精確跳回

## 兩個核心問題

1. 怎麼操控 terminal? → AppleScript
2. 怎麼認出是哪個 tab? → 比對工作目錄 or 環境變數

## 各 terminal 支援程度

| Terminal | 操控方法 | 認 tab 方法 | 支援精度 |
|---|---|---|---|
| iTerm2 | AppleScript | session.path 變數 | Tab 級 |
| Ghostty | AppleScript | working directory | Window 級 |
| cmux | cmux 指令 | CMUX_WORKSPACE_ID env | Workspace 級 |
| Terminal.app | AppleScript | tab 的 tty | 一般 |
| VS Code | URL scheme (vscode://) | folder path | 檔案級 |
| Warp | 只能 activate | 認不出 tab | App 級 |

## 實作核心邏輯(我的版本規劃)

```swift
func jumpToSession(session: Session) {
    guard let cwd = session.workingDirectory else { return }

    switch session.terminalType {
    case .iterm2:
        runAppleScript(itermJumpScript(cwd: cwd))
    case .cmux:
        // 讀 process 的 env vars 找 workspace
        let wsId = readEnvVar("CMUX_WORKSPACE_ID", pid: session.pid)
        shell("cmux jump --workspace \(wsId)")
    // ...
    }
}
```

## 失敗處理
- 找不到對應 tab → 只 activate terminal app
- Terminal 已關閉 → 提示使用者
EOF
```

#### 拆完你學到什麼
- AppleScript 的基本用法(macOS 自動化很多地方會用)
- 如何「對應 process 到 UI 元素」這種跨程式問題
- 環境變數當作 process 辨識的技巧

---

### 🔬 黑盒 5:macOS 權限迷宮

#### 這是什麼?
你的 App 要做一些「敏感」操作:
- 寫檔到 `~/.claude/` 目錄(需要檔案權限)
- 跳到某個 terminal tab(需要 Accessibility 權限)
- 顯示通知(需要通知權限)
- 讀其他 process 的環境變數(可能需要額外權限)

macOS 對這些全部都有嚴格的權限管控,**處理不好 app 就不能用**。

#### 為什麼是黑盒?
- 每種操作需要什麼權限,Apple 沒一個清單
- 權限一旦使用者拒絕,**很難再問一次**
- 簽章(signed)和未簽章 app 的權限行為不一樣
- MioIsland 還特別提到:「Accessibility 權限跟 app 的 signed path 綁定,Debug 重編會失效」——這是什麼鬼?

#### 白話講是怎麼回事

macOS 的權限邏輯:

```
1. App 嘗試做敏感事(例如讀其他 app 的視窗)
      ↓
2. macOS 檢查:你這個 app 有沒有權限?
      ↓
3. 沒有 → 跳對話框問使用者「要不要允許?」
      ↓
4. 使用者選允許 → macOS 記下來「這個 app 有這個權限」
      ↓
5. 「這個 app」用什麼認? → 用 app 的 bundle ID + 簽章指紋
      ↓
6. 下次開 → 不用問,直接允許
```

**問題來了**:你在開發時 Swift 每 build 一次產生的 app 「指紋」可能略不同,macOS 會覺得「這是不同的 app」,權限全部要重新問。

MioIsland 的解法:**強制把 app 複製到 `/Applications/` 那個固定路徑,用那個版本跑,權限就不會漏失**。

#### 怎麼驗證(實際動手)

**實驗 A:看 CodeIsland 要哪些權限**

```bash
# 看 Info.plist 裡的權限宣告
grep -A1 "UsageDescription" Info.plist

# 應該有類似
# <key>NSAccessibilityUsageDescription</key>
# <string>Need to control terminal windows to jump to sessions</string>
```

每個 `XxxUsageDescription` 都是一個權限請求,字串是給使用者看的理由。

**實驗 B:實際看權限設定**

```bash
# 系統設定 → 隱私權與安全性 → 輔助使用
# 應該看到你的 CodeIsland 在清單裡
```

或用指令:

```bash
# 這指令會列出 TCC(隱私權資料庫)裡有哪些 app 註冊了哪些權限
# 但 macOS 保護得很嚴,只能部分讀取
sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT service, client FROM access" 2>/dev/null
# 通常會沒權限讀,沒關係,去系統設定看
```

**實驗 C:重現「Debug 重編失去權限」的坑**

```bash
# 1. 第一次 build 並跑
swift build
open .build/debug/CodeIsland.app
# 允許所有權限

# 2. 改一行 code、重 build
echo "// comment" >> Sources/某個檔.swift
swift build
open .build/debug/CodeIsland.app
# 可能權限對話框又出現了!

# 這就是 MioIsland 提到的問題
```

**實驗 D:看 CodeIsland 怎麼檢查權限**

```bash
grep -rn "AXIsProcessTrusted\|requestAccess\|authorizationStatus" Sources/ --include="*.swift"
```

你會看到類似:
```swift
import ApplicationServices

func hasAccessibilityPermission() -> Bool {
    return AXIsProcessTrusted()  // ← 有 Accessibility 權限嗎?
}

func requestAccessibilityPermission() {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    AXIsProcessTrustedWithOptions(options)  // ← 跳對話框請求
}
```

#### 筆記要寫什麼

```bash
cat > docs/research/05-macos-permissions.md <<'EOF'
# 黑盒 5:macOS 權限迷宮

## 我的 app 需要哪些權限?

| 權限 | 做什麼用 | Info.plist key | 檢查 API |
|---|---|---|---|
| Accessibility | 控制 terminal 視窗 | NSAccessibilityUsageDescription | AXIsProcessTrusted() |
| Automation | AppleScript 控制其他 app | NSAppleEventsUsageDescription | 自動跳對話框 |
| Notifications | 顯示通知 | 沒有 key,用 code 請求 | UNUserNotificationCenter |
| File access | ~/.claude/ 讀寫 | 通常不需特別授權 | - |

## 開發時的坑

- Debug 重編會改變 signature → 權限失效
- 解法:固定用 /Applications/MyIsland.app 跑開發版
  - 寫個 install.sh:swift build && cp -R .build/debug/MyIsland.app /Applications/
  - Launch /Applications 版本測試

## 使用者第一次跑的流程

1. 下載 .dmg → 拖到 Applications
2. 打開 → macOS 擋:"未識別的開發者"
   - 解法:右鍵 → 開啟 或 xattr -dr com.apple.quarantine
3. 跳權限對話框(Accessibility)
   - 我的 app 要處理「使用者拒絕」的情況
4. 允許後才能使用所有功能

## 最佳實踐

- 啟動時檢查所有需要的權限
- 缺權限不要直接 crash,顯示提示畫面
- 提供「打開系統設定」按鈕(用 URL scheme)
  - x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility
EOF
```

#### 拆完你學到什麼
- macOS 的權限模型(TCC)
- 為什麼 app 要簽章、簽章影響什麼
- 如何優雅處理「使用者拒絕權限」
- 開發期間如何避免權限 reset

---

### Phase 4.75 總結:你現在擁有的能力

拆完 5 個黑盒,你已經能:

| 能力 | 靠哪個黑盒 |
|---|---|
| 做瀏海浮動視窗 | 黑盒 1 |
| 接收、解讀、回應 Claude hook 事件 | 黑盒 2 |
| 寫 CLI ↔ App 的本機通訊 | 黑盒 3 |
| 跨 app 自動化(跳 tab、控制其他軟體) | 黑盒 4 |
| 處理 macOS 所有權限 | 黑盒 5 |

**這 5 個加起來,就是一個瀏海類 app 的全部技術地基**。你現在不只是「會改 CodeIsland」,而是「知道整類 app 怎麼做」。

### ✅ 驗收

- [ ] `docs/research/` 裡有 5 個黑盒的筆記
- [ ] 每個黑盒你都能**用自己的話**跟朋友講清楚
- [ ] 至少做完一個「實驗 A」(親手驗證)
- [ ] 把原本 `~/.claude/settings.json` 還原(別讓研究用的攔截器影響正常使用)

### 卡關了怎麼辦?

如果某個黑盒你看不懂,**跳過**。先把後面的 Phase 做完,有實戰經驗後再回來看會突然通。

但**黑盒 2(Hook)和黑盒 3(Socket)是後面一定會用到的**,這兩個至少要懂原理。

---

<a id="phase-5"></a>
## Phase 5 — 換品牌(UI/名字)

這是最簡單也最有成就感的 phase,做完會覺得「這真是我的 app 了」。

### 5.1 想好你的名字與識別

在 `docs/my-notes/` 開 `brand.md` 填:
```markdown
- App 名(給使用者看):My Island
- Bundle ID:com.你的handle.myisland
- 程式碼 class 前綴(如果有):MI
- 主色:#FF6B6B(或其他)
- 次色:#4ECDC4
- 目標 logo 風格:極簡幾何 / 像素 / 手繪 之一
```

**Bundle ID 很重要,一旦發佈不要再改**,會影響使用者的設定遷移。

### 5.2 建立你的分支工作流

從現在開始,每個大改動都開分支:

```bash
git checkout -b feat/rebrand
```

### 5.3 改專案顯示名

**檔案**:`Info.plist`

找到 `CFBundleName` 和 `CFBundleDisplayName`,改成你的名字:

```xml
<key>CFBundleName</key>
<string>My Island</string>
<key>CFBundleDisplayName</key>
<string>My Island</string>
```

**檔案**:`Package.swift`

找到 `name: "CodeIsland"` 之類的,改成 `"MyIsland"`(程式碼識別字不要有空格)。

### 5.4 改 Bundle ID

```bash
# 全專案搜一下原本的 bundle ID
grep -rn "com.wxtsky" . --include="*.plist" --include="*.swift" --include="*.pbxproj" 2>/dev/null
```

把每一處都換成你的 `com.你的handle.myisland`。**用 VS Code 的全域搜尋取代最快**。

### 5.5 換 logo 和 icon

**最低限度**:換掉 `logo.svg`,以及 `Sources/.../Resources/Assets.xcassets/AppIcon.appiconset/` 裡的圖檔。

如果你不會做 icon,可以:
- [Bakery](https://apps.apple.com/app/bakery/id1575220747) — macOS 上免費的 icon 產生器
- [IconKitchen](https://icon.kitchen/) — 網頁版,上傳一張圖就能產生各尺寸

macOS icon 需要的尺寸:16、32、64、128、256、512、1024,每個還要 @1x 和 @2x。IconKitchen 會一次產給你。

```bash
# 產完後丟進資料夾覆蓋原檔
cp ~/Downloads/icon_export/* Sources/CodeIsland/Resources/Assets.xcassets/AppIcon.appiconset/
```

### 5.6 改主題色

找主畫面 SwiftUI 檔案(通常在 `Sources/.../Views/`),搜尋 `Color(` 或 `.accentColor`:

```swift
// 原本
.foregroundColor(Color(hex: "#6B73FF"))

// 改成
.foregroundColor(Color(hex: "#FF6B6B"))  // 你的主色
```

如果有集中的 `Theme.swift` 或 `Colors.swift`,改那邊更省事。

### 5.7 改歡迎畫面 / 關於畫面文案

搜 `Welcome to CodeIsland` / `About CodeIsland` 這類字串:

```bash
grep -rn "CodeIsland" Sources/ --include="*.swift"
```

用你的名字替換掉使用者會看到的文字。**class / file / folder 名暫時先不要動**(以後合併 upstream 更新會打架)。

### 5.8 測試

```bash
swift build
open .build/debug/CodeIsland.app  # 這個路徑還是舊的,因為 Package.swift 的 target 名
```

看你改的名字有出現、顏色對、icon 對。

### 5.9 Commit

```bash
git add -A
git commit -m "feat(rebrand): rename to My Island, update bundle ID, logo, and theme"
git push -u origin feat/rebrand
```

然後到 GitHub 開 PR merge 進 main(或直接 push 到 main,單人專案隨你)。

### ✅ 驗收

- [ ] App 顯示名變成你的
- [ ] Icon 換了
- [ ] 打開 app,看到 About 是你的名字
- [ ] 主色變了
- [ ] Bundle ID 改了
- [ ] 原作者的 Copyright 還在 LICENSE 裡

---

<a id="phase-6"></a>
## Phase 6 — 擴充 Agent 或終端整合

CodeIsland 已支援 8 個 agent,你要加新的看你需求。這 phase 用**「加一個新 agent」**當示範。

### 6.1 選目標

```bash
# 看現在支援哪些
grep -rn "class.*Agent\|enum.*Agent\|case.*agent" Sources/ --include="*.swift" | head -20
```

假設你想加 **Aider** 這個 agent(只是舉例)。先查它有沒有 hook 機制:
- Aider 的 docs 看有沒有 `--on-message`、`--pre-edit` 之類
- 沒有官方 hook 就退而求其次:watch log 檔案

### 6.2 先畫一張整合計劃

```bash
# 在 docs/my-notes 寫
cat > docs/my-notes/agent-aider.md <<'EOF'
# 整合 Aider

## Aider 提供什麼?
- [ ] Hook? 哪些事件?
- [ ] Log 檔案? 路徑?
- [ ] 有 permission system?

## 要做哪些事?
- [ ] 在 Models 加 Agent.aider
- [ ] 在 HookInstaller 加 Aider 的 hook 安裝邏輯
- [ ] 在 SocketReceiver 加 Aider 的事件 parsing
- [ ] UI 顯示的 icon、顏色
- [ ] 設定頁面加 toggle

## 怎麼測?
- [ ] 跑 aider,看事件有沒有進來
- [ ] 壓力測試:多個 session 同時
EOF
```

### 6.3 實作流程(以加 agent 為例)

假設 codebase 結構是這樣(名字可能不同,請依實際狀況替換):

```
Sources/CodeIsland/
├── Models/
│   └── Agent.swift           ← 這裡加 case
├── Services/
│   ├── HookInstaller.swift   ← 這裡加 install 邏輯
│   └── SocketReceiver.swift  ← 這裡加 parse 邏輯
└── Views/
    └── SessionRow.swift      ← 這裡加顯示邏輯
```

#### Step 1:加 enum case

```swift
// Models/Agent.swift(假設是 enum)
enum Agent: String, CaseIterable, Codable {
    case claudeCode = "claude-code"
    case codex
    case cursor
    case aider    // ← 加這行

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .codex: return "Codex"
        case .cursor: return "Cursor"
        case .aider: return "Aider"    // ← 加這行
        }
    }

    var icon: String {
        switch self {
        case .claudeCode: return "🤖"
        case .aider: return "🛠️"   // ← 加這行
        // ...
        }
    }
}
```

編譯器會逼你把每個 `switch` 都補上 `.aider` case — **這是 Swift 的好處,跟著編譯錯誤改就對了**。

#### Step 2:加 hook 安裝邏輯

```swift
// Services/HookInstaller.swift
func installHooks(for agent: Agent) {
    switch agent {
    case .claudeCode:
        installClaudeCodeHooks()
    case .aider:
        installAiderHooks()    // ← 加這個新 method
    // ...
    }
}

private func installAiderHooks() {
    // Aider 假設支援 --hook 參數
    let hookScript = """
    #!/bin/bash
    # Aider 觸發時把 stdin 透過 socket 丟出去
    cat | /usr/local/bin/codeisland-bridge --agent aider
    """
    let path = "\(NSHomeDirectory())/.aider/hooks/pre_edit"
    // ... 寫檔邏輯
}
```

#### Step 3:bridge 處理新 agent

在 `Sources/codeisland-bridge/` 裡找處理訊息的地方,加一個 case 處理 aider 格式。

#### Step 4:UI 顯示

找出現 agent icon 或名字的 SwiftUI View,加上 `.aider` 的顯示。

#### Step 5:build & 測

```bash
swift build
# 第一次 build 會跳一堆錯,照著錯誤訊息補
```

### 6.4 加終端整合邏輯

同樣模式。看 `Sources/.../Services/TerminalJumper.swift`(或類似),照 iTerm2 / Ghostty 的現有實作抄一份,改 AppleScript 或 bundle ID。

**舉例:加 Alacritty 的 jump**:

```swift
// TerminalJumper.swift
func jumpToAlacritty(workingDir: String) {
    let script = """
    tell application "Alacritty" to activate
    """
    // Alacritty 沒有 tab 概念,所以 just activate
    runAppleScript(script)
}
```

### 6.5 Commit

```bash
git checkout -b feat/aider-support
# ... 做完以上
git add -A
git commit -m "feat(agents): add Aider support"
```

### ✅ 驗收

- [ ] 新 agent 出現在設定頁面
- [ ] 跑那個 agent 真的會觸發你的 app
- [ ] 事件 parsing 正常
- [ ] 不會搞壞原本的 agents

---

<a id="phase-7"></a>
## Phase 7 — iPhone 同步架構

⚠️ **這 Phase 難度陡然上升**。做這之前前面都要穩定。

### 7.1 決定架構模式

三種選擇,各有取捨:

**A. 純 Push Notification(最簡單)**
```
Mac app ──▶ APNs ──▶ 你 iPhone 收到通知
```
- 優點:不用寫後端
- 缺點:只能單向,無法 iPhone 回覆
- 需要:Apple Developer 帳號($99/年)、APNs 憑證

**B. 自架中繼 server(推薦,彈性高)**
```
Mac app ──WebSocket──▶ 你的 server ──WebSocket──▶ iPhone app
```
- 優點:雙向、可擴充、資料你掌控
- 缺點:要寫後端、要租 server(VPS 約 $5/月)
- MioIsland 的 Code Light 就是這種

**C. 用現成 realtime 服務(折衷)**
- Firebase Realtime Database / Supabase Realtime / Ably / Pusher
- 優點:快
- 缺點:資料在別人家、用量多要付錢

**新手建議:從 A 開始,做完再升 B**。

### 7.2 準備 Apple Developer 帳號

1. 去 [developer.apple.com](https://developer.apple.com) 註冊 $99/年
2. 創建 App ID
3. 產生 APNs key

**不付這 $99,下面通通不能做**。先停,想清楚要不要投。

### 7.3 路徑 A(APNs only)實作大綱

**Mac app 端**:

```swift
// Services/NotificationPusher.swift
import Foundation

class NotificationPusher {
    let apnsKey: String       // 從 .env 讀,不要 commit
    let keyID: String
    let teamID: String
    let deviceToken: String   // iPhone 註冊後會回傳這個

    func push(title: String, body: String) async throws {
        // 呼叫 APNs HTTP/2 API
        // 用 JWT 簽名
        // POST 到 https://api.push.apple.com/3/device/\(deviceToken)
    }
}
```

APNs 直接接有點硬,新手建議用 Swift package 簡化:[APNSwift](https://github.com/swift-server-community/APNSwift)(Apache 2.0,跟你的專案相容)。

**iPhone 端**:

另開一個 iOS Xcode 專案 `MyIslandCompanion`,用 UserNotifications framework 處理 push。

```bash
# 建立 iOS 專案
# Xcode → File → New → Project → iOS → App
# 命名:MyIslandCompanion
# Bundle ID:com.你的handle.myisland.companion
```

### 7.4 路徑 B(自架 server)實作大綱

**技術選擇**(擇一):
- Node.js + Express + Socket.io(熟 JS 建議這個)
- Swift + Vapor(全 Swift 統一,但小眾)
- Go + Gorilla WebSocket(效能好)

**資料流**:
```
Mac app 啟動
  └─▶ 連 WebSocket 到 wss://你的domain.com/ws
       └─▶ 註冊 Mac device ID

iPhone app 啟動
  └─▶ 連 WebSocket 到 wss://你的domain.com/ws
       └─▶ 掃 Mac 上顯示的 QR code 配對
              └─▶ server 記錄 deviceLink

Mac 有新 session 事件
  └─▶ 透過 WS 把 event 丟 server
       └─▶ server 轉發給該 Mac 配對的所有 iPhone
            └─▶ iPhone 更新 UI + 觸發 Live Activity
```

**後端最小雛形**(Node.js 示範):

```bash
mkdir ~/Projects/my-island-server && cd ~/Projects/my-island-server
npm init -y
npm install ws express
```

```javascript
// server.js
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

const devices = new Map();  // deviceId -> WebSocket
const pairings = new Map(); // macId -> [iphoneId...]

wss.on('connection', (ws) => {
    ws.on('message', (data) => {
        const msg = JSON.parse(data);
        if (msg.type === 'register') {
            devices.set(msg.deviceId, ws);
        } else if (msg.type === 'event') {
            const iphones = pairings.get(msg.macId) || [];
            iphones.forEach(id => {
                const phone = devices.get(id);
                if (phone) phone.send(JSON.stringify(msg));
            });
        }
    });
});
```

部署:買 VPS(推薦 Hetzner、DigitalOcean、Vultr),用 systemd / Docker 跑起來,套 nginx + Let's Encrypt SSL。

**⚠️ 以上只是骨架。真正上線要考慮**:
- 驗證(不能任何人來連都行)
- End-to-end encryption(使用者隱私)
- Reconnect 邏輯
- Rate limiting

這些都需要學,**預留至少 2–4 週**。

### 7.5 Live Activity(iPhone Dynamic Island)

iPhone 的瀏海互動要用 ActivityKit:

```swift
// iOS app 端
import ActivityKit

struct MyIslandAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var sessionStatus: String
        var agentName: String
    }
}

// 啟動一個 Live Activity
let activity = try Activity<MyIslandAttributes>.request(
    attributes: MyIslandAttributes(),
    contentState: .init(sessionStatus: "working", agentName: "Claude")
)
```

Apple 對 Live Activity 有**時長限制(8 小時上限)**,要定期用 push 更新延長。

### ✅ 驗收(路徑 A 最低可用)

- [ ] Mac 有事件時,iPhone 收到 push notification
- [ ] 點通知能開你的 iPhone app 看詳情

### ✅ 驗收(路徑 B 完整版)

- [ ] iPhone 能看到即時 session 狀態
- [ ] iPhone 能發訊息傳回 Mac 的 Claude Code
- [ ] Lock screen 有 Live Activity
- [ ] 網路斷線會 reconnect

---

<a id="phase-8"></a>
## Phase 8 — 打包、簽章、發佈

### 8.1 本地打包(未簽章,給自己用)

```bash
./build.sh
# 或 swift build -c release
```

產物在 `.build/release/CodeIsland.app`。複製到 Applications:

```bash
cp -R .build/release/CodeIsland.app /Applications/
```

### 8.2 想給別人用:要簽章

未簽章的 app 別人跑會跳一堆警告。你有兩條路:

**A. 不簽,寫清楚怎麼 bypass**
在 README 寫:
```
Right-click the app → Open → Open
# 或
xattr -dr com.apple.quarantine "/Applications/My Island.app"
```

**B. 正式簽章(需要 Apple Developer 帳號 $99/年)**

1. Xcode → Settings → Accounts → 加入你的 Apple ID
2. Developer 網站產生 `Developer ID Application` 憑證,下載安裝到 Keychain
3. 簽章:
   ```bash
   codesign --force --deep --options runtime \
     --sign "Developer ID Application: Your Name (TEAMID)" \
     .build/release/CodeIsland.app
   ```
4. Notarize(讓 macOS 認得):
   ```bash
   ditto -c -k --keepParent .build/release/CodeIsland.app MyIsland.zip
   xcrun notarytool submit MyIsland.zip \
     --apple-id you@example.com \
     --team-id TEAMID \
     --password "app-specific-password" \
     --wait
   xcrun stapler staple .build/release/CodeIsland.app
   ```

### 8.3 發佈到 GitHub Releases

```bash
# 打 tag
git tag v0.1.0
git push --tags

# 用 gh 建 release 並上傳
ditto -c -k --keepParent .build/release/CodeIsland.app MyIsland-0.1.0.zip
gh release create v0.1.0 MyIsland-0.1.0.zip \
  --title "v0.1.0 — First Release" \
  --notes "First release of My Island, forked from CodeIsland."
```

### 8.4 Homebrew Cask(可選)

等有穩定版本再做。建立自己的 tap repo `homebrew-my-island`:

```bash
gh repo create homebrew-my-island --public --clone
cd homebrew-my-island
mkdir Casks
# 建 Casks/my-island.rb,參考 MioIsland 的格式
```

### ✅ 驗收

- [ ] 另一台 Mac 能從 GitHub Release 下載執行
- [ ] 裝完能正常啟動、hook 有裝、功能運作

---

<a id="phase-9"></a>
## Phase 9 — 長期維護

### 9.1 追 upstream 更新

CodeIsland 有新版本時,你可以拉進來:

```bash
# 一次性設定
git remote add upstream https://github.com/wxtsky/CodeIsland.git

# 每次要同步
git fetch upstream
git checkout main
git merge upstream/main    # 可能要手動解衝突
```

**衝突大多發生在你改過的檔案**。慢慢解、每次解完都跑一次 `swift build` 確認沒壞。

### 9.2 把你的功能 PR 回去(可選)

有些功能(bug fix、新終端支援)其實對原專案也有價值,可以發 PR 回 wxtsky/CodeIsland:

```bash
git checkout -b upstream/fix-terminal-jump
# 挑出那部分 commit
git push origin upstream/fix-terminal-jump
gh pr create --repo wxtsky/CodeIsland --title "Fix terminal jump for X"
```

### 9.3 寫自動化

開始用 GitHub Actions 自動 build / test:

```yaml
# .github/workflows/build.yml
name: Build
on: [push, pull_request]
jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: swift build
      - run: swift test
```

### 9.4 收集使用者回饋

- GitHub Issues
- Discord / Telegram / Slack 群
- 產品官網加 feedback 按鈕

### ✅ 驗收

這 phase 是持續的,沒有終點。

---

<a id="附錄-a"></a>
## 附錄 A — 除錯手冊

### 問題 1:`swift build` 報錯 "cannot find X in scope"

**原因**:某個 import 少了,或檔名跟 class 名不一致。

**解**:
```bash
# 看哪個檔用到但沒 import
grep -rn "XClassName" Sources/
# 補 import
```

### 問題 2:改完 code 但 app 行為沒變

**原因**:你用 `open .build/debug/CodeIsland.app` 開的是舊 build。

**解**:
```bash
swift build  # 一定要先 rebuild
killall CodeIsland 2>/dev/null  # 殺掉舊的
open .build/debug/CodeIsland.app
```

### 問題 3:hook 沒觸發

**解**:
```bash
# 看 hook 檔是否存在且可執行
ls -la ~/.claude/hooks/
# 手動執行看會不會 error
echo '{"test": true}' | ~/.claude/hooks/pre_tool_use.sh
```

### 問題 4:瀏海 UI 跑版

**解**:不同機型瀏海高度不同,檢查是否寫死 pixel 值。MacBook Air M2 和 Pro 14" 數值不同。

### 問題 5:`codesign` 失敗

**解**:
```bash
# 看有沒有可用憑證
security find-identity -v -p codesigning
# 沒有就先回 Apple Developer 設定
```

### 問題 6:Xcode 打開 Package.swift 後找不到 scheme

**解**:等 Xcode 把 dependencies 下載完。底下 status bar 會顯示 "Resolving Swift packages...",跑完才會出現 scheme。

---

<a id="附錄-b"></a>
## 附錄 B — 有用指令速查

### 每日開發

```bash
# 開 Xcode
open Package.swift

# 編譯
swift build

# 跑並看 log
swift run 2>&1 | tee /tmp/my-island.log

# 清空 build cache(偶爾用)
swift package clean
rm -rf .build

# 跑 lint
swiftlint --fix
swiftformat Sources/
```

### Git 工作流

```bash
# 開分支
git checkout -b feat/xxx

# 快速 commit
git add -A && git commit -m "feat(xxx): yyy"

# 推上去
git push -u origin feat/xxx

# 開 PR
gh pr create
```

### 同步 upstream

```bash
git fetch upstream
git merge upstream/main
# 衝突時
git status         # 看哪些檔衝突
# 手動解,然後
git add <檔案>
git commit
```

### 觀察 hook/socket

```bash
# 看你的 app 用的 socket
ls -la /tmp/codeisland*.sock

# 看 hook 設定
jq '.hooks' ~/.claude/settings.json

# 即時看 log
tail -f /tmp/my-island.log
```

### 打包

```bash
# Debug 版
swift build

# Release 版
swift build -c release

# 打成 zip 分發
ditto -c -k --keepParent .build/release/CodeIsland.app MyIsland.zip
```

---

## 結語

做完 Phase 5 你就有一個能用的「自己的版本」。
做完 Phase 6 你會真的開始有人用(因為支援的 agent 多了)。
Phase 7 是「作品變產品」的門檻。

**慢慢來,不要趕**。新手一週能完成 Phase 2–5 就很厲害。

遇到卡關的地方,有三個資源:
1. CodeIsland 原 repo 的 issues — 有人踩過坑
2. Swift 官方 [forums](https://forums.swift.org/)
3. Apple Developer Forum

祝你 ship 出屬於你的 Island!🏝️
