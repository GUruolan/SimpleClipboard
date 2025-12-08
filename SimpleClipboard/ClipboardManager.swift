import Foundation
import AppKit
import Combine

private let maxHistoryCount = 50

class ClipboardManager: ObservableObject {
    // 存储历史记录，使用 @Published 让 UI 自动更新
    @Published var history: [String] = []
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    init() {
        // 初始化时记录当前的变更计数
        self.lastChangeCount = pasteboard.changeCount
        startMonitoring()
    }

    func startMonitoring() {
        // 每0.5秒检查一次剪贴板是否有变化
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    private func checkPasteboard() {
        // 剪贴板的 changeCount 每次变化都会增加，这是最性能友好的检测方式
        guard pasteboard.changeCount != lastChangeCount else { return }
        
        lastChangeCount = pasteboard.changeCount
        
        // 目前只处理文本类型
        if let newString = pasteboard.string(forType: .string) {
            // 去除前后空格
            let trimmedString = newString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 避免保存空字符串或重复内容
            if !trimmedString.isEmpty && !history.contains(trimmedString) {
                DispatchQueue.main.async {
                    // 将新内容插入到数组最前面
                    self.history.insert(trimmedString, at: 0)
                    // 限制只保存最近20条
                    if self.history.count > maxHistoryCount {
                        self.history.removeLast()
                    }
                }
            }
        }
    }
    
    // 将历史记录重新写入剪贴板
    func copyToHead(item: String) {
        pasteboard.clearContents()
        pasteboard.setString(item, forType: .string)
        // 这里的 changeCount 也会变，但因为 item 已经在 history 里，
        // checkPasteboard 的去重逻辑会忽略它，或者你可以手动更新 lastChangeCount
    }
    // 【新增删除方法】
    func delete(item: String) {
        if let index = history.firstIndex(of: item) {
            history.remove(at: index)
        }
    }
}
