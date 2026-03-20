# 🧪 测试指南

## 在 Xcode 中运行和测试 SimpleClipboard

---

## ✅ 运行前检查清单

### 1. 项目配置
- [x] Xcode 已打开项目
- [ ] 选择目标设备为 "My Mac"
- [ ] 构建目标为 "SimpleClipboard"

### 2. 系统权限
- [ ] 系统设置 → 隐私与安全性 → 辅助功能
- [ ] 添加 SimpleClipboard（首次运行后）

---

## 🚀 运行步骤

### 方法 1: 使用快捷键（推荐）

1. **编译并运行**
   ```
   ⌘ + R (Command + R)
   ```

2. **查看应用**
   - 菜单栏右上角会出现剪贴板图标 📋
   - 点击图标或按 `Control + Shift + Space` 打开窗口

3. **停止运行**
   ```
   ⌘ + . (Command + 句号)
   ```

---

### 方法 2: 使用菜单

1. **Product** → **Run**
2. 或点击左上角的 ▶️ 播放按钮

---

## 🧪 测试功能清单

### ✅ 基础功能测试

#### 1. 剪贴板监控
- [ ] 复制一段文本（`⌘ + C`）
- [ ] 打开应用窗口，检查是否出现在历史列表

#### 2. 全局快捷键
- [ ] 按 `Control + Shift + Space`
- [ ] 窗口是否正常打开/关闭

#### 3. 键盘导航
- [ ] 按 `↑` 向上选择
- [ ] 按 `↓` 向下选择
- [ ] 按 `Enter` 复制选中项
- [ ] 检查剪贴板是否更新（粘贴测试）

#### 4. 鼠标操作
- [ ] 点击列表项是否复制
- [ ] 鼠标悬停是否显示删除按钮
- [ ] 点击删除按钮是否移除记录

---

### ✨ 新增功能测试

#### 5. 搜索功能
- [ ] 在搜索框输入关键词
- [ ] 列表是否实时过滤
- [ ] 清空搜索框，列表是否恢复

#### 6. 数据持久化
- [ ] 复制几段文本
- [ ] 退出应用（`⌘ + Q`）
- [ ] 重新运行应用
- [ ] 历史记录是否保留

#### 7. 隐私保护
测试以下内容是否**不会**被记录：

- [ ] 复制密码（如 `Test@123456`）
- [ ] 复制长 Token（如 `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`）
- [ ] 复制包含关键词的文本（如 `my password is xxx`）

#### 8. 清空历史
- [ ] 点击右上角垃圾桶图标
- [ ] 列表是否清空
- [ ] 重启应用，历史是否仍为空

---

## 🐛 调试技巧

### 查看控制台日志

1. **打开控制台**
   ```
   ⌘ + Shift + Y (显示/隐藏调试区域)
   ```

2. **查看输出**
   - 剪贴板变化会在控制台输出
   - 错误信息会显示红色

---

### 断点调试

#### 关键位置设置断点：

1. **剪贴板检测**
   - `ClipboardManager.swift:74` - `checkPasteboard()` 方法

2. **敏感内容过滤**
   - `ClipboardManager.swift:50` - `isSensitive()` 方法

3. **搜索过滤**
   - `ContentView.swift:18` - `filteredHistory` 计算属性

4. **选中复制**
   - `ContentView.swift:131` - `selectItem()` 方法

---

### 常见问题排查

#### 问题 1: 快捷键不生效

**检查步骤**:
1. 控制台是否有输出？
   - 无输出 → 权限问题
   - 有输出 → 代码逻辑问题

2. 添加调试日志：
   ```swift
   // AppDelegate.swift:15
   NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
       print("🔍 KeyCode: \(event.keyCode), Modifiers: \(event.modifierFlags)")
       // ...
   }
   ```

3. 授予辅助功能权限：
   - 系统设置 → 隐私与安全性 → 辅助功能
   - 添加 Xcode 或 SimpleClipboard

---

#### 问题 2: 历史记录不保存

**检查步骤**:
1. 添加保存日志：
   ```swift
   // ClipboardManager.swift:32
   private func saveHistory() {
       UserDefaults.standard.set(history, forKey: historyKey)
       print("💾 Saved \(history.count) items")
   }
   ```

2. 查看 UserDefaults：
   ```swift
   // 在任意位置添加
   print(UserDefaults.standard.array(forKey: "clipboardHistory") ?? [])
   ```

---

#### 问题 3: 搜索结果不正确

**检查步骤**:
1. 添加过滤日志：
   ```swift
   // ContentView.swift:18
   var filteredHistory: [String] {
       let result = searchText.isEmpty ? clipboardManager.history
           : clipboardManager.history.filter {
               $0.localizedCaseInsensitiveContains(searchText)
           }
       print("🔍 Search: '\(searchText)' → \(result.count) results")
       return result
   }
   ```

---

#### 问题 4: 敏感内容仍被记录

**检查步骤**:
1. 测试敏感内容检测：
   ```swift
   // 在 init() 中添加测试
   print("Password test:", isSensitive("Test@123456"))  // 应该是 true
   print("Token test:", isSensitive("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"))  // 应该是 true
   print("Normal test:", isSensitive("Hello World"))  // 应该是 false
   ```

---

## 📊 性能测试

### 测试轮询性能

1. 打开活动监视器（Activity Monitor）
2. 搜索 "SimpleClipboard"
3. 观察 CPU 和内存使用率

**预期结果**:
- CPU: < 1% （空闲时）
- 内存: < 50MB

---

### 测试大量历史记录

1. 修改上限：
   ```swift
   // ClipboardManager.swift:5
   private let maxHistoryCount = 500  // 临时改为 500
   ```

2. 快速复制大量内容
3. 观察性能和响应速度

---

## 🎯 测试场景

### 场景 1: 日常使用
1. 浏览网页，复制多段文本
2. 使用快捷键快速访问历史
3. 键盘导航选择并粘贴

### 场景 2: 代码开发
1. 复制代码片段
2. 在不同文件间快速粘贴
3. 搜索之前复制的函数名

### 场景 3: 敏感操作
1. 登录网站，复制密码
2. 检查密码是否被记录（不应该）
3. 复制 API Token 测试

---

## 📝 测试报告模板

```markdown
## 测试日期: YYYY-MM-DD
## 测试人员: [Your Name]
## Xcode 版本: 16.x
## macOS 版本: 14.x

### 功能测试结果

| 功能 | 状态 | 备注 |
|------|------|------|
| 剪贴板监控 | ✅ / ❌ | |
| 全局快捷键 | ✅ / ❌ | |
| 键盘导航 | ✅ / ❌ | |
| 鼠标操作 | ✅ / ❌ | |
| 搜索功能 | ✅ / ❌ | |
| 数据持久化 | ✅ / ❌ | |
| 隐私保护 | ✅ / ❌ | |
| 清空历史 | ✅ / ❌ | |

### 性能测试

- CPU 使用率: ___%
- 内存使用: ___MB
- 响应延迟: ___ms

### 发现的问题

1. [问题描述]
   - 重现步骤:
   - 预期结果:
   - 实际结果:

### 改进建议

1. [建议内容]
```

---

## 🔧 构建配置

### Debug 模式（开发）
```
Product → Scheme → Edit Scheme → Run → Build Configuration → Debug
```

特点：
- 包含调试符号
- 未优化代码
- 可设置断点

---

### Release 模式（发布）
```
Product → Scheme → Edit Scheme → Run → Build Configuration → Release
```

特点：
- 代码优化
- 体积更小
- 性能更好

---

## 📦 导出应用

### 创建 Archive

1. **Product** → **Archive**
2. 等待构建完成
3. **Distribute App** → **Copy App**
4. 选择保存位置

---

### 手动导出

1. 找到编译产物：
   ```bash
   open ~/Library/Developer/Xcode/DerivedData
   ```

2. 搜索 `SimpleClipboard.app`

3. 复制到应用程序文件夹：
   ```bash
   cp -r SimpleClipboard.app /Applications/
   ```

---

## ✅ 测试完成标准

- [ ] 所有基础功能正常工作
- [ ] 所有新增功能测试通过
- [ ] 无崩溃或明显 Bug
- [ ] 性能符合预期
- [ ] 隐私保护生效
- [ ] 数据持久化正常

---

## 🎉 测试通过后

1. **清理代码**
   - 移除调试日志
   - 移除测试代码

2. **更新文档**
   - 记录已知问题
   - 更新 CHANGELOG.md

3. **提交代码**
   ```bash
   git add .
   git commit -m "test: 通过所有功能测试"
   ```

4. **打包发布**
   - 创建 Release Archive
   - 分发给用户

---

**祝测试顺利！如有问题，请查看控制台日志或提交 Issue。** 🚀
