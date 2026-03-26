import Cocoa
import SwiftUI
import AppKit

// 自定义窗口类，允许 borderless 窗口接收键盘事件
class KeyWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    // 【重要提醒】使用 NSEvent.addGlobalMonitorForEvents 需要在系统设置的”辅助功能”中授予应用权限，才能在应用不活跃时全局生效。

    private var overlayWindow: NSWindow?
    static var shared: AppDelegate?
    var clipboardManager: ClipboardManager?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isWindowShowing = false  // 追踪窗口显示状态
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // 检查辅助功能权限
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)

        // 注册全局快捷键 (Command + Shift + V)
        setupKeyboardMonitors()
    }

    private func setupKeyboardMonitors() {
        // 全局监听（其他应用）
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // 本地监听（自己应用）
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
    }

    private func removeKeyboardMonitors() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        // 检查 Command 键
        let hasCommand = event.modifierFlags.contains(.command)
        // 检查 Shift 键
        let hasShift = event.modifierFlags.contains(.shift)
        // 检查 V 键 (KeyCode 9)
        let isVKey = event.keyCode == 9

        // 精确匹配 Command + Shift + V
        if isVKey && hasCommand && hasShift {
            print("🎯 快捷键触发！")
            // 确保在主线程执行
            DispatchQueue.main.async { [weak self] in
                self?.toggleMenuBarExtra()
            }
        }
    }
    
    func toggleMenuBarExtra() {
        print("🔍 toggleMenuBarExtra 调用, isWindowShowing=\(isWindowShowing)")
        if isWindowShowing {
            hideOverlayWindow()
        } else {
            showOverlayWindow()
        }
        print("   执行后 isWindowShowing=\(isWindowShowing)")
    }

    func showOverlayWindow() {
        if overlayWindow == nil {
            createOverlayWindow()
        }

        overlayWindow?.makeKeyAndOrderFront(nil)
        overlayWindow?.level = .floating

        // 确保窗口成为焦点窗口
        overlayWindow?.makeFirstResponder(overlayWindow?.contentView)

        NSApp.activate(ignoringOtherApps: true)

        isWindowShowing = true  // 标记窗口已显示
    }

    func hideOverlayWindow() {
        guard let window = overlayWindow else {
            isWindowShowing = false
            return
        }

        window.orderOut(nil)
        isWindowShowing = false  // 标记窗口已隐藏
    }

    private func createOverlayWindow() {
        // 获取主屏幕尺寸
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame

        // 使用自定义窗口类，允许 borderless 窗口接收键盘事件
        let window = KeyWindow(
            contentRect: screenFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // 关键设置：允许窗口接收键盘和鼠标事件
        window.acceptsMouseMovedEvents = true
        window.ignoresMouseEvents = false

        // 防止窗口被自动释放
        window.isReleasedWhenClosed = false

        // 设置 SwiftUI 内容
        let contentView = OverlayWindowView()
            .environmentObject(getClipboardManager())

        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView

        overlayWindow = window
    }

    private func getClipboardManager() -> ClipboardManager {
        // 从单例获取 ClipboardManager
        return clipboardManager ?? ClipboardManager()
    }
}
