# 架構決策紀錄(ADR — Architecture Decision Records)

> **這是什麼?**:每次你做了一個「為什麼選 X 不選 Y」的決定,就寫一條在這裡。
>
> **為什麼要寫?**:三個月後你會忘記為什麼當初這樣設計。Code 看得到結果,但看不到「為什麼」。ADR 就是填這個空白。
>
> **格式**:每個決策一個段落,不用寫得太長。

---

## 怎麼寫一條 ADR?

用這個模板:

```markdown
## ADR-XXX:[短標題]

**日期**:YYYY-MM-DD
**狀態**:Proposed / Accepted / Deprecated / Superseded by ADR-YYY

**情境**(Context):
[為什麼要做這個決定?當時的問題是什麼?]

**選項**(Options):
- A: [說明]
- B: [說明]
- C: [說明]

**決定**(Decision):
選 X,因為...

**後果**(Consequences):
- 好處:...
- 壞處:...
- 未來要注意:...
```

---

## 已記錄的決策

### ADR-001:選擇 wxtsky/CodeIsland 作為 fork 起點

**日期**:2026-04-18
**狀態**:Accepted

**情境**:
市面上有四個同類型 repo(farouqaldori/claude-island、Octane0411/open-vibe-island、MioMioOS/MioIsland、wxtsky/CodeIsland)。我需要選一個起點 fork,之後做自己的版本。

**選項**:
- A: farouqaldori/claude-island(Apache 2.0,功能最少,star 最多 914)
- B: Octane0411/open-vibe-island(GPL v3,功能多)
- C: MioMioOS/MioIsland(CC BY-NC 4.0,功能最多)
- D: wxtsky/CodeIsland(MIT,8 個 agent 支援)

**決定**:
選 D(wxtsky/CodeIsland)。

理由:
1. MIT license 最寬鬆,保留未來閉源/商用彈性
2. 已內建多 agent 支援,省下我擴充成本
3. 作者只在 README 寫「inspired by claude-island」,沒有複雜依賴
4. 比 A 省力(A 只支援 Claude Code),比 B/C 法律彈性高

**後果**:
- 好處:起步快,license 乾淨
- 壞處:star 數 156 比 A 的 914 少,搜尋被看見的機率較低
- 未來要注意:upstream 活躍度中等,要準備自己長期維護

---

### ADR-002:保留原作者的 Copyright,新增自己的

**日期**:2026-04-18
**狀態**:Accepted

**情境**:
MIT license 要求「保留原作者 copyright 聲明」。我 fork 後怎麼處理 LICENSE?

**決定**:
- 原 `Copyright (c) 2025 wxtsky` 不動
- 在下面加一行 `Copyright (c) 2026 [我的名字]`
- LICENSE 其他條文不動

**後果**:
- 符合 MIT 合規
- 未來新增 Apache 2.0 code 時,再加 NOTICE 檔

---

### ADR-003:只改顯示名稱 "Notch Cove",保留內部 CFBundleIdentifier 與 Swift target 名 CodeIsland

**日期**:2026-04-18
**狀態**:Accepted

**情境**:
Fork 下來後要打自己的品牌。但 rebrand 有三層:顯示名稱(CFBundleName、選單列、設定頁)、bundle identifier(`com.codeisland.app`)、Swift target / binary 名稱(`CodeIsland`)。改 CFBundleIdentifier 會讓已安裝使用者的 UserDefaults、macOS TCC 權限、鑰匙圈完全失聯,需要寫 migration 才不會壞。改 Swift target 名要動 `Package.swift` + 所有 `import CodeIslandCore` + 重新命名 `Sources/CodeIsland/` 整個資料夾 + hook scripts 裡的版本標記 `# CodeIsland hook vN`。

**選項**:
- A: 一次全改(顯示名 + bundle id + target + hook 標記)。乾淨但強制 reset 使用者資料 + 改動面積極大
- B: 只改顯示名,bundle id + target + hook 標記保留
- C: 用版本控制+migration script 幫使用者搬設定,同時全改

**決定**:
選 B。

理由:
1. Pre-1.0 使用者不多,但已經有人裝並授權了 Accessibility / Automation 權限——砍掉重來體驗差
2. `hook script` 裡的 `# CodeIsland hook v...` 是舊版偵測標記,改掉老 hook 就變孤兒無法清理
3. 使用者看得到的層只有 CFBundleName、app 檔名、locale 字串、README 等——這些改就夠了
4. 未來真要做 C,至少先觀察 fork 是否有真實使用者再評估

**後果**:
- 好處:既有使用者零感知升級、改動面積小、風險低
- 壞處:程式碼裡長期會有「品牌分裂」的怪味(開發者看 `Contents/MacOS/CodeIsland` 會困惑)、跨平台搜尋時兩套名稱都查才全
- 未來要注意:真正 v2 / 大版本時再一次性全改,寫 migration 把 `UserDefaults` 從 `com.codeisland.app` 搬到 `com.notchcove.app`

---

### ADR-004:加 zh-Hant 為獨立 locale,不合併到既有 zh

**日期**:2026-04-18
**狀態**:Accepted

**情境**:
Upstream 只有一個 `zh` 字典(簡體),但台灣/香港使用者慣用詞彙差很多(工作階段 vs 会话、選單列 vs 菜单栏、瀏海 vs 刘海、預設 vs 默认)。直接改簡體字典變繁體會讓簡中使用者 UI 錯亂。

**選項**:
- A: 把 `zh` 改成繁中、不支援簡中
- B: 加 `zh-Hant` 當獨立 locale、`zh` 保留當簡中
- C: 用 `NSLocalizedString` + Apple 的 `.lproj` 資料夾結構、走標準化路線

**決定**:
選 B。

理由:
1. 保留 upstream 既有的簡中支援(社群可能有中國使用者),不做破壞性改動
2. `L10n.swift` 目前是 Swift dict-based,改成 `.lproj` 會重做整個 l10n 系統
3. `effectiveLanguage` 加 `zh-Hant`/`zh-TW`/`zh-HK`/`zh-MO` 前綴判斷就能對系統偏好自動路由

**後果**:
- 好處:兩套中文並存、使用者照系統 locale 自動對到正確版本、改動面積可控
- 壞處:之後每加一條字串要同步六個語系(英日韓土 + zh/zh-Hant)、dict-based 無法給翻譯者 po/xlf 檔
- 未來要注意:如果翻譯數量爆炸,再評估遷到 `NSLocalizedString` + Xcode string catalog

---

### ADR-005:換 Xcode 26 `AppIcon.icon` Liquid Glass composer → 傳統 `AppIcon.appiconset`

**日期**:2026-04-18
**狀態**:Accepted

**情境**:
Upstream 用 Xcode 26 的新格式 `AppIcon.icon/`,只放一張 SVG,讓 composer 幫你疊 glass / translucency / shadow 效果。我自己準備的 icon 已經是完成設計(含陰影、玻璃、漸層),再走 composer 會「效果疊兩層」變怪。

**選項**:
- A: 維持 `.icon` composer 格式,icon.json 把 `glass / translucency / shadow` 都關掉
- B: 換回傳統 `AppIcon.appiconset` + 7 張預先渲染好的 PNG(16/32/64/128/256/512/1024)
- C: 兩個格式並存,由 build 腳本決定用哪個

**決定**:
選 B。

理由:
1. Composer 格式文件少、未來 Xcode 變更風險高;appiconset 是 15 年穩定格式
2. 既然 icon 是預渲染的,多張不同尺寸的 PNG 在小尺寸(16pt dock overflow)可以分別手 tune,SVG 縮小到 16pt 反而糊
3. `build-dmg.sh` + `build.sh` 都用 `actool --app-icon AppIcon --compile ... Assets.xcassets`,只要 appiconset 在 Assets.xcassets 裡就會編進 app bundle

**後果**:
- 好處:icon 所見即所得、不受 composer 參數干擾、build script 統一
- 壞處:換設計要重出 7 張 PNG(我有原生 1024 就用 `sips` 縮,不算痛)
- 未來要注意:Xcode 26+ 若 deprecate appiconset、逼遷 `.icon` composer,再評估

---

### ADR-006:App 內小 logo(About 頁 + notch 頂部)從 Canvas 手繪改讀 Assets.xcassets imageset

**日期**:2026-04-18
**狀態**:Accepted

**情境**:
原本 `AppLogoView` 是 SwiftUI `Canvas { ... }` 用 code 畫的黑色 notch pill + 橘眼睛,代表上版主的品牌。換品牌後用 code 重畫不是我想做的事(design source of truth 散到 code 裡),也跟設計師無法協作。

**選項**:
- A: 維持 Canvas、改裡面的參數對應新設計
- B: 把 Canvas 拿掉,改讀 `Image("AboutLogo")` / `Image("NotchLogo")` 從 Assets.xcassets
- C: 用 SVG 檔直接引入(需要 3rd-party SVG lib)

**決定**:
選 B。

理由:
1. PNG 是設計師原生輸出格式、Canvas API 不是
2. 兩個尺寸(100pt About / 36pt notch)互相獨立、各自一個 imageset,方便分別 tune
3. Assets.xcassets 已經因為 appiconset 存在,多幾個 imageset 零成本

**後果**:
- 好處:換品牌只要丟 PNG 進 imageset,完全不用動 Swift
- 壞處:Canvas 可以根據 runtime state 變色(e.g. 不同狀態換主色),PNG 做不到——但目前也不需要
- 未來要注意:若要做 light/dark mode 各自的 logo,imageset 原生支援 Dark appearance slot

---

### ADR-007:Settings 字型系統 15pt title / 12pt #706F6F desc / 14pt base

**日期**:2026-04-18
**狀態**:Accepted

**情境**:
使用者截圖反應設定頁文字太灰、中文筆畫密度下看不清、字級混亂(11pt caption 搭 tertiary 色 = ~2.9:1 過不了 WCAG AA)。要統一整頁 typography,同時達到 WCAG AA(4.5:1)最低門檻、最好衝 AAA(7:1)。

**選項**:
- A: 維持 macOS 系統預設字型和 `.secondary`/`.tertiary` 語意色
- B: 全站 `.primary`(純黑/白),不再用 semantic dimming
- C: 自訂三段式:title / desc / control base,desc 用固定灰 `#706F6F`

**決定**:
選 C。

- **Title**:15pt regular,寫 `.settingsTitle()`
- **Desc**:12pt + `#706F6F`(白底約 5.5:1,過 AA 接近 AAA),寫 `.settingsDesc()`
- **Form 底**:`.font(.system(size: 14))` cascade 當 base,所有 picker 值 / textfield / button label 預設都吃到
- Section headers 用 `#706F6F`(和 desc 同色),所有 `Section(String){}` 轉 explicit header form

理由:
1. `.primary` 沒 opacity 乘(macOS labelColor ~85%)白底 ~15:1,比單 `.secondary` 4.5:1 穩很多
2. 固定灰 `#706F6F` 不受 `Color.primary.opacity(0.78)` 那種「semantic + opacity 相乘」的計算黑洞影響——使用者看到的對比就是 5.5:1
3. 層級仍靠字重 + 字級差異維持,不靠顏色

**後果**:
- 好處:全站一致、WCAG 可測、深淺模式自動適應(desc 在深色模式下效果一樣 #706F6F on dark bg 約 4.9:1,仍過 AA)
- 壞處:`#706F6F` 是 light mode 設計,dark mode 可能略暗;未來可能要分 light/dark adaptive
- 未來要注意:加新 Settings 元件時記得用 `.settingsTitle()`/`.settingsDesc()` helper,不要直接寫 `.foregroundStyle(.secondary)`

---

### ADR-008:v1.0.0 以 ad-hoc 簽章 DMG 發佈,暫不加入 Apple Developer Program

**日期**:2026-04-18
**狀態**:Accepted(短期決定)

**情境**:
要發 v1.0.0。完整簽章+公證要:Apple Developer ID Application 憑證(加入 Apple Developer Program $99/年)+ notarytool 憑證 profile。沒憑證就只能 ad-hoc 簽章,使用者首次啟動會被 Gatekeeper 擋。

**選項**:
- A: 加入 Apple Developer Program、完整簽章 + 公證
- B: Ad-hoc 簽章 DMG,README 教使用者 Gatekeeper 繞法(系統設定 / `xattr -dr`)
- C: 不發 .app,只提供 `./build.sh` 從原始碼建置

**決定**:
選 B。

理由:
1. 專案還在早期、不確定長期投入多少,$99/年先省
2. 使用者群是 AI / 開發者背景,會用 terminal 繞 Gatekeeper 不是門檻
3. README 雙語都有寫繞法步驟、用 `xattr -dr com.apple.quarantine "/Applications/Notch Cove.app"` 一行搞定
4. `build-dmg.sh` 有 `SKIP_SIGN=1 SKIP_NOTARIZE=1` 支援、隨時可以切回簽章路線

**後果**:
- 好處:零成本發版、release loop 可以先轉起來再說
- 壞處:Homebrew cask 雖然技術上可以發(release.yml 已寫),但 `brew install --cask notchcove` 之後使用者還是要手動繞 Gatekeeper,加值有限,所以 README 先拿掉 Homebrew 那段
- 未來要注意:有第一波真實使用者反饋 + 覺得值得了,再升級到完整簽章 + 公證 + 重發 Homebrew cask

---

### ADR-009:[範例,等你真的做時再寫]

**日期**:
**狀態**:

**情境**:

...

---

## 以後可能要記的決策(Placeholder)

當你遇到以下情況,記得來寫 ADR:

- [ ] 選擇用 SwiftUI 還是 AppKit 為主
- [ ] 選 `NWListener` 還是 BSD socket
- [ ] 訊息格式選 JSON / MessagePack / Protobuf
- [ ] Hook 要用 shell script 還是 compiled binary
- [ ] 首次啟動要自動裝 hook 還是讓使用者手動
- [ ] Hook fail open 還是 fail closed
- [ ] Dev build 要不要強制複製到 `/Applications`
- [ ] iPhone 同步用 APNs only 還是自架 server
- [ ] iPhone 用 E2EE 還是不加密
- [ ] 發佈用 GitHub Releases 還是 Homebrew Cask
- [ ] 要不要 sign + notarize(付 $99)
- [ ] 套餐收費還是完全免費
- [ ] 長期 roadmap:廣度(多 agent)還是深度(Claude Code 做到最好)

---

## 撰寫提示

- **狀態怎麼寫**:
  - `Proposed`:還在討論
  - `Accepted`:已決定、已實作
  - `Deprecated`:不再適用但保留紀錄
  - `Superseded by ADR-YYY`:被另一條取代
- **不要刪舊的**,只加新的。歷史軌跡才有價值。
- **簡潔優先**。一條 ADR 不超過一頁。
- **寫給未來的自己看**,不是給別人看。可以很口語。
