import SwiftUI
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if UserDefaults.standard.object(forKey: "hideTerminalOnQuit") == nil {
            UserDefaults.standard.set(true, forKey: "hideTerminalOnQuit")
        }
        if UserDefaults.standard.object(forKey: "autoHideCanvasWhenSwitchingApps") == nil {
            UserDefaults.standard.set(true, forKey: "autoHideCanvasWhenSwitchingApps")
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidActivateApplication(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        GlobalHotKeyController.shared.activateSavedShortcut()
        TerminalManager.shared.start()
        AutoContinueController.shared.start()
    }

    @objc private func workspaceDidActivateApplication(_ notification: Notification) {
        guard UserDefaults.standard.bool(forKey: "autoHideCanvasWhenSwitchingApps"),
              let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              application.bundleIdentifier != "com.apple.Terminal",
              application.bundleIdentifier != "io.github.zzusec.termosaic" else { return }
        TerminalManager.shared.hideDashboardIfVisible()
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
    @StateObject private var hotKeys = GlobalHotKeyController.shared
    @StateObject private var autoContinue = AutoContinueController.shared
    @AppStorage("hideTerminalOnQuit") private var hideTerminalOnQuit = true
    @AppStorage("autoHideCanvasWhenSwitchingApps") private var autoHideCanvasWhenSwitchingApps = true

    private var statusText: String {
        switch manager.phase {
        case .starting:
            return "正在连接 Terminal…"
        case .needsAutomationPermission:
            return "需要允许控制 Terminal"
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
        case .needsAutomationPermission, .error:
            return "exclamationmark.triangle.fill"
        case .hidden, .terminalNotRunning, .starting:
            return "rectangle.grid.2x2"
        }
    }

    var body: some Scene {
        MenuBarExtra {
            Text(statusText)
            Divider()

            Button("显示并重新平铺") {
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
            .disabled(!manager.automationAuthorized)

            Divider()
            Menu("全局快捷键：\(hotKeys.selectedShortcut.displayName)") {
                ForEach(GlobalShortcut.allCases) { shortcut in
                    Button {
                        hotKeys.setShortcut(shortcut)
                    } label: {
                        if hotKeys.selectedShortcut == shortcut {
                            Label(shortcut.menuTitle, systemImage: "checkmark")
                        } else {
                            Text(shortcut.menuTitle)
                        }
                    }
                }
            }

            if hotKeys.selectedShortcut == .commandO {
                Text("⌘O 会覆盖其他应用的“打开”快捷键")
            }
            if let error = hotKeys.registrationError {
                Text(error)
            }

            Divider()
            Toggle(
                "自动发送“继续”",
                isOn: Binding(
                    get: { autoContinue.isEnabled },
                    set: { autoContinue.setEnabled($0) }
                )
            )

            Menu("重试间隔：\(autoContinue.interval.displayName)") {
                ForEach(AutoContinueInterval.allCases) { interval in
                    Button {
                        autoContinue.setInterval(interval)
                    } label: {
                        if autoContinue.interval == interval {
                            Label(interval.displayName, systemImage: "checkmark")
                        } else {
                            Text(interval.displayName)
                        }
                    }
                }
            }
            .disabled(!autoContinue.isEnabled)

            Menu("发送范围：\(autoContinue.target.displayName)") {
                ForEach(AutoContinueTarget.allCases) { target in
                    Button {
                        autoContinue.setTarget(target)
                    } label: {
                        if autoContinue.target == target {
                            Label(target.displayName, systemImage: "checkmark")
                        } else {
                            Text(target.displayName)
                        }
                    }
                }
            }
            .disabled(!autoContinue.isEnabled)

            Button("立即发送一次“继续”") {
                autoContinue.sendNow()
            }
            .disabled(!manager.automationAuthorized)

            if autoContinue.isEnabled, let nextAttempt = autoContinue.nextAttemptDescription {
                Text("下次自动重试：\(nextAttempt)")
            }
            if let sentCount = autoContinue.lastSentCount {
                Text("上次已发送到 \(sentCount) 个会话")
            }

            if !manager.automationAuthorized {
                Divider()
                Text("需要允许 Termosaic 控制系统 Terminal")
                Button("打开自动化设置…") {
                    manager.openAutomationSettings()
                }
            }

            Divider()
            Toggle("切换到其他应用时隐藏终端画布", isOn: $autoHideCanvasWhenSwitchingApps)
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
