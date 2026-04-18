# 品牌決策(My Island)

> **這份筆記**:記錄品牌相關的所有決定。Phase 5 動手換品牌前先寫,避免改了一半才發現要改名、要挑色。

---

## 基本識別

| 項目 | 值 | 備註 |
|---|---|---|
| **使用者可見的 App 名** | [填] | 例:My Island、Dev Notch、AgentBar |
| **程式碼識別字(無空格)** | [填] | 例:MyIsland、DevNotch、AgentBar |
| **Bundle Identifier** | [填] | 例:com.你的handle.myisland。**一旦發佈不改!** |
| **GitHub Repo 名** | [填] | 例:my-island |
| **版本號起始** | 0.1.0 | 遵循 SemVer |

### Bundle ID 選擇建議

格式:`com.<你的域名反過來>.<app名>`

- 有自己域名:`com.yourdomain.myisland`
- 沒域名但有 GitHub:`io.github.yourhandle.myisland`
- 都沒有:`com.yourhandle.myisland`(之後要改會很麻煩)

---

## Logo & Icon

| 項目 | 決定 |
|---|---|
| 風格 | [極簡幾何 / 像素 / 手繪 / 擬物化] |
| 主圖形 | [例:一個發光的小圓,代表「通知島」] |
| 配色策略 | 單色 / 雙色 / 漸層 |
| 使用的工具 | [Figma / Sketch / Affinity / 找人畫] |

### Icon 檔案清單

macOS app 需要的 icon 尺寸(放進 `AppIcon.appiconset`):

```
icon_16x16.png       16×16
icon_16x16@2x.png    32×32
icon_32x32.png       32×32
icon_32x32@2x.png    64×64
icon_128x128.png     128×128
icon_128x128@2x.png  256×256
icon_256x256.png     256×256
icon_256x256@2x.png  512×512
icon_512x512.png     512×512
icon_512x512@2x.png  1024×1024
```

推薦工具:
- [IconKitchen](https://icon.kitchen/) — 網頁版,上傳 1024 全尺寸一次產
- [Bakery](https://apps.apple.com/app/bakery/id1575220747) — macOS app,設計 macOS icon 專用
- Sketch / Figma → 手動 export(比較累)

---

## 配色

### 主色 / 次色

| 角色 | Hex | 用在哪 |
|---|---|---|
| 主色(Primary) | [#填] | 主要互動元件、通知點 |
| 次色(Secondary) | [#填] | 輔助強調 |
| 危險(Danger) | [#填] | Deny 按鈕、錯誤 |
| 成功(Success) | [#填] | Allow 按鈕、完成狀態 |
| 中性文字(Text) | [#填] | 主要文字 |
| 中性背景(Background) | [#填] | 面板底色 |

### Light / Dark mode

macOS 使用者會切深淺模式,你的 app 要同時漂亮。兩個做法:

**做法 A**:在 Assets.xcassets 定義 Color Set,Light/Dark 各給一個值
**做法 B**:用 `@Environment(\.colorScheme)` 在 code 裡判斷

用做法 A 更乾淨。

---

## 文案語氣

- **第一人稱 or 第三人稱**:[我 / My Island / 你]
- **正式度**:[親切 / 專業 / 幽默]
- **表情符號使用**:[是 / 否 / 少量]
- **語系**:[英文 / 中英雙語]

### 關鍵字串範例

| 情境 | 文案 |
|---|---|
| 啟動歡迎 | [填] |
| 需要 Accessibility 權限時 | [填] |
| Hook 安裝完成 | [填] |
| 沒有 active session 時 | [填] |
| 使用者按 Deny 時 | [填] |

---

## 字型

- **UI 字型**:macOS 預設 `SF Pro`(免費用,和系統一致)
- **等寬字型(code 顯示用)**:`SF Mono` 或 `Menlo`

**不建議**:
- 用自訂字型要處理授權
- 用非系統字型會讓 app 看起來「不像 Mac app」

---

## 網域和社群(未來用)

- 官網域名:[有/沒有,域名:____]
- Twitter handle:[____]
- GitHub org 或個人:[____]
- Email 聯絡:[____]

---

## 什麼不可以跟 CodeIsland / MioIsland 很像?

避免品牌混淆與法律麻煩:

- ❌ 不要叫 "CodeIsland"、"MioIsland"、"Claude Island"
- ❌ 不要用跟他們太像的 logo
- ❌ 不要在宣傳用 "the best CodeIsland alternative" 之類暗示關係的文案
- ✅ 可以在 README 的 credits 誠實說「forked from CodeIsland」

---

## Phase 5 前檢核

- [ ] App 名已決定,老婆/朋友覺得順口
- [ ] Bundle ID 想清楚,Google 查過沒人用過
- [ ] Logo 有了(至少 1024×1024 PNG)
- [ ] Icon 展開成 AppIcon.appiconset 所有尺寸
- [ ] 主色與次色決定
- [ ] Light/Dark mode 色票都有
- [ ] 關鍵文案寫好(至少 5 條)
