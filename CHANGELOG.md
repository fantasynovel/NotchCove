# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- (什麼新功能?)

### Changed
- (哪些改變了?)

### Deprecated
- (什麼 API 要淘汰了?)

### Removed
- (移除了什麼?)

### Fixed
- (修了哪些 bug?)

### Security
- (安全相關的修正)

---

## [0.1.0] — YYYY-MM-DD

### Added
- Initial fork from [wxtsky/CodeIsland](https://github.com/wxtsky/CodeIsland).
- Rebranded as My Island.
- Updated bundle identifier to `com.你的handle.myisland`.
- Custom app icon and theme.

### Notes
- This is a development-focused pre-release. Not yet signed or notarized.
- See [NOTICE](./NOTICE) for attribution.

---

<!-- 未來版本範例模板:

## [0.2.0] — YYYY-MM-DD

### Added
- New agent support: [Agent Name]
- Terminal integration: [Terminal Name]

### Fixed
- Fixed notch alignment on MacBook Air M3 (#XX)

### Changed
- Improved permission onboarding flow

-->

---

## 撰寫規範(給自己)

### 何時更新?

- 每個要進 `main` 的 PR,都要在 `[Unreleased]` 對應小節加一行
- Release 前把 `[Unreleased]` 內容搬到新版本區塊

### 分類用哪個?

- **Added** — 新功能
- **Changed** — 既有功能的行為調整
- **Deprecated** — 即將移除的功能(先警告)
- **Removed** — 真的移除了
- **Fixed** — bug 修正
- **Security** — 安全性修正

### 寫給誰看?

寫給**使用者**看。不是 commit log。

❌ "Refactored SocketReceiver.swift to use NWListener" — 使用者看不懂
✅ "Improved socket stability on macOS 15.2+" — 使用者能理解影響

### 版本號怎麼跳?

遵循 [SemVer](https://semver.org/):
- `0.1.0` → `0.1.1`:bug fix
- `0.1.x` → `0.2.0`:新功能(向下相容)
- `0.x.x` → `1.0.0`:第一個「穩定」版或有破壞性變更
- `1.0.x` → `2.0.0`:破壞性變更(hook 格式變了、設定檔遷移等)

開發期 `0.x` 可以比較隨意,但 `1.0` 後要嚴謹。
