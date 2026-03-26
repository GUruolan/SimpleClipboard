// ContentView.swift

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager

    // 追踪当前选中项的索引
    @State private var selectedIndex: Int = 0

    // 用于接收键盘焦点的 State
    @FocusState private var isListFocused: Bool

    // 搜索关键词
    @State private var searchText: String = ""

    // 过滤后的历史记录
    var filteredHistory: [String] {
        if searchText.isEmpty {
            return clipboardManager.history
        } else {
            return clipboardManager.history.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 头部工具栏
            HStack(spacing: 12) {
                // 搜索框
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .onKeyPress(.downArrow) {
                        // 按下箭头时，将焦点转回列表
                        isListFocused = true
                        return .handled
                    }
                    .onKeyPress(.upArrow) {
                        // 按上箭头时，将焦点转回列表
                        isListFocused = true
                        return .handled
                    }
                    .onSubmit {
                        // 按回车后，将焦点转回列表
                        isListFocused = true
                    }

                // 清空历史按钮
                Button {
                    clipboardManager.clearHistory()
                    selectedIndex = 0
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .imageScale(.medium)
                }
                .buttonStyle(.borderless)
                .help("Clear all history")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            ScrollViewReader { proxy in
                List {
                    ForEach(filteredHistory.indices, id: \.self) { index in
                        HistoryRow(
                            manager: clipboardManager,
                            text: filteredHistory[index],
                            // 根据 selectedIndex 切换背景色
                            isSelected: index == selectedIndex,
                            // 【新增 Action 闭包】用于处理点击事件
                            onSelect: {
                                selectedIndex = index
                                selectItem(filteredHistory[index])
                                // 复制后自动关闭窗口
                                NSApp.deactivate()
                            }
                        )
                        .id(index) // 给每个项目设置 ID
                        // 修复：由于 HistoryRow 内部已经处理了 onTapGesture，这里不需要重复设置
                    }
                }
                .listStyle(.plain)
                .focusable()
                // 关键设置 1：设置焦点状态
                .focused($isListFocused)
                // 处理回车 (Enter) 键
                .onKeyPress(.return) {
                    if selectedIndex >= 0 && selectedIndex < filteredHistory.count {
                        selectItem(filteredHistory[selectedIndex])
                        // 关闭窗口
                        DispatchQueue.main.async {
                            if let window = NSApp.keyWindow {
                                window.close()
                            }
                            NSApp.deactivate()
                        }
                    }
                    return .handled
                }
                // 处理向下箭头
                .onKeyPress(.downArrow) {
                    if selectedIndex < filteredHistory.count - 1 {
                        selectedIndex += 1
                        // 滚动到选中项
                        withAnimation {
                            proxy.scrollTo(selectedIndex, anchor: .center)
                        }
                    }
                    return .handled
                }
                // 处理向上箭头
                .onKeyPress(.upArrow) {
                    if selectedIndex > 0 {
                        selectedIndex -= 1
                        // 滚动到选中项
                        withAnimation {
                            proxy.scrollTo(selectedIndex, anchor: .center)
                        }
                    }
                    return .handled
                }
                // 关键设置 2：窗口出现时请求焦点
                .onAppear {
                    isListFocused = true
                    searchText = "" // 清空搜索框
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
            }
        }
        .frame(width: 500, height: 300)
        .background(Color.white)
    }
    
    // 私有方法：选中并复制项目
    private func selectItem(_ item: String) {
        clipboardManager.copyToHead(item: item)
        // 不立即修改顺序，下次打开窗口时自动调整
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
        Button(action: {
            onSelect()
        }) {
            HStack(alignment: .top, spacing: 8) {
                // 文本内容
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(3)  // 最多显示 3 行
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)  // 允许垂直扩展

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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            // 【样式修改】键盘选中优先级高于鼠标悬停
            .background(
                isSelected
                    ? Color.blue.opacity(0.3)  // 键盘选中：深蓝色
                    : (isHovering ? Color.blue.opacity(0.1) : Color.clear)  // 鼠标悬停：浅蓝色
            )
            .cornerRadius(8)
            .overlay(
                isSelected ? AnyView(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.8), lineWidth: 2)
                    ) : AnyView(EmptyView())
            )
            .contentShape(Rectangle()) // 使整个 HStack 区域可点击
        }
        .buttonStyle(.plain) // 使用 plain 样式避免默认按钮样式
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
