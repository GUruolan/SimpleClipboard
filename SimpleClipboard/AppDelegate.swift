// AppDelegate.swift
import Cocoa
import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // 【注意】使用 NSEvent.addGlobalMonitorForEvents 只能在应用获得辅助功能权限后才能真正全局生效。
    // 否则，它只在当前应用是活跃状态时生效。
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // 注册全局快捷键 (例如：Command + Shift + C)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            
            // 检查快捷键：Command + Shift + 空格
            let commandKey = event.modifierFlags.contains(.control)
            let shiftKey = event.modifierFlags.contains(.shift)
            let cKey = event.keyCode == 49
            
            if commandKey && shiftKey && cKey {
                // 切换 MenuBarExtra 窗口的显示状态
                self.toggleMenuBarExtra()
            }
        }
    }
    
    func toggleMenuBarExtra() {
        // 切换窗口状态的逻辑比较复杂，在 SwiftUI MenuBarExtra 中，
        // 我们没有直接的 API 可以“打开/关闭”窗口。
        
        // 最佳实践是：如果没有窗口打开，就激活 App，让 MenuBarExtra 默认显示。
        if !NSApp.isActive {
            // 激活应用。由于这是菜单栏 App，激活后它会显示其 MenuBarExtra 窗口。
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // 如果应用已活跃，且当前有 Key Window（即历史记录窗口），则关闭它。
            if let window = NSApp.keyWindow {
                window.close()
            } else {
                // 如果应用活跃但窗口已关闭（通常不会发生），再次尝试激活（触发窗口显示）
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
