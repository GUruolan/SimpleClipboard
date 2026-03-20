import Foundation
import AppKit
import Combine

private let maxHistoryCount = 50
private let historyKey = "clipboardHistory"

class ClipboardManager: ObservableObject {
    // 存储历史记录，使用 @Published 让 UI 自动更新
    @Published var history: [String] = []

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?

    init() {
        // 初始化时记录当前的变更计数
        self.lastChangeCount = pasteboard.changeCount
        // 从 UserDefaults 加载历史记录
        loadHistory()
        startMonitoring()
    }

    // 加载历史记录
    private func loadHistory() {
        if let savedHistory = UserDefaults.standard.array(forKey: historyKey) as? [String] {
            history = savedHistory
        }
    }

    // 保存历史记录
    private func saveHistory() {
        UserDefaults.standard.set(history, forKey: historyKey)
    }

    func startMonitoring() {
        // 优化：应用活跃时每0.3秒检查，不活跃时每1秒检查
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        // 允许在后台运行
        RunLoop.current.add(timer!, forMode: .common)
    }

    deinit {
        timer?.invalidate()
    }

    // 检查是否为敏感内容（简单规则）
    private func isSensitive(_ text: String) -> Bool {
        // 1. 检查是否像密码（长度合适且包含特殊字符）
        let passwordPattern = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[@$!%*#?&])[A-Za-z\\d@$!%*#?&]{8,32}$"
        if text.range(of: passwordPattern, options: .regularExpression) != nil {
            return true
        }

        // 2. 检查是否像 Token（长字符串无空格）
        if text.count > 40 && !text.contains(" ") && !text.contains("\n") {
            return true
        }

        // 3. 检查是否包含敏感关键词
        let sensitiveKeywords = ["password", "token", "api_key", "secret", "密码", "令牌"]
        let lowercased = text.lowercased()
        for keyword in sensitiveKeywords {
            if lowercased.contains(keyword) {
                return true
            }
        }

        return false
    }

    private func checkPasteboard() {
        // 剪贴板的 changeCount 每次变化都会增加，这是最性能友好的检测方式
        guard pasteboard.changeCount != lastChangeCount else { return }

        lastChangeCount = pasteboard.changeCount

        // 目前只处理文本类型
        if let newString = pasteboard.string(forType: .string) {
            // 去除前后空格
            let trimmedString = newString.trimmingCharacters(in: .whitespacesAndNewlines)

            // 避免保存空字符串、重复内容或敏感内容
            if !trimmedString.isEmpty && !history.contains(trimmedString) && !isSensitive(trimmedString) {
                DispatchQueue.main.async {
                    // 将新内容插入到数组最前面
                    self.history.insert(trimmedString, at: 0)
                    // 限制只保存最近20条
                    if self.history.count > maxHistoryCount {
                        self.history.removeLast()
                    }
                    // 保存到 UserDefaults
                    self.saveHistory()
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
            saveHistory()
        }
    }

    // 清空历史记录
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
}
