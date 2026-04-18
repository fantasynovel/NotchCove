# 黑盒 3:Unix Socket——兩個程式怎麼對話?

> **狀態**:🟡 Draft(預填已知資訊,待親手實驗)
> **對應 Phase**:4.75 — 逆向工程
> **最後更新**:[實驗完填日期]

---

## 這個黑盒是什麼?

你的主 app 長時間跑著,hook 腳本跑一下就結束。兩者是**完全獨立的程式**,怎麼互傳訊息?

答案:**Unix Domain Socket**(Unix 網域通訊端,簡稱 Unix socket)。

---

## 最關鍵的三個問題

1. Unix socket 跟一般檔案有什麼不同?
2. 為什麼不用 TCP/HTTP?
3. 訊息格式怎麼設計?

---

## 白話解釋

### 用比喻

想像 Unix socket 是**兩根電話聽筒中間的傳話繩**:

```
  App(listener)                  Hook(client)
   🎙️ ═════════════════════════ 🎙️
        /tmp/xxx.sock 這條線

  A 拿起來說：「我在聽」         B 拿起來說：「有事找你」
  B 說話 A 就聽到                A 回答 B 就聽到
```

- `/tmp/xxx.sock` 是「線兩端的連接點」(就是個特殊檔案)
- 誰先「拿起聽筒」誰就是 listener(server 端)
- 另一邊連上來的是 client 端

### 跟一般檔案的差別

```bash
ls -la /tmp/codeisland-501.sock
# srwx------  1 you staff  0 Apr 18 10:00 /tmp/codeisland-501.sock
# ↑ 注意是 's' 不是 '-'
```

第一個字母是檔案類型:
- `-`:普通檔案
- `d`:目錄
- `l`:symlink
- **`s`:socket ← 我們要講的**

一般檔案是「寫下來存著」,socket 是「寫進去就立刻到對方」。**沒有「存在磁碟」這件事**(雖然路徑在 `/tmp`,實際資料不落地)。

### 為什麼不用 TCP/HTTP?

| 維度 | Unix socket | TCP |
|---|---|---|
| 範圍 | 只在本機 | 可以跨網路 |
| 速度 | 快(沒經過網路協定層) | 慢 |
| 安全 | 用檔案權限保護 | 要 TLS、auth |
| 複雜度 | 簡單(讀寫 bytes) | 要處理 IP、port、斷線重連 |

**你的需求是 App ↔ Hook 同機溝通,Unix socket 完美符合**,沒理由用 TCP。

---

## 實作上的三個核心問題

### 1. Socket 檔案路徑選哪裡?

常見慣例:

**選項 A**:`/tmp/yourapp-{UID}.sock`
- 簡單、可預測
- `{UID}` 是使用者 ID,多使用者系統不會打架

**選項 B**:`$XDG_RUNTIME_DIR/yourapp.sock`(Linux 慣例)
- macOS 沒這個環境變數,放棄

**選項 C**:`~/Library/Application Support/YourApp/socket`
- 應該避免。macOS `~/Library` 路徑有長度限制,socket path 超過 ~100 字會悄悄截斷

**CodeIsland 實際用的**:`/tmp/codeisland-{UID}.sock`

### 2. 權限怎麼設?

預設建立的 socket 檔權限可能太寬:

```bash
# 這樣別的使用者可以連進來送假事件
srw-rw-rw-
```

正確應該設成 `0600`(只有 owner 可讀寫):

```swift
// Swift 端
chmod(path.cString(using: .utf8), 0o600)
```

### 3. 訊息格式

三種常見選擇:

**A. Line-delimited JSON**(推薦,CodeIsland 用的)
```
{"event":"PreToolUse","data":...}\n
{"event":"PostToolUse","data":...}\n
```
- 每行一個 JSON
- 解析簡單:`readLine()` → `JSON.parse()`

**B. 長度前綴**
```
[4 bytes: length][payload bytes]
```
- 更精準但複雜

**C. Protobuf / MessagePack**
- 高效能但小題大作,你的事件量不高

---

## 實驗 A:找出 CodeIsland 用的 socket

```bash
# 先讓 CodeIsland 跑起來
open ~/Projects/my-island/.build/debug/CodeIsland.app

# 列出所有 socket 檔
ls -la /tmp/*.sock 2>/dev/null

# 看你 Mac 的 UID
id -u

# 找到對應的 socket
ls -la /tmp/codeisland-$(id -u).sock
```

[親手實驗後填]
```
socket 路徑:/tmp/...
權限:srwx------
建立時機:[CodeIsland 啟動時/其他]
```

---

## 實驗 B:用 nc 窺探 socket 訊息

`nc`(netcat)可以直接連上 Unix socket 看流量:

### 連上看訊息

```bash
# 這會「截斷」CodeIsland 的監聽,所以先關掉 CodeIsland!
killall CodeIsland

# 自己跑一個 listener 替代它
nc -lU /tmp/codeisland-$(id -u).sock
```

現在另開一個 terminal,隨便跑個 Claude Code 動作(會觸發 hook):

```bash
claude
> ls
```

你的 `nc` 那邊應該會看到 hook 送來的 JSON。

[親手實驗後填] 觀察到的訊息:
```json
[貼一個實際收到的訊息]
```

實驗完 `Ctrl+C` 停掉 nc,刪掉 socket 檔讓 CodeIsland 可以自己重建:
```bash
rm /tmp/codeisland-$(id -u).sock
```

---

## 實驗 C:寫你自己的 echo server

這是理解 socket 最快的方法。

### Python 版

```bash
mkdir ~/socket-test && cd ~/socket-test

cat > server.py <<'EOF'
import socket, os

path = "/tmp/myapp-test.sock"

# 清掉舊的
if os.path.exists(path):
    os.unlink(path)

# 建立 socket
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.bind(path)
os.chmod(path, 0o600)
s.listen()

print(f"Listening on {path}")
print("From another terminal:")
print(f"  echo 'hello' | nc -U {path}")
print()

while True:
    conn, _ = s.accept()
    data = conn.recv(1024)
    print(f"[SERVER] Received: {data.decode().strip()}")
    conn.send(b"echo: " + data)
    conn.close()
EOF

# 跑起來
python3 server.py
```

### 另開終端測試

```bash
echo "hello socket world" | nc -U /tmp/myapp-test.sock
# 應該收到:echo: hello socket world
```

你剛剛做的事:
1. **Server** 開了一個 Unix socket 在 `/tmp/myapp-test.sock` 聽
2. **Client**(nc)連上來,傳了一段 bytes
3. Server 收到、處理、回傳
4. Client 收到回應

**這就是 CodeIsland 和 hook 的基本模型**。差別只在:
- 訊息是 JSON 不是純文字
- Server 不是 Python,是 Swift
- 真實情境會同時有多個 client 連進來

---

## 實驗 D:多連線

真實場景會有多個 hook 同時觸發。改改 server 讓它能處理並發:

```python
# 加在 accept 迴圈裡改用 threading
import threading

def handle(conn):
    data = conn.recv(1024)
    print(f"[SERVER] Got: {data.decode().strip()}")
    conn.send(b"ok\n")
    conn.close()

while True:
    conn, _ = s.accept()
    threading.Thread(target=handle, args=(conn,), daemon=True).start()
```

---

## Swift 端實作速寫(預覽)

```swift
import Foundation
import Network

class SocketServer {
    let path: String
    var listener: NWListener?

    init(path: String) {
        self.path = path
    }

    func start() throws {
        // 用 NWListener(Network.framework,macOS 10.14+)
        let params = NWParameters.tcp  // 其實是 Unix socket,framework 會處理
        let endpoint = NWEndpoint.unix(path: path)
        let listener = try NWListener(using: params, on: endpoint)

        listener.newConnectionHandler = { conn in
            conn.start(queue: .main)
            self.receive(on: conn)
        }

        listener.start(queue: .main)
        self.listener = listener
    }

    func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) {
            data, _, isComplete, error in
            if let data = data, let text = String(data: data, encoding: .utf8) {
                print("Got: \(text)")
                // parse JSON, dispatch event
            }
            if !isComplete {
                self.receive(on: connection)  // 繼續收
            }
        }
    }
}
```

⚠️ `NWListener` 的 Unix socket 支援在某些 macOS 版本有 bug。退而求其次可以用傳統 BSD socket API,或 Swift package `SwiftNIO`。

---

## 實驗 E:看 CodeIsland 的 socket 實作

```bash
cd ~/Projects/my-island/Sources
grep -rn "NWListener\|AF_UNIX\|Unix\|\.sock\|socket(" --include="*.swift"
```

[親手實驗後填] 觀察到:
```
用的 API:[NWListener / BSD socket / SwiftNIO / 其他]
檔案路徑產生邏輯:[親手看填]
訊息格式:[line-delimited JSON / 其他]
並發處理方式:[queue / thread / actor]
```

---

## 常見坑

1. **socket 檔殘留**
   - App crash 沒清乾淨 → 下次啟動 bind 失敗
   - 解法:啟動時先 `unlink` 舊檔

2. **權限不對**
   - 預設 `0666` 任何使用者可連 → 安全問題
   - 啟動後 `chmod 0600`

3. **客戶端斷線沒處理**
   - Hook 腳本 crash 中斷連線 → server 要處理 EOF 和 error
   - 不處理會資源洩漏

4. **路徑太長**
   - Unix socket path 上限 macOS 約 104 字元
   - 用 `/tmp/...` 最安全

5. **寫入被 buffer 住沒送出**
   - Swift 或 Python 寫完 `flush()`,不然對方收不到
   - 或用 line-delimited + 每行 flush

---

## 我的實作計劃

- [ ] 定義我的 socket 路徑:`/tmp/myisland-{UID}.sock`
- [ ] 訊息格式:line-delimited JSON
- [ ] App 端:
  - [ ] 啟動時清舊 socket
  - [ ] 開 NWListener(或 fallback BSD socket)
  - [ ] chmod 0600
  - [ ] 多連線 handler
- [ ] Hook 端(CLI binary):
  - [ ] 讀 stdin
  - [ ] 連到 socket
  - [ ] 送 JSON
  - [ ] 讀回應(如果需要)
  - [ ] 依回應 exit
- [ ] App 關掉時清 socket 檔

---

## 延伸學習資源

- [Apple — Network framework](https://developer.apple.com/documentation/network)
- [man 2 socket](https://man.openbsd.org/socket.2)(BSD 原始 API,底層原理)
- [SwiftNIO](https://github.com/apple/swift-nio)(Apple 官方高階 networking library)

---

## 完成檢核

- [ ] Demo C 跑成功:自己寫的 Python echo server 會 echo
- [ ] 能解釋為什麼 Unix socket 比 TCP 適合這情境
- [ ] 知道 CodeIsland 用哪個 API、訊息格式是什麼
- [ ] 理解 socket 權限為何要 `0600`
- [ ] 能解釋「殘留 socket 檔」的問題和解法
