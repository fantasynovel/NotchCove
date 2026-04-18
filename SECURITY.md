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

如果你發現了 My Island 的安全漏洞,**請不要公開在 GitHub Issues 討論**。

改用以下方式:

### 方法 1:GitHub Private Security Advisory(推薦)

1. 到 [Security Advisories 頁面](https://github.com/你的handle/my-island/security/advisories/new)
2. 填表,我會私下收到通知

### 方法 2:Email

寄到:**[你的email,可用 security@你的域名 或個人 email]**

Email 主旨請包含 `[MyIsland Security]`。

### 請在通報中包含

- 漏洞描述(是哪類問題?例如 RCE、info leak、privilege escalation...)
- 重現步驟
- 影響範圍(誰會受影響?)
- 已確認受影響的版本
- (選填)修正建議或 POC

---

## Response Timeline

我個人專案沒有團隊,回應時間不會像公司那麼快。但我承諾:

- **48 小時內**:確認收到
- **7 天內**:初步評估(確認是否為漏洞、嚴重程度)
- **30 天內**:如果確認是漏洞,釋出修正或緩解方案
- 修正釋出後,會在 release notes 和 advisory 致謝(除非你要求匿名)

---

## 安全設計原則(我的承諾)

My Island 在設計上遵守這些原則:

### Local-first
- 預設所有資料留在本機
- 沒有遙測、沒有分析
- 沒有帳號系統

### Unix Socket 權限
- Socket 檔建立後強制 `chmod 0600`
- 只有當前使用者能讀寫
- 別的使用者沒辦法偽造 hook 事件

### Hook Fail Open
- App 沒開或故障時,hook 放行
- 不會因為安全元件壞掉阻擋 Claude Code 運作

### 最小權限
- 只要求真正需要的 macOS 權限
- 每個權限都在 Info.plist 寫清楚用途

### 簽章與公證
- Release 版本會簽章
- 簽章用 Apple Developer ID(如我有付費)或 ad-hoc(未付費)
- 會在 release notes 清楚標示

---

## 已知的 Security 限制

透明告知使用者:

1. **Hook script 跟 app 同權限執行**
   - Hook 以你的 user 身份跑,擁有你的檔案權限
   - 這是 shell script 的天性,無法改善
   - 我們有限制:只從 Claude Code 的可信 hook 機制觸發

2. **如果你啟用 iPhone 同步**(未來功能)
   - 見 [PRIVACY.md](./PRIVACY.md) 的詳細說明
   - 預計使用 end-to-end encryption

3. **AppleScript 的能力**
   - Accessibility 權限讓 app 能控制其他 app
   - 我們只用這個權限做 terminal tab 切換
   - 不會截圖、不會偷看其他 app 內容

---

## 針對開發者的建議

如果你 fork 了這個專案:

- 請定期同步上游的 security 修正
- Socket 檔路徑建議換成你自己的,避免跟原版衝突
- Hook binary 路徑請用你的 bundle ID,避免意外覆蓋
- 不要硬編碼 API keys 或憑證到 code 裡(用環境變數或 macOS Keychain)

---

Thanks for helping keep My Island safe!
