// ContentView.swift

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    
    // 追踪当前选中项的索引
    @State private var selectedIndex: Int = 0
    
    // 用于接收键盘焦点的 State
    @FocusState private var isListFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 样式调整 1: 头部使用更简洁的颜色和内边距
            Text("Clipboard History")
                // 【样式调整：字体加粗】
                .font(.system(.headline, design: .monospaced).bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.8)) // 更淡的背景
            
            Divider()
            
            List {
                ForEach(clipboardManager.history.indices, id: \.self) { index in
                    HistoryRow(
                        manager: clipboardManager,
                        text: clipboardManager.history[index],
                        // 根据 selectedIndex 切换背景色
                        isSelected: index == selectedIndex,
                        // 【新增 Action 闭包】用于处理点击事件
                        onSelect: {
                            selectedIndex = index
                            selectItem(clipboardManager.history[index])
                            // 复制后自动关闭窗口
                            NSApp.deactivate()
                        }
                    )
                    // 修复：由于 HistoryRow 内部已经处理了 onTapGesture，这里不需要重复设置
                }
            }
            .listStyle(.plain)
            // 关键设置 1：设置焦点状态
            .focused($isListFocused)
            
            // 关键设置 2：窗口出现时请求焦点
            .onAppear {
                isListFocused = true
                if clipboardManager.history.isEmpty {
                    selectedIndex = -1
                } else {
                    selectedIndex = 0 // 默认选中第一项
                }
                // 确保应用被激活，以便接收键盘事件
                NSApp.activate(ignoringOtherApps: true)
            }
            // 确保窗口关闭时取消焦点
            .onDisappear {
                isListFocused = false
            }
            
            // 处理回车 (Enter) 键
            .onKeyPress(.return) {
                if selectedIndex >= 0 && selectedIndex < clipboardManager.history.count {
                    selectItem(clipboardManager.history[selectedIndex])
                    NSApp.deactivate()
                }
                return .handled
            }
            
            // 处理向下箭头
            .onKeyPress(.downArrow) {
                if selectedIndex < clipboardManager.history.count - 1 {
                    selectedIndex += 1
                }
                return .handled
            }
            
            // 处理向上箭头
            .onKeyPress(.upArrow) {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                }
                return .handled
            }
        }
        .frame(width: 320, height: 450)
        .background(Color.white.opacity(0.80))
    }
    
    // 私有方法：选中并复制项目
    private func selectItem(_ item: String) {
        clipboardManager.copyToHead(item: item)
        
        // 优化：将选中的项目移到列表最上方（解决 Publishing changes 错误的关键）
        guard let selectedIndex = clipboardManager.history.firstIndex(of: item) else {
            return
        }
        
        // 使用 DispatchQueue.main.async 延迟执行状态修改
        DispatchQueue.main.async {
            // 推荐的“移动到顶部”安全写法：
            let itemToMove = self.clipboardManager.history.remove(at: selectedIndex) // 删除旧项
            self.clipboardManager.history.insert(itemToMove, at: 0) // 插入新项
        }
    }
}

// 单独的行视图 (HistoryRow)
struct HistoryRow: View {
    @ObservedObject var manager: ClipboardManager // 接收 manager
    let text: String
    let isSelected: Bool // 被选中状态
    let onSelect: () -> Void // 【新增】点击时执行的闭包
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            // 文本内容
            Text(text)
                .font(.subheadline).bold()
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.vertical, 4)
                
            Spacer() // 将文字和按钮推到两端
            
            // 删除按钮
            Button {
                manager.delete(item: text) // 调用删除方法
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .imageScale(.medium)
            }
            .buttonStyle(.borderless) // 隐藏按钮边框
            .opacity(isHovering ? 1.0 : 0.0) // 鼠标悬停时才显示
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        // 【样式修改】如果被选中（键盘）或鼠标悬停，使用蓝色背景
        .background(isSelected || isHovering ? Color.blue.opacity(0.1) : Color.clear)
        .contentShape(Rectangle()) // 使整个 HStack 区域可点击/悬停
        .onHover { hovering in
            isHovering = hovering
        }
        // 【修复】点击时调用外部传入的 onSelect 闭包
        .onTapGesture {
            onSelect()
        }
    }
}
