import Cocoa
import SwiftUI
import AppKit
import Carbon

// 辅助扩展：将字符串转换为 FourCharCode
extension String {
    var fourCharCodeValue: Int {
        var result: Int = 0
        for char in self.utf8 {
            result = result << 8 + Int(char)
        }
        return result
    }
}

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
    private var hotKeyRef: EventHotKeyRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // 使用 Carbon 热键 API（不需要辅助功能权限）
        registerGlobalHotKey()
        print("✅ 已注册全局快捷键: Command + Shift + V")
    }

    private func registerGlobalHotKey() {
        // 定义热键 ID
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType("SCLP".fourCharCodeValue)
        hotKeyID.id = 1

        // 注册 Command + Shift + V
        // V 的虚拟键码是 9
        var eventHotKey: EventHotKeyRef?
        let status = RegisterEventHotKey(
            9, // V 键
            UInt32(cmdKey | shiftKey), // Command + Shift
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &eventHotKey
        )

        if status == noErr {
            hotKeyRef = eventHotKey

            // 安装事件处理器
            var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetEventDispatcherTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
                // 获取 AppDelegate 实例
                guard let appDelegate = AppDelegate.shared else { return noErr }

                // 触发窗口切换
                DispatchQueue.main.async {
                    appDelegate.toggleMenuBarExtra()
                }

                return noErr
            }, 1, &eventSpec, nil, nil)

            print("✅ Carbon 热键注册成功")
        } else {
            print("❌ Carbon 热键注册失败: \(status)")
        }
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
        // 打印所有按键，用于调试
        print("⌨️ KeyCode: \(event.keyCode), Modifiers: \(event.modifierFlags.rawValue)")

        // 检查 Control 键
        let hasControl = event.modifierFlags.contains(.control)
        // 检查 Shift 键
        let hasShift = event.modifierFlags.contains(.shift)
        // 检查 V 键 (KeyCode 9)
        let isVKey = event.keyCode == 9

        print("   Control=\(hasControl), Shift=\(hasShift), V=\(isVKey)")

        // 精确匹配 Control + Shift + V
        if isVKey && hasControl && hasShift {
            print("🎯 快捷键触发！")
            // 确保在主线程执行
            DispatchQueue.main.async { [weak self] in
                self?.toggleMenuBarExtra()
            }
        }
    }
    
    func toggleMenuBarExtra() {
        // 检查窗口实际可见性，而不是依赖标志位
        let isActuallyVisible = overlayWindow?.isVisible ?? false

        print("🔍 toggleMenuBarExtra: isVisible=\(isActuallyVisible), isWindowShowing=\(isWindowShowing)")

        if isActuallyVisible {
            print("   → 隐藏窗口")
            hideOverlayWindow()
        } else {
            print("   → 显示窗口")
            showOverlayWindow()
        }
    }

    func showOverlayWindow() {
        if overlayWindow == nil {
            createOverlayWindow()
        }

        // 先激活应用
        NSApp.activate(ignoringOtherApps: true)

        // 显示窗口
        overlayWindow?.makeKeyAndOrderFront(nil)
        overlayWindow?.level = .floating

        // 确保窗口成为焦点窗口
        overlayWindow?.makeFirstResponder(overlayWindow?.contentView)

        // 再次确保窗口是 key window
        overlayWindow?.makeKey()

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
