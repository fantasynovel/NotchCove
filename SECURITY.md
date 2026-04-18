# Security Policy

## Supported Versions

只有最新的 minor 版本會收到安全性修正。

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | ✅                 |
| < 0.1.0 | ❌(尚未發佈)     |

等有 1.0.0 後,策略會改為:最新 major 和前一個 major 都支援。

---

## Reporting a Vulnerability

如果你發現了 NotchCove 的安全漏洞,**請不要公開在 GitHub Issues 討論**。

請使用 GitHub Private Security Advisory:

1. 前往 [Security Advisories 頁面](https://github.com/fantasynovel/NotchCove/security/advisories/new)
2. 填寫表單,維護者會私下收到通知

### 請在通報中包含

- 漏洞描述(是哪類問題?例如 RCE、info leak、privilege escalation…)
- 重現步驟
- 影響範圍(誰會受影響?)
- 已確認受影響的版本
- (選填)修正建議或 PoC

---

## Response Timeline

這是個人專案,回應時間不會像公司那麼快。但承諾如下:

- **48 小時內**:確認收到
- **7 天內**:初步評估(確認是否為漏洞、嚴重程度)
- **30 天內**:如果確認是漏洞,釋出修正或緩解方案
- 修正釋出後,會在 release notes 與 advisory 致謝(除非你要求匿名)

---

## 安全設計原則

NotchCove 在設計上遵守這些原則:

### Local-first
- 預設所有資料留在本機
- 沒有遙測、沒有分析
- 沒有帳號系統

### Unix Socket 權限
- Socket 檔建立後強制 `chmod 0600`
- 只有當前使用者能讀寫
- 其他使用者無法偽造 hook 事件

### Hook Fail Open
- App 沒開或故障時,hook 放行
- 不會因為安全元件壞掉阻擋 AI 工具運作

### 最小權限
- 只要求真正需要的 macOS 權限
- 每個權限都在 Info.plist 寫清楚用途

### 簽章與公證
- Release 版本會簽章
- 簽章用 Apple Developer ID(如果可用)或 ad-hoc
- 會在 release notes 清楚標示

---

## 已知的 Security 限制

透明告知使用者:

1. **Hook script 以使用者權限執行**
   - Hook 會以你的 user 身份跑,擁有你的檔案權限
   - 這是 shell script 的天性,無法消除
   - 限制:只從 AI 工具的可信 hook 機制觸發

2. **AppleScript 能力**
   - Accessibility 權限讓 app 能控制其他 app
   - 只用於 terminal tab 切換
   - 不會截圖、不會讀取其他 app 內容

---

## 針對開發者的建議

如果你 fork 了這個專案:

- 請定期同步上游的 security 修正
- Socket 檔路徑建議換成你自己的,避免跟原版衝突
- Hook binary 路徑請用你的 bundle ID,避免意外覆蓋
- 不要硬編碼 API keys 或憑證到 code 裡(用環境變數或 macOS Keychain)

---

Thanks for helping keep NotchCove safe!
