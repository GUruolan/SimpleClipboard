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

    
    func toggleMenuBarExtra() {
        // 检查窗口实际可见性，而不是依赖标志位
        let isActuallyVisible = overlayWindow?.isVisible ?? false

        if isActuallyVisible {
            hideOverlayWindow()
        } else {
            showOverlayWindow()
        }
    }

    func showOverlayWindow() {
        // 获取当前鼠标所在的屏幕
        let mouseLocation = NSEvent.mouseLocation
        let currentScreen = NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main ?? NSScreen.screens.first!


        // 如果窗口不存在，创建窗口
        if overlayWindow == nil {
            createOverlayWindow()
        }

        // 更新窗口位置到当前屏幕（在显示之前）
        overlayWindow?.setFrame(currentScreen.frame, display: false)

        // 设置窗口层级为最高
        overlayWindow?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))

        // 强制窗口到最前面
        overlayWindow?.orderFrontRegardless()

        // 显示窗口并设置为 key window
        overlayWindow?.makeKeyAndOrderFront(nil)

        // 激活应用（会切换到应用所在的 Space）
        NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])

        // 等待桌面切换动画完成后再设置焦点
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let window = self?.overlayWindow else { return }

            // 第一次激活
            NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])

            // 确保窗口在最前面
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)

            // 短暂延迟后再次强制获取焦点
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSRunningApplication.current.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                window.makeKey()
                window.makeFirstResponder(window.contentView)

                print("✅ 焦点已设置 (两次激活)")
            }
        }

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
        // 获取当前鼠标所在的屏幕（即用户正在使用的屏幕）
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main ?? NSScreen.screens.first!

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

        // 设置窗口层级为最高
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))

        // 窗口行为：不加入所有空间，让系统自动切换到窗口所在的桌面
        window.collectionBehavior = [
            .moveToActiveSpace,          // 移动到当前活跃的空间（关键！）
            .transient,                  // 临时窗口
            .ignoresCycle                // 不参与窗口循环
        ]

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
