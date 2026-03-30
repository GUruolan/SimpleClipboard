# SimpleClipboard

一个简洁优雅的 macOS 剪贴板历史管理工具。

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ 核心功能

- 📋 **剪贴板历史** - 自动记录文本和图片（最多 50 条，图片限 10 张）
- 🔍 **实时搜索** - 输入关键词即时过滤
- ⌨️ **全局快捷键** - `Command + Shift + V` 唤起面板
- 🖥️ **多屏多桌面** - 自动在当前屏幕和桌面显示
- 🎯 **桌面切换** - `Command + ←/→` 快速切换桌面
- 💾 **数据持久化** - 历史记录自动保存
- 🔒 **隐私保护** - 自动过滤密码和 Token
- 🎨 **半透明遮罩** - 优雅的全屏覆盖界面

## 🚀 快速开始

### 系统要求
- macOS 13.0+
- Xcode 15.0+

### 安装运行

```bash
git clone https://github.com/GUruolan/SimpleClipboard.git
cd SimpleClipboard
open SimpleClipboard.xcodeproj
```

在 Xcode 中选择 "My Mac" 并运行 (`⌘ + R`)

### 授予权限

**桌面切换功能需要辅助功能权限：**
- 系统设置 → 隐私与安全性 → 辅助功能
- 添加 SimpleClipboard 并勾选

## 📖 使用指南

### 快捷键

| 功能 | 快捷键 |
|------|--------|
| 打开剪贴板面板 | `Command + Shift + V` |
| 切换到左边桌面 | `Command + ←` |
| 切换到右边桌面 | `Command + →` |
| 向上/下选择 | `↑` / `↓` |
| 复制选中项 | `Enter` |
| 关闭面板 | `ESC` 或点击遮罩 |

### 鼠标操作

- **点击项目** - 复制到剪贴板并关闭面板
- **悬停项目** - 显示删除按钮
- **点击垃圾桶** - 清空所有历史

### 隐私保护规则

自动跳过以下内容：
- 疑似密码（8-32 字符，含字母数字特殊符号）
- 长 Token（超过 40 字符无空格）
- 包含敏感关键词：`password`, `token`, `api_key`, `secret`, `密码`, `令牌`

## 🛠️ 项目结构

```
SimpleClipboard/
├── SimpleClipboardApp.swift      # 应用入口，覆盖窗口
├── ContentView.swift              # 主界面和键盘导航
├── ClipboardManager.swift         # 剪贴板监控和历史管理
├── AppDelegate.swift              # 全局快捷键和桌面切换
└── Assets.xcassets/               # 资源文件
```

## 🔧 自定义配置

### 修改历史记录上限

`ClipboardManager.swift:5-6`
```swift
private let maxHistoryCount = 50  // 文本历史上限
private let maxImageCount = 10    // 图片历史上限
```

### 添加敏感关键词

`ClipboardManager.swift:146`
```swift
let sensitiveKeywords = ["password", "token", "你的关键词"]
```

## 📄 许可证

MIT License

---

**⭐ 如果觉得有用，请给个 Star！**
