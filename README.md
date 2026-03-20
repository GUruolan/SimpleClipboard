# SimpleClipboard

一个简洁优雅的 macOS 菜单栏剪贴板历史管理工具。

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ 特性

### 核心功能
- 📋 **自动记录剪贴板历史**（最多 50 条）
- 🔍 **实时搜索过滤**
- ⌨️ **全局快捷键唤起**（Control + Shift + Space）
- 💾 **数据持久化**（重启不丢失）
- 🔒 **智能隐私保护**（自动过滤密码/Token）
- 🎨 **简洁 UI**（菜单栏图标，无 Dock 图标）

### 交互方式
- **键盘导航**: `↑` `↓` 选择，`Enter` 复制
- **鼠标操作**: 点击复制，悬停显示删除按钮
- **搜索**: 输入关键词实时过滤

---

## 🚀 快速开始

### 系统要求
- macOS 13.0 (Ventura) 或更高版本
- Xcode 15.0+

### 安装步骤

1. **克隆仓库**
```bash
git clone https://github.com/yourusername/SimpleClipboard.git
cd SimpleClipboard
```

2. **打开项目**
```bash
open SimpleClipboard.xcodeproj
```

3. **编译运行**
- 选择目标设备为 "My Mac"
- 点击 `⌘ + R` 运行

4. **授予权限**（首次运行）
- 系统设置 → 隐私与安全性 → 辅助功能
- 添加 SimpleClipboard 并勾选

---

## 📖 使用指南

### 基本操作

| 操作 | 快捷键/方式 |
|------|------------|
| 打开历史窗口 | `Control + Shift + Space` |
| 向上选择 | `↑` 或鼠标悬停 |
| 向下选择 | `↓` 或鼠标悬停 |
| 复制选中项 | `Enter` 或点击 |
| 删除单条记录 | 鼠标悬停 → 点击 `×` |
| 清空所有历史 | 点击右上角垃圾桶图标 |
| 搜索 | 直接输入文字 |

### 隐私保护

应用会自动跳过以下类型的内容：

1. **疑似密码**
   - 8-32 字符，包含字母、数字、特殊符号

2. **长 Token**
   - 超过 40 字符且无空格的字符串

3. **敏感关键词**
   - 包含 `password`, `token`, `api_key`, `secret`, `密码`, `令牌`

---

## 🛠️ 开发

### 项目结构

```
SimpleClipboard/
├── SimpleClipboardApp.swift      # 应用入口
├── ContentView.swift              # 主界面
├── ClipboardManager.swift         # 剪贴板管理器
├── AppDelegate.swift              # 全局快捷键
├── Assets.xcassets/               # 图标资源
└── SimpleClipboard.entitlements   # 权限配置
```

### 核心类说明

#### `ClipboardManager`
- **职责**: 监控剪贴板变化，管理历史记录
- **关键方法**:
  - `checkPasteboard()`: 检测剪贴板变化
  - `isSensitive()`: 敏感内容过滤
  - `saveHistory()` / `loadHistory()`: 持久化

#### `ContentView`
- **职责**: UI 渲染，键盘事件处理
- **关键状态**:
  - `selectedIndex`: 当前选中项索引
  - `searchText`: 搜索关键词
  - `filteredHistory`: 过滤后的历史记录

#### `AppDelegate`
- **职责**: 全局快捷键注册
- **快捷键**: Control + Shift + Space

---

## ⚙️ 配置

### 修改快捷键

编辑 `AppDelegate.swift:17-30`：

```swift
// 示例：改为 Command + Shift + V
let hasCommand = event.modifierFlags.contains(.command)
let hasShift = event.modifierFlags.contains(.shift)
let isVKey = event.keyCode == 9  // V 键

if isVKey && hasCommand && hasShift {
    self?.toggleMenuBarExtra()
}
```

### 修改历史记录上限

编辑 `ClipboardManager.swift:5`：

```swift
private let maxHistoryCount = 50  // 改为你想要的数量
```

### 修改敏感词规则

编辑 `ClipboardManager.swift:52-74`：

```swift
let sensitiveKeywords = ["password", "token", "你的关键词"]
```

---

## 🐛 已知问题

1. **全局快捷键不生效**
   - 原因：未授予"辅助功能"权限
   - 解决：系统设置 → 隐私与安全性 → 辅助功能 → 添加应用

2. **快捷键冲突**
   - 原因：与输入法或其他应用冲突
   - 解决：修改快捷键（见上方配置说明）

3. **搜索时键盘导航失效**
   - 原因：搜索框获取了焦点
   - 解决：点击列表区域恢复焦点

---

## 🗺️ 路线图

### v1.1 (计划中)
- [ ] 自定义快捷键设置界面
- [ ] 时间戳显示
- [ ] 图片/文件支持
- [ ] 导出/导入历史记录

### v1.2 (未来)
- [ ] iCloud 同步
- [ ] 分组管理
- [ ] 智能推荐（AI 辅助）

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 贡献步骤
1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

---

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

## 🙏 致谢

- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - 现代化 UI 框架
- [AppKit](https://developer.apple.com/documentation/appkit) - macOS 原生 API

---

## 📧 联系方式

- 作者: Navy
- 邮箱: your.email@example.com
- 问题反馈: [GitHub Issues](https://github.com/yourusername/SimpleClipboard/issues)

---

**⭐ 如果觉得有用，请给个 Star！**
