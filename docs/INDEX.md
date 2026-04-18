# 📚 Documentation Index

這份文件是所有 docs 的「地圖」,讓你(或未來的貢獻者)知道哪裡找什麼。

---

## 📂 結構

```
my-island/
├── README.md                    ← 對外門面
├── LICENSE                      ← MIT license(保留 wxtsky copyright)
├── NOTICE                       ← 法律歸屬清單
├── CHANGELOG.md                 ← 版本歷史
├── SECURITY.md                  ← 安全政策
├── .github/
│   └── ISSUE_TEMPLATE/          ← GitHub issue 範本
│       ├── bug_report.md
│       ├── feature_request.md
│       └── config.yml
└── docs/
    ├── INDEX.md                 ← 你正在看的這份
    ├── research/                ← 逆向工程筆記(Phase 4.75)
    │   ├── 01-notch-positioning.md
    │   ├── 02-hook-protocol.md
    │   ├── 03-unix-socket.md
    │   ├── 04-terminal-jump.md
    │   └── 05-macos-permissions.md
    └── my-notes/                ← 個人筆記(不對外)
        ├── architecture.md      ← 我理解的架構
        ├── brand.md             ← 品牌決策
        └── decisions.md         ← ADR 架構決策紀錄
```

---

## 🎯 依目的找文件

### 「我要從頭開始學這個專案」
1. 讀 [README.md](../README.md) — 30 秒認識
2. 讀 [docs/my-notes/architecture.md](./my-notes/architecture.md) — 了解資料流
3. 讀 [docs/research/02-hook-protocol.md](./research/02-hook-protocol.md) — 最關鍵技術點

### 「我要回報 bug」
→ [.github/ISSUE_TEMPLATE/bug_report.md](../.github/ISSUE_TEMPLATE/bug_report.md) 有模板

### 「我要提議功能」
→ [.github/ISSUE_TEMPLATE/feature_request.md](../.github/ISSUE_TEMPLATE/feature_request.md)

### 「我要加新的 agent 支援」
1. 看 [docs/research/02-hook-protocol.md](./research/02-hook-protocol.md) 理解 hook 機制
2. 看 [docs/my-notes/architecture.md](./my-notes/architecture.md) 了解整合點
3. 照著 Phase 6 的模式做

### 「我要加新的 terminal 支援」
→ [docs/research/04-terminal-jump.md](./research/04-terminal-jump.md)

### 「我搞砸了權限」
→ [docs/research/05-macos-permissions.md](./research/05-macos-permissions.md)

### 「我想知道當初為什麼這樣設計」
→ [docs/my-notes/decisions.md](./my-notes/decisions.md)

### 「我要打包發佈」
→ docs/packaging.md(還沒寫,Phase 8 再補)

### 「我關心隱私」
→ 目前 README 有 Privacy section,如果加 iPhone 同步要寫 PRIVACY.md

### 「安全漏洞」
→ [SECURITY.md](../SECURITY.md)

---

## 📝 撰寫原則

| 類型 | 寫給誰 | 語氣 | 更新頻率 |
|---|---|---|---|
| README | 使用者 / 潛在貢獻者 | 親切 + 專業 | 每個 release |
| CHANGELOG | 使用者 | 簡潔 | 每個 release |
| research/* | **我自己** | 可以很口語 | 初始一次,之後 as-needed |
| my-notes/* | **只有我** | 完全自由 | 想到就寫 |
| .github/ | GitHub 使用者 | 結構化 | 很少變 |
| ISSUE/PR | 使用者 | 引導式 | 很少變 |

**關鍵差異**:
- `docs/research/` 是**學習筆記**,對外可見但主要服務自己
- `docs/my-notes/` 是**個人筆記**,可以寫「我覺得 Swift 好難」這種話,沒人會 judge

---

## 🚫 還沒寫的文件(未來 Phase 會補)

- [ ] `docs/architecture.md` — 對外版架構文件(跟 my-notes/ 那個不同,這是正式版)
- [ ] `docs/packaging.md` — 打包、簽章、notarize(Phase 8)
- [ ] `docs/roadmap.md` — 公開 roadmap
- [ ] `CONTRIBUTING.md` — 貢獻者指南(等有人想貢獻再寫)
- [ ] `PRIVACY.md` — 隱私政策(iPhone 同步上線前必須有)
- [ ] `README.zh-TW.md` — 中文 README
- [ ] `docs/images/` — 截圖(發 v0.1.0 前要有)

---

## 🗺️ 關聯到實作計劃(IMPLEMENTATION_PLAN.md)

| 文件 | 對應 Phase |
|---|---|
| docs/research/01–05 | Phase 4.75 |
| docs/my-notes/architecture.md | Phase 4 |
| docs/my-notes/brand.md | Phase 5 |
| docs/my-notes/decisions.md | 貫穿所有 Phase |
| README.md | Phase 5 + 持續 |
| NOTICE | Phase 4.5 + Phase 5 |
| CHANGELOG.md | Phase 8 + 持續 |
| SECURITY.md | Phase 8 前 |
| .github/ISSUE_TEMPLATE | Phase 8 前 |
