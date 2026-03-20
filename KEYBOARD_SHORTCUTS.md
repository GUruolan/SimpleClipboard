# ⌨️ 键盘快捷键配置指南

## 当前快捷键

| 功能 | 快捷键 | 说明 |
|------|--------|------|
| 打开/关闭窗口 | `Control + Shift + Space` | 全局快捷键 |
| 向上选择 | `↑` | 需要窗口激活 |
| 向下选择 | `↓` | 需要窗口激活 |
| 复制选中项 | `Enter` | 需要窗口激活 |

---

## 修改全局快捷键

### 方案 1: Command + Shift + V (推荐)

这是最符合 macOS 习惯的组合键，类似于"粘贴并匹配样式"。

**步骤**:

1. 打开 `AppDelegate.swift`
2. 找到第 17-30 行
3. 替换为以下代码：

```swift
NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
    // 检查 Command 键
    let hasCommand = event.modifierFlags.contains(.command)
    // 检查 Shift 键
    let hasShift = event.modifierFlags.contains(.shift)
    // 检查 V 键 (KeyCode 9)
    let isVKey = event.keyCode == 9

    // 精确匹配 Command + Shift + V
    if isVKey && hasCommand && hasShift {
        self?.toggleMenuBarExtra()
    }
}
```

---

### 方案 2: Option + Space

简洁的单修饰键组合，避免多键冲突。

```swift
NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
    let hasOption = event.modifierFlags.contains(.option)
    let isSpaceKey = event.keyCode == 49

    if isSpaceKey && hasOption {
        self?.toggleMenuBarExtra()
    }
}
```

---

### 方案 3: Control + Command + C

双修饰键 + C（Clipboard 的首字母）。

```swift
NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
    let hasControl = event.modifierFlags.contains(.control)
    let hasCommand = event.modifierFlags.contains(.command)
    let isCKey = event.keyCode == 8

    if isCKey && hasControl && hasCommand {
        self?.toggleMenuBarExtra()
    }
}
```

---

## 常用按键 KeyCode 对照表

| 按键 | KeyCode | 说明 |
|------|---------|------|
| A | 0 | |
| S | 1 | |
| D | 2 | |
| F | 3 | |
| H | 4 | |
| G | 5 | |
| Z | 6 | |
| X | 7 | |
| C | 8 | |
| V | 9 | |
| B | 11 | |
| Q | 12 | |
| W | 13 | |
| E | 14 | |
| R | 15 | |
| Y | 16 | |
| T | 17 | |
| 1 | 18 | |
| 2 | 19 | |
| 3 | 20 | |
| 4 | 21 | |
| 5 | 23 | |
| 6 | 22 | |
| 7 | 26 | |
| 8 | 28 | |
| 9 | 25 | |
| 0 | 29 | |
| Return | 36 | 回车键 |
| Tab | 48 | Tab 键 |
| Space | 49 | 空格键 |
| Delete | 51 | 删除键 |
| Escape | 53 | ESC 键 |
| F1 | 122 | |
| F2 | 120 | |
| F3 | 99 | |
| F4 | 118 | |
| F5 | 96 | |

---

## 修饰键对照表

| 修饰键 | Swift 代码 | 说明 |
|--------|-----------|------|
| Command | `.command` | ⌘ |
| Shift | `.shift` | ⇧ |
| Option | `.option` | ⌥ (Alt) |
| Control | `.control` | ⌃ |
| Function | `.function` | Fn |
| CapsLock | `.capsLock` | ⇪ |

---

## 检测快捷键冲突

### 系统快捷键

检查是否与系统快捷键冲突：

1. 打开 **系统设置** → **键盘** → **键盘快捷键**
2. 查看各类别的快捷键
3. 避免使用已占用的组合

### 常见冲突快捷键

| 快捷键 | 系统功能 |
|--------|---------|
| `Command + Space` | Spotlight 搜索 |
| `Control + Space` | 输入法切换 |
| `Command + Tab` | 应用切换 |
| `Command + Shift + 3/4/5` | 截图 |
| `Control + ↑/↓` | Mission Control |

---

## 自定义窗口内快捷键

如果你想修改窗口内的键盘导航：

编辑 `ContentView.swift:101-124`：

```swift
// 示例：使用 J/K 代替上下箭头（Vim 风格）
.onKeyPress(.init(character: "j")) {
    if selectedIndex < filteredHistory.count - 1 {
        selectedIndex += 1
    }
    return .handled
}

.onKeyPress(.init(character: "k")) {
    if selectedIndex > 0 {
        selectedIndex -= 1
    }
    return .handled
}
```

---

## 调试快捷键

如果快捷键不生效，添加调试日志：

```swift
NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
    // 打印所有按键事件
    print("KeyCode: \(event.keyCode), Modifiers: \(event.modifierFlags)")

    // 你的快捷键逻辑...
}
```

运行应用后，按下任意键查看终端输出，找到你想要的 KeyCode。

---

## 权限问题

### 辅助功能权限

全局快捷键需要"辅助功能"权限：

1. **系统设置** → **隐私与安全性** → **辅助功能**
2. 点击 `+` 添加 SimpleClipboard
3. 勾选启用

### 检查权限代码

在 `AppDelegate.swift` 的 `applicationDidFinishLaunching` 中添加：

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // 检查辅助功能权限
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)

    if !accessEnabled {
        print("⚠️ 需要辅助功能权限才能使用全局快捷键")
    }

    // 注册全局快捷键...
}
```

---

## 推荐配置

根据使用场景选择：

### 场景 1: 频繁使用
- **推荐**: `Command + Shift + V`
- **理由**: 单手操作，符合 macOS 习惯

### 场景 2: 避免冲突
- **推荐**: `Control + Command + C`
- **理由**: 双修饰键，冲突概率低

### 场景 3: 快速访问
- **推荐**: `Option + Space`
- **理由**: 最少按键，最快响应

---

## 常见问题

### Q1: 快捷键按了没反应？
**A**: 检查以下几点：
1. 是否授予"辅助功能"权限
2. 是否与其他应用冲突
3. 应用是否在运行

### Q2: 快捷键与输入法冲突？
**A**: 避免使用 `Control + Space` 或 `Command + Space`，改用其他组合。

### Q3: 如何禁用全局快捷键？
**A**: 注释掉 `AppDelegate.swift` 中的 `NSEvent.addGlobalMonitorForEvents` 代码块。

### Q4: 能否支持多个快捷键？
**A**: 可以，添加多个 `if` 条件判断：

```swift
NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
    // 快捷键 1: Command + Shift + V
    if event.keyCode == 9 && event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) {
        self?.toggleMenuBarExtra()
    }

    // 快捷键 2: Option + Space
    if event.keyCode == 49 && event.modifierFlags.contains(.option) {
        self?.toggleMenuBarExtra()
    }
}
```

---

**最后更新**: 2026-03-20
**作者**: Claude Code 🤖
