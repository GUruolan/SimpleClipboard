import SwiftUI

@main
struct SimpleClipboardApp: App {
    // 初始化我们的逻辑控制器
    @StateObject var clipboardManager = ClipboardManager()
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 使用 MenuBarExtra 创建菜单栏应用
        MenuBarExtra("Clipboard", systemImage: "doc.on.clipboard") {
            ContentView()
                .environmentObject(clipboardManager) // 注入数据
        }
        .menuBarExtraStyle(.window) // 使用窗口样式而不是传统菜单列表
    }
}
