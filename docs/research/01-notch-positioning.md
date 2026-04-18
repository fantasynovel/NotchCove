# 黑盒 1:App 怎麼住在瀏海裡?

> **狀態**:🟡 Draft(預填已知資訊,待親手實驗)
> **對應 Phase**:4.75 — 逆向工程
> **最後更新**:[實驗完填日期]

---

## 這個黑盒是什麼?

瀏海(notch)是 MacBook 螢幕頂部那塊裝相機的黑色凹槽。macOS **沒有官方 API** 讓 app「住在瀏海裡」,但 CodeIsland、MioIsland 都做到了。

這份筆記拆解它是怎麼做到的。

---

## 最關鍵的三個問題

1. 要用什麼類型的視窗?(普通視窗達不到)
2. 要怎麼偵測當前螢幕有沒有瀏海、瀏海多寬?
3. 外接螢幕沒瀏海時怎麼處理?

---

## 已知的技術線索

### 1. 視窗類型:`NSPanel`(不是 `NSWindow`)

`NSPanel` 是 `NSWindow` 的子類別,特性:
- 輕量(不搶焦點,不出現在 Dock)
- 可以一直浮在上層
- 關閉 app 時不會擋住退出

### 2. 視窗層級:`.screenSaver`

macOS 有「視窗層級」(window level)的概念,從低到高大致是:

```
normal(一般 app 視窗)
  ↓
floating(浮動小工具)
  ↓
submenu(下拉選單)
  ↓
mainMenu(選單列)
  ↓
statusBar(狀態列圖示)
  ↓
popupMenu(popup 選單)
  ↓
screenSaver  ← 我們要用這個!
```

設成 `.screenSaver` 的視窗會比選單列、Dock 都高,**真的蓋在瀏海上面**。

```swift
// 預期看到的 code
panel.level = .screenSaver
// 或者等價的數值
panel.level = NSWindow.Level(rawValue: 1000)
```

### 3. 偵測瀏海:`NSScreen.safeAreaInsets.top`

macOS 14 後,`NSScreen` 有個 `safeAreaInsets` 屬性:

```swift
if let screen = NSScreen.main {
    let topInset = screen.safeAreaInsets.top
    // 0 → 沒瀏海
    // > 0 → 有瀏海,數值是瀏海高度(pt)
}
```

常見數值:
- MacBook Air M2:38 pt
- MacBook Pro 14"(2021+):[親手實驗後填]
- MacBook Pro 16"(2021+):[親手實驗後填]
- 外接螢幕:0

### 4. 偵測瀏海「寬度」:沒有官方 API

這個最鳥——Apple 不給你瀏海的寬度(只給高度)。實務做法:

**做法 A:查表**
根據 Mac 型號硬編碼:
```swift
// 預期 code 結構
let notchWidth: CGFloat = {
    let model = getHardwareModel()  // e.g. "MacBookPro18,3"
    switch model {
    case "Mac14,2":   return 200  // Air M2
    case "Mac15,7":   return 205  // Pro 14" M3
    // ...
    }
}()
```

**做法 B:取螢幕中央動態量**
假設瀏海一定在螢幕水平中央,寬度用 safeArea 反推:

```swift
// 概念 code
let screenFrame = screen.frame
let safeFrame = screen.visibleFrame
// 左右 inset 可能給瀏海寬度線索
```

---

## 實際從 code 挖出來的事實

[親手實驗後填:跑完下面指令,把真實觀察到的東西貼進來]

### 檢查 CodeIsland 用什麼視窗

```bash
cd ~/Projects/my-island/Sources
grep -rn "NSPanel\|windowLevel\|\.level = \|\.screenSaver" --include="*.swift"
```

觀察到的:
```
[親手實驗後填]
```

### 檢查瀏海偵測邏輯

```bash
grep -rn "safeAreaInsets\|auxiliaryTopLeftArea\|notch" Sources/ --include="*.swift"
```

觀察到的:
```
[親手實驗後填]
```

### 檢查外接螢幕的降級

```bash
grep -rn "externalDisplay\|fallback\|topCenter\|NSScreen.screens" Sources/ --include="*.swift"
```

觀察到的:
```
[親手實驗後填]
```

---

## 自己跑一次 minimal demo

### Demo A:做一個住在瀏海的最小視窗

在你自己的 app 裡(不改 CodeIsland)驗證原理:

```swift
// ExperimentPanel.swift(寫在一個新的 test file)
import AppKit

class NotchTestPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 32),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.level = .screenSaver
        self.backgroundColor = .red     // 紅色看得清楚
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false

        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let x = screenFrame.midX - 100      // 水平置中
            let y = screenFrame.maxY - 32       // 貼齊頂部
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}

// 在 AppDelegate 裡
let panel = NotchTestPanel()
panel.orderFront(nil)
```

**[親手實驗後填]** 觀察:
- 紅色塊出現在預期位置嗎?
- 有切到瀏海邊緣嗎?
- 按一下會不會搶焦點?
- 切換 app 時會不會消失?

### Demo B:印出你 Mac 的 safeAreaInsets

```swift
for (i, screen) in NSScreen.screens.enumerated() {
    print("Screen \(i): \(screen.localizedName ?? "unknown")")
    print("  safeAreaInsets: \(screen.safeAreaInsets)")
    print("  frame: \(screen.frame)")
}
```

**[親手實驗後填]** 你看到的數值:
```
Screen 0: ...
  safeAreaInsets: NSEdgeInsets(top: X, left: Y, bottom: Z, right: W)
```

---

## 常見坑

1. **瀏海區域點不到滑鼠**
   - `ignoresMouseEvents = true` 會讓視窗收不到點擊
   - 但 `false` 又可能擋到其他 app
   - 進階做法:只在視窗展開時接收點擊

2. **外接螢幕黑掉**
   - `NSScreen.main` 只回傳「滑鼠所在」那個螢幕
   - 要用 `NSScreen.screens` 遍歷所有螢幕
   - 記得 observe `NSApplication.didChangeScreenParametersNotification`

3. **Debug 時視窗位置對不齊**
   - HiDPI 座標系統,pt 跟 pixel 不一樣
   - 用 `screen.backingScaleFactor` 轉換

4. **Notch 區域會有 app 自己的影子**
   - `hasShadow = false`
   - `isOpaque = false`

---

## 我的實作計劃

根據逆向工程理解,我要做的事:

- [ ] 建一個 `NotchPanel` 類別繼承 `NSPanel`
- [ ] 預設參數:`.borderless` + `.nonactivatingPanel` + 透明背景
- [ ] 寫一個 `NotchPositioner` 幫忙處理定位
  - [ ] 偵測當前顯示器有沒有瀏海
  - [ ] 有瀏海 → 對齊瀏海區域
  - [ ] 沒瀏海(外接螢幕) → 降級到螢幕頂部中央
  - [ ] Observe 螢幕變化事件(接/拔螢幕)
- [ ] 硬編碼幾個機型的瀏海寬度(先支援 M2/M3 Air & Pro)

---

## 延伸學習資源

官方文件(重要的讀這幾篇就夠):
- [NSPanel — Apple Developer](https://developer.apple.com/documentation/appkit/nspanel)
- [NSWindow.Level — Apple Developer](https://developer.apple.com/documentation/appkit/nswindow/level)
- [NSScreen.safeAreaInsets — Apple Developer](https://developer.apple.com/documentation/appkit/nsscreen/safeareainsets)

相關 repo 可看(記得 license 限制):
- CodeIsland(主骨架,可抄)
- claude-island(Apache 2.0,可抄)
- open-vibe-island(**只看 docs**,不 copy code)

---

## 完成檢核

- [ ] Demo A 在你的 Mac 成功跑起來
- [ ] 知道怎麼做出「住在瀏海」的視窗
- [ ] 知道為什麼要用 NSPanel 而不是 NSWindow
- [ ] 理解 `.screenSaver` 這個層級做什麼
- [ ] 能解釋:插拔外接螢幕時 app 該怎麼反應
