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

### ADR-003:[範例,等你真的做時再寫]

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
