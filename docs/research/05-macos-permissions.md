# 黑盒 5:macOS 權限迷宮

> **狀態**:🟡 Draft(預填已知資訊,待親手實驗)
> **對應 Phase**:4.75 — 逆向工程
> **最後更新**:[實驗完填日期]

---

## 這個黑盒是什麼?

你的 app 做一些「敏感」動作時,macOS 會擋下來問使用者。例如:

- 控制其他 app(切 terminal tab)→ 需要 **Accessibility** 權限
- 送 Apple Event(跑 AppleScript)→ 需要 **Automation** 權限
- 顯示通知 → 需要 **Notifications** 權限
- 讀 Claude 的認證 token → 需要 **Keychain** 存取

如果 app 沒處理好權限,使用者要嘛**用不了功能**,要嘛**卡在第一次啟動就放棄**。

---

## 為什麼這是黑盒?

- Apple 的權限文件**零散在十幾個地方**,沒有統一指南
- 哪個操作要哪個權限,沒人寫清楚(要靠踩坑經驗)
- 權限一旦拒絕,**很難再問一次**(要使用者手動去系統設定)
- 開發期間 Debug 重編會搞壞權限(MioIsland 特別提到的坑)

---

## macOS 的權限系統叫什麼?

**TCC**(Transparency, Consent, and Control)。

資料庫存在:
```
~/Library/Application Support/com.apple.TCC/TCC.db       # User 層
/Library/Application Support/com.apple.TCC/TCC.db        # System 層
```

這兩個檔案普通 user 讀不到,你可以從「系統設定 → 隱私權與安全性」看到一部分內容。

---

## 權限類型與 Info.plist 對照表

| 權限類型 | TCC 服務名 | Info.plist key | 相關 Swift API |
|---|---|---|---|
| Accessibility(控制其他 app 視窗) | `kTCCServiceAccessibility` | `NSAccessibilityUsageDescription` | `AXIsProcessTrusted()` |
| Automation(AppleScript 控制其他 app) | `kTCCServiceAppleEvents` | `NSAppleEventsUsageDescription` | 自動跳對話框 |
| Notifications | `kTCCServiceNotifications` | 不需 Info.plist key | `UNUserNotificationCenter` |
| Full Disk Access | `kTCCServiceSystemPolicyAllFiles` | 不需(使用者手動授權) | 沒 API 檢查 |
| Camera | `kTCCServiceCamera` | `NSCameraUsageDescription` | `AVCaptureDevice.authorizationStatus` |
| Input Monitoring(全域鍵盤事件) | `kTCCServiceListenEvent` | 不需 Info.plist | `CGPreflightListenEventAccess()` |
| Screen Recording | `kTCCServiceScreenCapture` | `NSScreenCaptureUsageDescription`(macOS 14+) | `CGPreflightScreenCaptureAccess()` |

---

## 權限怎麼「認」你的 app?

重點來了——TCC 記錄的「這個 app 有權限」不是記 app 名稱,而是記:

1. **Bundle Identifier**(e.g. `com.myhandle.myisland`)
2. **Code signature**(簽章指紋)

**兩者都對得上**才算同一個 app。如果你每次 build 的簽章指紋不一樣,TCC 會覺得是不同 app。

### Debug 重編失去權限的原因

```
第一次 build:
  swift build → Build/debug/MyIsland.app
  簽章:ad-hoc ("-")
  TCC 看到:bundle=com.myhandle.myisland, sig=ad-hoc-xxxxx
  使用者授權 → TCC 記下來

改程式重 build:
  swift build → Build/debug/MyIsland.app(同路徑)
  簽章:ad-hoc,但指紋變了!
  TCC 看到:bundle=com.myhandle.myisland, sig=ad-hoc-yyyyy
  TCC:「這不是我認識的 app」→ 又要重新授權
```

### MioIsland 的解法

**強制複製到 `/Applications`** 並用那份簽章(Developer ID 簽章才穩定):

```bash
# 在你的 build script 裡
swift build -c debug
cp -R .build/debug/MyIsland.app /Applications/
open /Applications/MyIsland.app
```

這樣從 `/Applications` 跑的版本,簽章如果是 Developer ID,指紋就是穩定的。Ad-hoc 簽章還是會變(你沒買 Apple Developer 前),但至少 path 穩定。

---

## 檢查/請求權限的 Swift 模式

### Accessibility

```swift
import ApplicationServices

// 檢查
func hasAccessibility() -> Bool {
    return AXIsProcessTrusted()
}

// 請求(跳對話框)
func requestAccessibility() {
    let options: NSDictionary = [
        kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
    ]
    _ = AXIsProcessTrustedWithOptions(options)
}

// 打開系統設定頁面(讓使用者自己去勾)
func openAccessibilitySettings() {
    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    NSWorkspace.shared.open(url)
}
```

### Automation(AppleScript)

```swift
// Automation 沒有「請求權限」的 API
// 使用者要等 app 實際跑 AppleScript 時,系統會自動跳對話框
// 你能做的是在 Info.plist 寫好理由

// 檢查(用 pre-flight 避免跳框)
import Foundation

func canSendAppleEventsTo(bundleID: String) -> Bool {
    let descriptor = NSAppleEventDescriptor(bundleIdentifier: bundleID)
    let status = AEDeterminePermissionToAutomateTarget(
        descriptor.aeDesc,
        typeWildCard,
        typeWildCard,
        false  // askUserIfNeeded = false,只檢查不跳框
    )
    return status == noErr
}
```

### Notifications

```swift
import UserNotifications

func requestNotifications() async {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()

    switch settings.authorizationStatus {
    case .notDetermined:
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    case .denied:
        // 使用者拒絕過,引導到系統設定
        openNotificationSettings()
    case .authorized, .provisional, .ephemeral:
        break
    @unknown default:
        break
    }
}
```

---

## Info.plist 必填清單(你這種 app)

```xml
<key>NSAccessibilityUsageDescription</key>
<string>MyIsland needs accessibility permission to focus the correct terminal tab when you jump to a session.</string>

<key>NSAppleEventsUsageDescription</key>
<string>MyIsland uses AppleScript to switch between terminal tabs and windows.</string>

<!-- 如果你做畫面截圖或錄影功能 -->
<key>NSScreenCaptureUsageDescription</key>
<string>MyIsland captures terminal output to sync with your iPhone companion.</string>

<!-- LSUIElement = true 讓 app 不出現在 Dock / Cmd+Tab -->
<key>LSUIElement</key>
<true/>

<!-- 最低支援的 macOS 版本 -->
<key>LSMinimumSystemVersion</key>
<string>14.0</string>
```

**注意**:`UsageDescription` 字串**必須**寫清楚為什麼,Apple 審查會擋模糊的理由。

---

## 實驗 A:看 CodeIsland 要哪些權限

```bash
cd ~/Projects/my-island
grep -A1 "UsageDescription" Info.plist
```

[親手實驗後填] 觀察到的權限宣告:
```
[貼你看到的 UsageDescription keys 和 values]
```

---

## 實驗 B:看系統設定裡你的 app 狀態

在系統設定 → 隱私權與安全性,找這幾個頁面:
- 輔助使用(Accessibility)
- 自動化(Automation)
- 通知

你會看到 CodeIsland 的開關狀態。

[親手實驗後填]
```
Accessibility:[開/關]
Automation → iTerm2:[開/關/沒出現]
Automation → 其他:...
通知:[開/關]
```

---

## 實驗 C:重現「Debug 重編失去權限」

```bash
cd ~/Projects/my-island

# 第一次 build 跑
swift build
open .build/debug/CodeIsland.app
# 授權所有權限

# 關掉 app,隨便改一行 code
echo "// comment $(date)" >> Sources/CodeIsland/AppDelegate.swift

# 重 build
swift build
open .build/debug/CodeIsland.app
```

[親手實驗後填] 觀察:
- 權限對話框有再跳嗎?
- 系統設定裡 app 項目變多了嗎?(因為舊的 signature 還留著)
- Accessibility 權限還有嗎?

---

## 實驗 D:MioIsland 建議的解法

```bash
# 在你的 repo 加一個 install 腳本
cat > install-dev.sh <<'EOF'
#!/bin/bash
swift build -c debug
rm -rf /Applications/MyIsland\ Dev.app
cp -R .build/debug/CodeIsland.app /Applications/MyIsland\ Dev.app
open /Applications/MyIsland\ Dev.app
EOF
chmod +x install-dev.sh

# 之後開發就用這個而不是直接跑 .build 的
./install-dev.sh
```

好處:
- Path 穩定,使用者看起來是「同個 app」
- TCC 不會抱怨(雖然 signature 還是每次變)

---

## 「權限被拒絕」要怎麼優雅處理?

使用者點了「拒絕」之後,**你的 app 不能就 crash**。要做到:

1. 啟動時檢查所有必要權限
2. 缺任何一個 → 顯示**引導頁面**
   - 告訴使用者這個 app 為何需要這個權限
   - 提供「打開系統設定」按鈕
   - 提供「知道了先跳過」按鈕(非必要權限)
3. 權限補齊後,偵測到就關掉引導頁面

### 檢測權限變化

```swift
// 用 Timer 或 NotificationCenter 定期檢查
Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
    if AXIsProcessTrusted() {
        // 權限到手,更新 UI
    }
}
```

或用 `DistributedNotificationCenter` 監聽 `com.apple.accessibility.api`(不穩定,API 沒公開)。

---

## 常見坑

1. **LSUIElement = true 後找不到 app 視窗**
   - 你的 app 不在 Dock 也不在 Cmd+Tab
   - 要用 menu bar icon / 瀏海 icon 觸發視窗
   - 建議加個「緊急退出」快捷鍵

2. **Sandbox 模式與 AppleScript 衝突**
   - 啟用 App Sandbox 會限制 AppleScript
   - 你這類 app **不要** enable sandbox
   - App Store 上架才需要 sandbox,你不上架就算了

3. **tccutil reset 可以強制重置權限(開發用)**
   ```bash
   # 重置特定 app 的 Accessibility 權限
   tccutil reset Accessibility com.myhandle.myisland
   tccutil reset AppleEvents com.myhandle.myisland
   tccutil reset All com.myhandle.myisland  # 全重置
   ```

4. **Notifications 權限要先 import UserNotifications 才能請求**
   - 純 AppKit 的 `NSUserNotification` 已 deprecated

5. **使用者系統版本太舊**
   - macOS 14 以上才有 `NSScreen.safeAreaInsets`
   - macOS 13 以下要 fallback

---

## 我的實作計劃

- [ ] 建立 `PermissionChecker` 單例
  - [ ] 檢查 Accessibility、Automation、Notifications
  - [ ] 提供 `openSystemSettings()` 方法
- [ ] 設計「權限引導畫面」
  - [ ] 每種權限一張卡片,說明用途
  - [ ] 缺的標紅,有的標綠
  - [ ] 點擊卡片 → 跳到對應系統設定頁
- [ ] 啟動時檢查
  - [ ] 全部有 → 直接跑
  - [ ] 少核心權限 → 顯示引導
  - [ ] 少次要權限 → 提示但允許進入
- [ ] 寫 `install-dev.sh` 腳本給開發用

---

## 延伸學習資源

- [Apple — About TCC(Transparency, Consent, and Control)](https://support.apple.com/guide/mac-help/allow-apps-to-request-to-access-your-data-mchl55f7dae7/mac) — 對使用者的說明(反向理解 TCC 存在的目的)
- [Apple — NSAccessibility](https://developer.apple.com/documentation/appkit/nsaccessibility)
- [Apple — UNUserNotificationCenter](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)

---

## 完成檢核

- [ ] 列出你的 app 需要的所有權限
- [ ] 每個權限都在 Info.plist 有對應 UsageDescription
- [ ] 了解 TCC 怎麼「認」你的 app
- [ ] 知道開發時 Debug 重編為何會失去權限、怎麼避免
- [ ] 能寫 Swift code 檢查 Accessibility 權限
- [ ] 能寫 Swift code 開啟系統設定對應頁面
- [ ] 設計了權限缺失時的 fallback UI
- [ ] 知道 `tccutil reset` 可以強制重置(開發除錯)
