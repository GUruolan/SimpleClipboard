import Cocoa
import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // 【重要提醒】使用 NSEvent.addGlobalMonitorForEvents 需要在系统设置的“辅助功能”中授予应用权限，才能在应用不活跃时全局生效。
    
    // 存储 MenuBarExtra 窗口的引用或状态 (如果需要，但通常 SwiftUI 会管理)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // 注册全局快捷键 (Control + Shift + K)
        // 必须在应用启动后注册
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            
            // --- 检查快捷键：Control + Shift + 空格 ---
            
            // 检查 Control 键
            let hasControl = event.modifierFlags.contains(.control)
            // 检查 Shift 键
            let hasShift = event.modifierFlags.contains(.shift)
            // 检查空格键 (KeyCode 49)
            let isSpaceKey = event.keyCode == 49

            // 精确匹配 Control + Shift + 空格
            if isSpaceKey && hasControl && hasShift {
                // 切换 MenuBarExtra 窗口的显示状态
                self?.toggleMenuBarExtra()
            }
        }
    }
    
    func toggleMenuBarExtra() {
        // 由于 SwiftUI 的 MenuBarExtra 没有直接的 close() 或 show() API，
        // 这里的逻辑是通过激活/去激活应用来间接控制窗口状态。
        
        if !NSApp.isActive {
            // 如果应用不活跃，激活它。对于 MenuBarExtra 应用，这通常会显示其窗口。
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // 如果应用已活跃，且当前有 Key Window（即历史记录窗口），则关闭它。
            // 关闭窗口后，应用会变为不活跃状态。
            if let window = NSApp.keyWindow {
                window.close()
                NSApp.deactivate() // 确保应用去活跃，以便下一次激活时窗口能重新弹出
            } else {
                // 如果应用活跃但窗口已关闭，再次尝试激活（触发窗口显示）
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
