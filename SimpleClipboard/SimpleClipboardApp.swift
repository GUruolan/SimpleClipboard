import SwiftUI

@main
struct SimpleClipboardApp: App {
    // 初始化我们的逻辑控制器
    @StateObject var clipboardManager = ClipboardManager()

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 保留菜单栏图标
        MenuBarExtra("Clipboard", systemImage: "doc.on.clipboard") {
            Button("Show Clipboard") {
                appDelegate.clipboardManager = clipboardManager
                appDelegate.showOverlayWindow()
            }
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// 带遮罩的覆盖窗口视图
struct OverlayWindowView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager

    var body: some View {
        ZStack {
            // 半透明黑色遮罩
            Color.black.opacity(0.001)  // 几乎透明，但可以接收点击
                .ignoresSafeArea()
                .onTapGesture {
                    closeWindow()
                }

            // 实际的黑色背景（不接收点击）
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .allowsHitTesting(false)  // 不拦截点击事件

            // 内容窗口
            ContentView()
                .environmentObject(clipboardManager)
                .frame(width: 500, height: 300)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        // 监听 ESC 键关闭窗口
        .onKeyPress(.escape) {
            closeWindow()
            return .handled
        }
    }

    private func closeWindow() {
        AppDelegate.shared?.hideOverlayWindow()
    }
}
