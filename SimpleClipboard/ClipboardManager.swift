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
            // 避免重复保存刚刚复制的内容
            if !history.contains(newString) {
                DispatchQueue.main.async {
                    // 将新内容插入到数组最前面
                    self.history.insert(newString, at: 0)
                    // 限制只保存最近20条
                    if self.history.count > maxL {
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
