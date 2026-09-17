import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if UserDefaults.standard.object(forKey: "hideTerminalOnQuit") == nil {
            UserDefaults.standard.set(true, forKey: "hideTerminalOnQuit")
        }
        TerminalManager.shared.start()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        TerminalManager.shared.showDashboard()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        TerminalManager.shared.prepareForTermination()
    }
}

@main
struct TermosaicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var manager = TerminalManager.shared
    @AppStorage("hideTerminalOnQuit") private var hideTerminalOnQuit = true

    private var statusText: String {
        switch manager.phase {
        case .starting:
            return "正在连接 Terminal…"
        case .needsPermission:
            return "需要辅助功能权限"
        case .hidden:
            return "终端已隐藏 · \(manager.terminalWindowCount) 个窗口"
        case .visible:
            return "终端已显示 · \(manager.terminalWindowCount) 个窗口"
        case .terminalNotRunning:
            return "Terminal 尚未运行"
        case .error(let message):
            return message
        }
    }

    private var menuBarSymbol: String {
        switch manager.phase {
        case .visible:
            return "rectangle.grid.2x2.fill"
        case .needsPermission:
            return "exclamationmark.triangle.fill"
        case .hidden, .terminalNotRunning:
            return "rectangle.grid.2x2"
        case .starting, .error:
            return "rectangle.grid.2x2"
        }
    }

    var body: some Scene {
        MenuBarExtra {
            Text(statusText)
            Divider()

            Button("显示并平铺") {
                manager.showDashboard()
            }
            .keyboardShortcut("1", modifiers: [.command, .option])

            Button("隐藏终端") {
                manager.hideDashboard()
            }
            .keyboardShortcut("2", modifiers: [.command, .option])

            Button("重新排列到鼠标所在显示器") {
                manager.useDisplayUnderPointerAndRetile()
            }
            .keyboardShortcut("3", modifiers: [.command, .option])
            .disabled(!manager.accessibilityGranted)

            if !manager.accessibilityGranted {
                Divider()
                Text("授权后才能移动 Terminal 窗口")
                Button("打开辅助功能设置…") {
                    manager.openAccessibilitySettings()
                }
            }

            Divider()
            Toggle("退出时隐藏 Terminal", isOn: $hideTerminalOnQuit)

            Divider()
            Button("退出 Termosaic") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Label("Termosaic", systemImage: menuBarSymbol)
        }
        .menuBarExtraStyle(.menu)
    }
}
