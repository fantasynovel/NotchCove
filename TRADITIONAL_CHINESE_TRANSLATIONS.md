# 繁體中文翻譯對照表

此文件列出 `Sources/Notch Cove/L10n.swift` 中所有簡體中文（`zh`）的字串，並提供初版繁體中文（`zh-Hant`）翻譯供審閱與修改。

- 翻譯風格預設貼近台灣 macOS 使用者慣用語（菜單欄 → 選單列、视频 → 影片、默認 → 預設、网络 → 網路、软件 → 軟體、字体 → 字型、刘海 → 瀏海…）。
- 若香港/其他地區用語偏好不同，請直接在「繁體中文」欄修改；之後可再同步回 `L10n.swift` 的 `zh-Hant` 字典。
- 表格欄位：`Key`（程式識別字）/ `简体中文`（現況）/ `繁體中文`（草稿）。

## Settings 分頁

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| general | 通用 | 一般 |
| behavior | 行为 | 行為 |
| appearance | 外观 | 外觀 |
| mascots | 角色 | 角色 |
| sound | 声音 | 聲音 |
| remote | 远程 | 遠端 |
| hooks | Hooks | Hooks |
| about | 关于 | 關於 |

## 語言

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| language | 语言 | 語言 |
| system_language | 跟随系统 | 系統預設 |

## General（通用）

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| launch_at_login | 登录时打开 | 登入時開啟 |
| allow_horizontal_drag | 允许水平拖动面板 | 允許水平拖曳面板 |
| allow_horizontal_drag_desc | 开启后可沿菜单栏左右拖动面板位置 | 開啟後可沿選單列左右拖曳面板位置 |
| display | 显示器 | 顯示器 |
| auto | 自动 | 自動 |
| builtin_display | 内建显示器 | 內建顯示器 |
| notch | (刘海) | (瀏海) |

## Behavior（行為）

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| display_section | 显示 | 顯示 |
| hide_in_fullscreen | 全屏时隐藏 | 全螢幕時隱藏 |
| hide_in_fullscreen_desc | 当任意应用进入全屏模式时自动隐藏面板 | 當任一應用程式進入全螢幕模式時自動隱藏面板 |
| hide_when_no_session | 无活跃会话时自动隐藏 | 無活躍工作階段時自動隱藏 |
| hide_when_no_session_desc | 没有 AI Agent 运行时完全隐藏面板 | 沒有 AI Agent 執行時完全隱藏面板 |
| smart_suppress | 智能抑制 | 智慧抑制 |
| smart_suppress_desc | Agent 所在终端标签页在前台时不自动展开面板 | Agent 所在終端機分頁在前景時不自動展開面板 |
| collapse_on_mouse_leave | 鼠标离开时自动收起 | 滑鼠離開時自動收合 |
| collapse_on_mouse_leave_desc | 鼠标移出展开的面板后自动收回到刘海状态 | 滑鼠移出展開的面板後自動收回瀏海狀態 |
| auto_collapse_after_session_jump | 点击跳转会话后自动收起面板 | 點擊跳轉工作階段後自動收合面板 |
| auto_collapse_after_session_jump_desc | 点击会话并成功切换到对应终端/客户端后自动收起面板 | 點擊工作階段並成功切換到對應終端機/用戶端後自動收合面板 |
| haptic_on_hover | 悬停触控板震动 | 懸停觸控板震動 |
| haptic_on_hover_desc | 鼠标悬停在刘海上时触发触控板震动反馈 | 滑鼠懸停在瀏海上時觸發觸控板震動回饋 |
| haptic_light | 轻 | 輕 |
| haptic_medium | 中 | 中 |
| haptic_strong | 强 | 強 |
| shortcuts | 快捷键 | 快捷鍵 |
| shortcut_recording | 请按下快捷键… | 請按下快捷鍵… |
| shortcut_none | 未设置 | 未設定 |
| shortcut_togglePanel | 切换面板 | 切換面板 |
| shortcut_togglePanel_desc | 展开或收起面板 | 展開或收合面板 |
| shortcut_approve | 批准 | 核准 |
| shortcut_approve_desc | 批准当前权限请求 | 核准目前的權限請求 |
| shortcut_approveAlways | 始终批准 | 總是核准 |
| shortcut_approveAlways_desc | 批准并记住本次会话 | 核准並記住本次工作階段 |
| shortcut_deny | 拒绝 | 拒絕 |
| shortcut_deny_desc | 拒绝当前权限请求 | 拒絕目前的權限請求 |
| shortcut_skipQuestion | 跳过问题 | 略過問題 |
| shortcut_skipQuestion_desc | 跳过当前问答提示 | 略過目前的問答提示 |
| shortcut_jumpToTerminal | 跳转终端 | 跳轉終端機 |
| shortcut_jumpToTerminal_desc | 切换到当前活跃会话的终端 | 切換到目前活躍階段的終端機 |
| shortcut_conflict | 与以下快捷键冲突: | 與下列快捷鍵衝突： |
| sessions | 会话 | 工作階段 |
| session_cleanup | 空闲会话清理 | 閒置工作階段清理 |
| session_cleanup_desc | 自动移除超过指定时间没有活动的会话 | 自動移除超過指定時間沒有活動的工作階段 |
| no_cleanup | 不清理 | 不清理 |
| 10_minutes | 10 分钟 | 10 分鐘 |
| 30_minutes | 30 分钟 | 30 分鐘 |
| 1_hour | 1 小时 | 1 小時 |
| 2_hours | 2 小时 | 2 小時 |
| rotation_interval | 会话轮转间隔 | 工作階段輪替間隔 |
| rotation_interval_desc | 收缩状态下多个活跃会话之间的切换频率 | 收合狀態下多個活躍工作階段之間的切換頻率 |
| 3_seconds | 3 秒 | 3 秒 |
| 5_seconds | 5 秒 | 5 秒 |
| 8_seconds | 8 秒 | 8 秒 |
| 10_seconds | 10 秒 | 10 秒 |
| tool_history_limit | 工具历史上限 | 工具歷史上限 |
| tool_history_limit_desc | 每个会话显示的最近工具调用数量上限 | 每個工作階段顯示的最近工具呼叫數量上限 |

## Appearance（外觀）

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| preview | 预览 | 預覽 |
| panel | 面板 | 面板 |
| max_visible_sessions | 最大显示会话数 | 最大顯示工作階段數 |
| max_visible_sessions_desc | 超出数量的会话将通过滚动查看 | 超出數量的工作階段將透過捲動檢視 |
| collapsed_width_scale | 灵动岛宽度 | 動態島寬度 |
| collapsed_width_scale_desc | 调整灵动岛收起宽度（100% 对齐物理刘海） | 調整動態島收合寬度（100% 對齊實體瀏海） |
| notch_layout_mode | 灵动岛布局 | 動態島版面 |
| notch_layout_mode_desc | 延伸模式在刘海两侧显示状态；紧凑模式将内容完全收进物理刘海范围 | 延伸模式在瀏海兩側顯示狀態；緊湊模式將內容完全收進實體瀏海範圍 |
| notch_layout_extended | 延伸 | 延伸 |
| notch_layout_compact | 紧凑 | 緊湊 |
| notch_height_mode | 顶部高度对齐 | 頂部高度對齊 |
| notch_height_mode_desc | 让面板与真实 notch 高度、菜单栏高度或自定义值对齐 | 讓面板與實際 notch 高度、選單列高度或自訂值對齊 |
| notch_height_match_notch | 对齐 notch 高度 | 對齊 notch 高度 |
| notch_height_match_menubar | 对齐菜单栏高度 | 對齊選單列高度 |
| notch_height_custom | 自定义高度 | 自訂高度 |
| custom_notch_height | 自定义高度 | 自訂高度 |
| default | 默认 | 預設 |
| content | 内容 | 內容 |
| content_font_size | 内容字体大小 | 內容字型大小 |
| 11pt_default | 11pt (默认) | 11pt（預設） |
| ai_reply_lines | AI 回复行数 | AI 回覆行數 |
| 1_line_default | 1 行 (默认) | 1 行（預設） |
| 2_lines | 2 行 | 2 行 |
| 3_lines | 3 行 | 3 行 |
| 5_lines | 5 行 | 5 行 |
| unlimited | 不限制 | 不限制 |
| show_agent_details | 显示代理活动详情 | 顯示代理活動詳情 |
| show_tool_status | 紧凑栏显示工具调用详情 | 緊湊列顯示工具呼叫詳情 |

## Mascots（角色）

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| preview_status | 预览状态 | 預覽狀態 |
| processing | 工作中 | 工作中 |
| idle | 空闲 | 閒置 |
| waiting_approval | 等待审批 | 等待核准 |
| mascot_speed | 动画速度 | 動畫速度 |
| speed_off | 关闭 | 關閉 |
| speed_slow | 0.5× 慢速 | 0.5× 慢速 |
| speed_normal | 1× 正常 | 1× 正常 |
| speed_fast | 1.5× 快速 | 1.5× 快速 |
| speed_very_fast | 2× 极速 | 2× 極速 |

## Sound（聲音）

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| enable_sound | 启用音效 | 啟用音效 |
| volume | 音量 | 音量 |
| session_start | 会话开始 | 工作階段開始 |
| new_claude_session | 新的 Claude Code 会话 | 新的 Claude Code 工作階段 |
| task_complete | 任务完成 | 任務完成 |
| ai_completed_reply | AI 完成了本轮回复 | AI 完成了本輪回覆 |
| task_error | 任务错误 | 任務錯誤 |
| tool_or_api_error | 工具失败或 API 错误 | 工具失敗或 API 錯誤 |
| system_section | 系统 | 系統 |
| boot_sound | 启动音效 | 啟動音效 |
| boot_sound_desc | Notch Cove 启动时播放提示音 | Notch Cove 啟動時播放提示音 |
| interaction | 交互 | 互動 |
| approval_needed | 需要审批 | 需要核准 |
| waiting_approval_desc | 等待权限审批或回答问题 | 等待權限核准或回答問題 |
| task_confirmation | 任务确认 | 任務確認 |
| you_sent_message | 你发送了一条消息 | 你送出了一則訊息 |
| custom_sound | 自定义 | 自訂 |
| choose_sound_file | 选择音效文件 | 選擇音效檔案 |
| reset_to_default | 恢复默认 | 恢復預設 |
| custom_sound_set | 自定义: %@ | 自訂：%@ |

## Hooks / Remote

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| cli_status | CLI 状态 | CLI 狀態 |
| activated | 已激活 | 已啟用 |
| not_installed | 未安装 | 未安裝 |
| not_detected | 未检测到 | 未偵測到 |
| management | 管理 | 管理 |
| reinstall | 重新安装 | 重新安裝 |
| uninstall | 卸载 | 解除安裝 |
| hooks_installed | Hooks 安装成功 | Hooks 安裝成功 |
| install_failed | 安装失败 | 安裝失敗 |
| hooks_uninstalled | Hooks 已卸载 | Hooks 已解除安裝 |
| remote_hosts | 远程主机 | 遠端主機 |
| remote_hosts_empty | 还没有远程主机。你可以在下方添加，通过 SSH 监控远程会话。 | 還沒有遠端主機。你可以在下方新增，透過 SSH 監控遠端工作階段。 |
| add_remote_host | 添加远程主机 | 新增遠端主機 |
| remote_name | 显示名称 | 顯示名稱 |
| remote_host | 主机名或 SSH 别名 | 主機名稱或 SSH 別名 |
| remote_user | SSH 用户（可选） | SSH 使用者（選填） |
| remote_port | SSH 端口（可选） | SSH 連接埠（選填） |
| remote_identity | 私钥文件（可选） | 私鑰檔案（選填） |
| remote_auth_socket | SSH_AUTH_SOCK（可选） | SSH_AUTH_SOCK（選填） |
| remote_auth_socket_placeholder | ~/.1password/agent.sock | ~/.1password/agent.sock |
| remote_auto_connect | 启动时自动连接 | 啟動時自動連線 |
| remote_add_button | 添加主机 | 新增主機 |
| remote_hint | 主机字段既可以填普通 hostname，也可以直接填 ~/.ssh/config 里的别名。Notch Cove 会在远端安装一个很小的 hook 脚本，并通过 SSH 转发事件回来。 | 主機欄位可以填一般 hostname，也可以直接填 ~/.ssh/config 裡的別名。Notch Cove 會在遠端安裝一個很小的 hook 腳本，並透過 SSH 轉發事件回來。 |
| remote_connect | 连接 | 連線 |
| remote_connecting | 连接中… | 連線中… |
| remote_connected | 已连接 | 已連線 |
| remote_disconnected | 未连接 | 未連線 |
| remote_disconnect | 断开 | 中斷連線 |
| remote_remove | 删除 | 刪除 |

## About（關於）

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| about_desc1 | macOS 实时 AI Agent 状态面板 | macOS 即時 AI Agent 狀態面板 |
| about_desc2 | 通过 Unix socket IPC 支持 11 种 CLI/IDE 工具 | 透過 Unix socket IPC 支援 11 種 CLI/IDE 工具 |

## Window

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| settings_title | Notch Cove 设置 | Notch Cove 設定 |

## Menu

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| settings_ellipsis | 设置... | 設定… |
| check_for_updates | 检查更新... | 檢查更新… |
| export_diagnostics | 导出诊断信息... | 匯出診斷資訊… |
| export_diagnostics_desc | 创建包含日志、设置和会话状态的 zip 文件，用于反馈 Bug | 建立包含記錄檔、設定與工作階段狀態的 zip 檔案，用於回報 Bug |
| reinstall_hooks | 重新安装 Hooks | 重新安裝 Hooks |
| remove_hooks | 卸载 Hooks | 解除安裝 Hooks |
| quit | 退出 | 結束 |

## Update（更新）

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| update_available_title | 发现新版本 | 發現新版本 |
| update_available_body | Notch Cove %@ 已发布（当前版本：%@），是否前往下载？ | Notch Cove %@ 已發佈（目前版本：%@），是否前往下載？ |
| download_update | 前往下载 | 前往下載 |
| later | 稍后 | 稍後 |
| no_update_title | 已是最新版本 | 已是最新版本 |
| no_update_body | Notch Cove %@ 已是最新版本。 | Notch Cove %@ 已是最新版本。 |
| ok | 好 | 好 |
| update_now | 立即更新 | 立即更新 |
| update_downloading | 正在下载更新... | 正在下載更新… |
| update_failed_title | 更新失败 | 更新失敗 |
| update_failed_body | 无法安装更新：%@ | 無法安裝更新：%@ |
| update_manual_download | 手动下载 | 手動下載 |
| update_installing | 正在安装更新... | 正在安裝更新… |
| update_retry | 重试 | 重試 |
| update_homebrew_title | 发现新版本 | 發現新版本 |
| update_homebrew_body | Notch Cove %@ 已发布。由于您通过 Homebrew 安装，请运行： | Notch Cove %@ 已發佈。由於您透過 Homebrew 安裝，請執行： |
| update_homebrew_command | brew upgrade Notch Cove | brew upgrade Notch Cove |
| update_copy_command | 复制命令 | 複製指令 |

## NotchPanel（面板）

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| mute | 静音 | 靜音 |
| enable_sound_tooltip | 开启音效 | 開啟音效 |
| settings | 设置 | 設定 |
| deny | 拒绝 | 拒絕 |
| dismiss | 忽略 | 忽略 |
| allow_once | 允许一次 | 允許一次 |
| always | 始终允许 | 總是允許 |
| approval_queue_label | 审批 %d/%d：%@ | 核准 %d/%d：%@ |
| approval_details_expand | 详情 | 詳情 |
| approval_details_collapse | 收起 | 收合 |
| type_answer | 输入回答… | 輸入回答… |
| skip | 跳过 | 略過 |
| back | 返回 | 返回 |
| confirm | 确认 | 確認 |
| submit | 提交 | 送出 |
| open_path | 打开 | 開啟 |
| copy_session_id | 复制会话 ID | 複製工作階段 ID |

## Session grouping（工作階段分組）

| Key | 简体中文 | 繁體中文 |
|---|---|---|
| status_running | 运行中 | 執行中 |
| status_waiting | 等待中 | 等待中 |
| status_processing | 处理中 | 處理中 |
| status_idle | 空闲 | 閒置 |
| other | 其他 | 其他 |
| n_sessions | 个会话 | 個工作階段 |
| scroll_for_more | 向下滚动查看更多 | 向下捲動查看更多 |
| scroll_hidden | 个未显示 | 個未顯示 |
| lines | 行 | 行 |

---

### 改完之後

1. 在此檔案直接修改第 3 欄（繁體中文）。
2. 告訴我要套用，我會把 `Sources/Notch Cove/L10n.swift` 的 `zh-Hant` 字典重新同步成最終版本。
