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
    private var leftArrowHotKeyRef: EventHotKeyRef?
    private var rightArrowHotKeyRef: EventHotKeyRef?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // 检查辅助功能权限（桌面切换需要）
        checkAccessibilityPermission()

        // 使用 Carbon 热键 API（不需要辅助功能权限）
        registerGlobalHotKey()
        registerDesktopSwitchHotKeys()
        print("✅ 已注册全局快捷键: Command + Shift + V")
        print("✅ 已注册桌面切换快捷键: Command + 左/右箭头")
    }

    private func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("⚠️ 桌面切换功能需要辅助功能权限")
            print("⚠️ 请在系统设置 > 隐私与安全性 > 辅助功能 中授权")
        } else {
            print("✅ 辅助功能权限已授予")
        }
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
            print("✅ Command + Shift + V 注册成功")
        } else {
            print("❌ Command + Shift + V 注册失败: \(status)")
        }
    }

    private func registerDesktopSwitchHotKeys() {
        // 注册 Command + 左箭头 (切换到左边的桌面)
        var leftHotKeyID = EventHotKeyID()
        leftHotKeyID.signature = OSType("SCLF".fourCharCodeValue)
        leftHotKeyID.id = 2

        // 左箭头的虚拟键码是 123
        var leftEventHotKey: EventHotKeyRef?
        let leftStatus = RegisterEventHotKey(
            123, // 左箭头键
            UInt32(cmdKey), // Command
            leftHotKeyID,
            GetEventDispatcherTarget(),
            0,
            &leftEventHotKey
        )

        if leftStatus == noErr {
            leftArrowHotKeyRef = leftEventHotKey
            print("✅ Command + 左箭头 注册成功")
        } else {
            print("❌ Command + 左箭头 注册失败: \(leftStatus)")
        }

        // 注册 Command + 右箭头 (切换到右边的桌面)
        var rightHotKeyID = EventHotKeyID()
        rightHotKeyID.signature = OSType("SCRT".fourCharCodeValue)
        rightHotKeyID.id = 3

        // 右箭头的虚拟键码是 124
        var rightEventHotKey: EventHotKeyRef?
        let rightStatus = RegisterEventHotKey(
            124, // 右箭头键
            UInt32(cmdKey), // Command
            rightHotKeyID,
            GetEventDispatcherTarget(),
            0,
            &rightEventHotKey
        )

        if rightStatus == noErr {
            rightArrowHotKeyRef = rightEventHotKey
            print("✅ Command + 右箭头 注册成功")
        } else {
            print("❌ Command + 右箭头 注册失败: \(rightStatus)")
        }

        // 统一安装事件处理器（处理所有热键）
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(theEvent, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

            DispatchQueue.main.async {
                guard let appDelegate = AppDelegate.shared else { return }

                // 根据 hotKeyID 判断是哪个快捷键
                if hotKeyID.id == 1 {
                    // Command + Shift + V
                    appDelegate.toggleMenuBarExtra()
                } else if hotKeyID.id == 2 {
                    // Command + 左箭头
                    appDelegate.switchToLeftDesktop()
                } else if hotKeyID.id == 3 {
                    // Command + 右箭头
                    appDelegate.switchToRightDesktop()
                }
            }

            return noErr
        }, 1, &eventSpec, nil, nil)
    }

    private func switchToLeftDesktop() {
        // 模拟系统快捷键 Control + 左箭头
        simulateKeyPress(keyCode: 123, flags: .maskControl)
    }

    private func switchToRightDesktop() {
        // 模拟系统快捷键 Control + 右箭头
        simulateKeyPress(keyCode: 124, flags: .maskControl)
    }

    private func simulateKeyPress(keyCode: CGKeyCode, flags: CGEventFlags) {
        // 创建键盘按下事件
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) else {
            print("❌ 无法创建按键事件")
            return
        }
        keyDownEvent.flags = flags

        // 创建键盘释放事件
        guard let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            print("❌ 无法创建释放事件")
            return
        }
        keyUpEvent.flags = flags

        // 发送事件
        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
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

        // 每次都重新创建窗口，确保尺寸正确
        if let window = overlayWindow {
            window.orderOut(nil)
            overlayWindow = nil
        }

        createOverlayWindow(for: currentScreen)

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

    private func createOverlayWindow(for screen: NSScreen? = nil) {
        // 使用传入的屏幕，或者获取当前鼠标所在的屏幕
        let targetScreen: NSScreen
        if let screen = screen {
            targetScreen = screen
        } else {
            let mouseLocation = NSEvent.mouseLocation
            targetScreen = NSScreen.screens.first { screen in
                NSMouseInRect(mouseLocation, screen.frame, false)
            } ?? NSScreen.main ?? NSScreen.screens.first!
        }

        let screenFrame = targetScreen.frame

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
