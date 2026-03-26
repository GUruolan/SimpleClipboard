import Foundation
import AppKit
import Combine

private let maxHistoryCount = 50
private let historyKey = "clipboardHistory"
private let imageHistoryKey = "clipboardImageHistory"

// 剪贴板项目类型
enum ClipboardItemType: Codable {
    case text(String)
    case image(Data)

    var displayText: String {
        switch self {
        case .text(let str):
            return str
        case .image:
            return "[Image]"
        }
    }

    var isImage: Bool {
        if case .image = self { return true }
        return false
    }
}

// 剪贴板历史项
struct ClipboardItem: Identifiable, Codable {
    let id: String
    let type: ClipboardItemType
    let timestamp: Date

    init(type: ClipboardItemType) {
        self.id = UUID().uuidString
        self.type = type
        self.timestamp = Date()
    }
}

class ClipboardManager: ObservableObject {
    // 存储历史记录，使用 @Published 让 UI 自动更新
    @Published var history: [ClipboardItem] = []

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private var shouldIgnoreNextChange = false // 标志：是否忽略下一次剪贴板变化

    init() {
        // 初始化时记录当前的变更计数
        self.lastChangeCount = pasteboard.changeCount
        // 从 UserDefaults 加载历史记录
        loadHistory()
        startMonitoring()
    }

    // 加载历史记录
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            history = decoded
        }
    }

    // 保存历史记录
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
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

        // 如果设置了忽略标志，跳过这次处理
        if shouldIgnoreNextChange {
            shouldIgnoreNextChange = false
            return
        }

        // 目前只处理文本类型
        if let newString = pasteboard.string(forType: .string) {
            // 去除前后空格
            let trimmedString = newString.trimmingCharacters(in: .whitespacesAndNewlines)

            // 避免保存空字符串或敏感内容
            if !trimmedString.isEmpty && !isSensitive(trimmedString) {
                DispatchQueue.main.async {
                    // 如果已存在，先删除旧位置
                    if let existingIndex = self.history.firstIndex(of: trimmedString) {
                        self.history.remove(at: existingIndex)
                    }

                    // 将内容插入到数组最前面
                    self.history.insert(trimmedString, at: 0)

                    // 限制只保存最近50条
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
        // 检查剪贴板当前内容是否已经是这个项目
        if let currentContent = pasteboard.string(forType: .string),
           currentContent.trimmingCharacters(in: .whitespacesAndNewlines) == item {
            // 已经是当前内容，不需要重复复制
            return
        }

        shouldIgnoreNextChange = true // 设置标志，忽略这次剪贴板变化
        pasteboard.clearContents()
        pasteboard.setString(item, forType: .string)
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
