import SwiftUI
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidActivateApplication(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        GlobalHotKeyController.shared.activateSavedShortcut()
        TerminalManager.shared.start()
        AutoContinueController.shared.start()
        UpdateController.shared.start()
    }

    @objc private func workspaceDidActivateApplication(_ notification: Notification) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              application.bundleIdentifier != "com.apple.Terminal",
              application.bundleIdentifier != "io.github.zzusec.termosaic" else { return }
        TerminalManager.shared.hideDashboardIfVisible()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        TerminalManager.shared.showDashboard()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if !UpdateController.shared.isInstallingUpdate {
            TerminalManager.shared.prepareForTermination()
        }
    }
}

@main
struct TermosaicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var manager = TerminalManager.shared
    @StateObject private var hotKeys = GlobalHotKeyController.shared
    @StateObject private var autoContinue = AutoContinueController.shared
    @StateObject private var updater = UpdateController.shared

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

    private var updateVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "未知"
        if updater.isDownloading || updater.isInstallingUpdate {
            return "版本 v\(version)（正在更新…）"
        }
        if updater.isChecking {
            return "版本 v\(version)（正在检查…）"
        }
        if updater.isUpToDate {
            return "版本 v\(version)（已是最新）"
        }
        return "版本 v\(version)"
    }

    private var updateDetailText: String? {
        guard !updater.isChecking,
              !updater.isDownloading,
              !updater.isInstallingUpdate,
              !updater.isUpToDate else { return nil }
        return updater.statusMessage
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

            Toggle(
                "显示终端画布",
                isOn: Binding(
                    get: { manager.phase == .visible },
                    set: { $0 ? manager.showDashboard() : manager.hideDashboard() }
                )
            )
            .keyboardShortcut("1", modifiers: [.command, .option])

            Button("重新排列到鼠标所在显示器") {
                manager.useDisplayUnderPointerAndRetile()
            }
            .keyboardShortcut("2", modifiers: [.command, .option])
            .disabled(!manager.automationAuthorized)

            Button("发送一次“继续”") {
                autoContinue.sendNow()
            }
            .keyboardShortcut("3", modifiers: [.command, .option])
            .disabled(!manager.automationAuthorized)

            if !manager.automationAuthorized {
                Button("打开自动化设置…") {
                    manager.openAutomationSettings()
                }
            }

            Divider()
            Menu("全局快捷键：\(hotKeys.selectedShortcut.displayName)") {
                ForEach(GlobalShortcut.allCases) { shortcut in
                    Toggle(
                        shortcut.menuTitle,
                        isOn: Binding(
                            get: { hotKeys.selectedShortcut == shortcut },
                            set: { selected in
                                if selected { hotKeys.setShortcut(shortcut) }
                            }
                        )
                    )
                }
            }

            if hotKeys.selectedShortcut == .commandO {
                Text("⌘O 会覆盖其他应用的“打开”快捷键")
            }
            if let error = hotKeys.registrationError {
                Text(error)
            }

            Divider()
            Menu("自动“继续”") {
                Toggle(
                    "自动发送“继续”",
                    isOn: Binding(
                        get: { autoContinue.isEnabled },
                        set: { autoContinue.setEnabled($0) }
                    )
                )

                Divider()
                Menu("间隔：\(autoContinue.interval.displayName)") {
                    ForEach(AutoContinueInterval.allCases) { interval in
                        Toggle(
                            interval.displayName,
                            isOn: Binding(
                                get: { autoContinue.interval == interval },
                                set: { selected in
                                    if selected { autoContinue.setInterval(interval) }
                                }
                            )
                        )
                    }
                }
                .disabled(!autoContinue.isEnabled)

                Menu("范围：\(autoContinue.target.displayName)") {
                    ForEach(AutoContinueTarget.allCases) { target in
                        Toggle(
                            target.displayName,
                            isOn: Binding(
                                get: { autoContinue.target == target },
                                set: { selected in
                                    if selected { autoContinue.setTarget(target) }
                                }
                            )
                        )
                    }
                }
                .disabled(!autoContinue.isEnabled)

                Button("激活 5h 窗口：\(autoContinue.windowScheduleDescription)") {
                    WindowSchedulePicker.shared.show()
                }
                .disabled(!autoContinue.isEnabled)

                if let nextAttempt = autoContinue.nextAttemptDescription {
                    Text("下次：\(nextAttempt)")
                }
                if let statusMessage = autoContinue.lastStatusMessage {
                    Text(statusMessage)
                } else if let sentCount = autoContinue.lastSentCount {
                    Text("上次已发送到 \(sentCount) 个会话")
                }
            }

            Divider()
            Text(updateVersionText)
            Button(updater.isChecking ? "正在检查…" : "检查更新") {
                updater.checkForUpdates()
            }
            .disabled(updater.isChecking || updater.isDownloading || updater.isInstallingUpdate)

            if let detail = updateDetailText {
                Text(detail)
            }

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
