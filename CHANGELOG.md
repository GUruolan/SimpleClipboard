# Changelog

All notable changes to SimpleClipboard will be documented in this file.

## [1.1.0] - 2026-03-20

### ✨ Added
- **搜索功能**: 实时过滤剪贴板历史记录
- **数据持久化**: 使用 UserDefaults 保存历史，重启不丢失
- **隐私保护**: 自动过滤密码、Token 等敏感内容
- **清空历史**: 一键清空所有历史记录
- **窗口自适应**: 高度范围 300-600px

### 🔧 Changed
- 轮询间隔从 0.5s 优化到 0.3s，响应更快
- 窗口宽度从 450px 增加到 500px
- 搜索框采用圆角边框样式

### 🐛 Fixed
- 修复删除/清空操作未同步到持久化存储的问题
- 修复定时器未正确释放可能导致的内存泄漏

### 📝 Documentation
- 新增 README.md 使用指南
- 新增 OPTIMIZATION_SUMMARY.md 优化总结

---

## [1.0.0] - 2025-12-05

### ✨ Initial Release
- 基础剪贴板历史记录功能
- 全局快捷键 (Control + Shift + Space)
- 键盘导航 (上下箭头 + 回车)
- 鼠标悬停删除按钮
- 菜单栏图标

---

## 版本规则

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

### 变更类型
- `Added` - 新增功能
- `Changed` - 现有功能变更
- `Deprecated` - 即将废弃的功能
- `Removed` - 已移除的功能
- `Fixed` - 修复的 Bug
- `Security` - 安全相关的修复
