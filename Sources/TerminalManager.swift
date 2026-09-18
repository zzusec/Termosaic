@preconcurrency import AppKit
import Combine
import os

@MainActor
final class TerminalManager: NSObject, ObservableObject {
    static let shared = TerminalManager()

    enum Phase: Equatable {
        case starting
        case needsAutomationPermission
        case hidden
        case visible
        case terminalNotRunning
        case error(String)
    }

    @Published private(set) var phase: Phase = .starting
    @Published private(set) var terminalWindowCount = 0
    @Published private(set) var automationAuthorized = true

    private let terminalBundleIdentifier = "com.apple.Terminal"
    private let logger = Logger(subsystem: "io.github.zzusec.termosaic", category: "TerminalManager")
    private let pollInterval: TimeInterval = 0.2
    private var pollTimer: Timer?
    private var lastObservedWindowCount = -1
    private var lastWindowServerCandidateCount = -1
    private var targetScreen: NSScreen?
    private var started = false
    private var dashboardRequested = false

    override private init() {
        super.init()
    }

    func start() {
        guard !started else { return }
        started = true
        startPolling()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.showDashboard()
        }
    }

    func openAutomationSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Automation"
        ]
        for value in candidates {
            if let url = URL(string: value), NSWorkspace.shared.open(url) { return }
        }
    }

    func showDashboard() {
        dashboardRequested = true
        lastWindowServerCandidateCount = -1
        targetScreen = screenUnderPointer() ?? NSScreen.main

        if let terminal = terminalApplication() {
            _ = terminal.unhide()
            _ = terminal.activate(options: [.activateAllWindows])
            phase = .visible
            scheduleTilePasses()
        } else {
            launchTerminal()
        }
    }

    func hideDashboardIfVisible() {
        guard dashboardRequested, terminalApplication()?.isHidden == false else { return }
        hideDashboard(activateManager: false)
    }

    func hideDashboard(activateManager: Bool = true) {
        dashboardRequested = false
        if let terminal = terminalApplication() {
            _ = terminal.hide()
        }

        phase = terminalApplication() == nil ? .terminalNotRunning : .hidden

        if activateManager {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func toggleDashboard() {
        if dashboardRequested, terminalApplication()?.isHidden == false {
            hideDashboard()
        } else {
            showDashboard()
        }
    }

    func retile() {
        if targetScreen == nil {
            targetScreen = screenUnderPointer() ?? NSScreen.main
        }
        tileTerminalWindows()
    }

    func useDisplayUnderPointerAndRetile() {
        targetScreen = screenUnderPointer() ?? NSScreen.main
        retile()
    }

    func sendContinueToTerminalSessions(includeAllWindows: Bool, onlyWhenQuotaBlocked: Bool = false) -> Int? {
        let sendToAll = includeAllWindows ? "true" : "false"
        let requireQuotaBlock = onlyWhenQuotaBlocked ? "true" : "false"
        let source = """
        set sendToAll to \(sendToAll)
        set requireQuotaBlock to \(requireQuotaBlock)
        set sentCount to 0
        tell application id "com.apple.Terminal"
            repeat with windowRef in every window
                try
                    set currentWindow to contents of windowRef
                    set activeTab to selected tab of currentWindow
                    set windowName to name of currentWindow as text
                    set processText to (processes of activeTab) as text
                    set screenText to get contents of selected tab of currentWindow
                    set shouldSend to sendToAll
                    if shouldSend is false then
                        ignoring case
                            if windowName contains "codex" or windowName contains "claude" or processText contains "codex" or processText contains "claude" then
                                set shouldSend to true
                            end if
                        end ignoring
                    end if

                    set quotaBlocked to false
                    ignoring case
                        if screenText contains "you've hit your usage limit" or screenText contains "you have hit your usage limit" or screenText contains "usage limit reached" or screenText contains "rate limit reached" or screenText contains "try again in" or screenText contains "额度已用完" or screenText contains "已达到使用上限" or screenText contains "达到使用限额" or screenText contains "限额将在" or screenText contains "请稍后重试" then
                            set quotaBlocked to true
                        end if
                    end ignoring

                    if shouldSend and ((requireQuotaBlock is false) or quotaBlocked) then
                        do script "继续" in activeTab
                        set sentCount to sentCount + 1
                    end if
                end try
            end repeat
        end tell
        return sentCount
        """

        guard let result = executeAppleScript(source) else { return nil }
        return Int(result.int32Value)
    }

    func prepareForTermination() {
        let preferenceExists = UserDefaults.standard.object(forKey: "hideTerminalOnQuit") != nil
        if !preferenceExists || UserDefaults.standard.bool(forKey: "hideTerminalOnQuit") {
            hideDashboard(activateManager: false)
        }
    }

    private func startPolling() {
        pollTimer?.invalidate()
        let timer = Timer(timeInterval: pollInterval, target: self, selector: #selector(pollTerminalState), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    @objc private func pollTerminalState() {
        guard let terminal = terminalApplication() else {
            terminalWindowCount = 0
            lastObservedWindowCount = 0
            if dashboardRequested { phase = .terminalNotRunning }
            return
        }

        if terminal.isHidden {
            dashboardRequested = false
            phase = .hidden
            return
        }

        guard dashboardRequested else { return }
        phase = .visible

        // Poll Window Server cheaply for near-instant change detection. Confirm with
        // Terminal AppleScript only when the candidate count changes, excluding the
        // small Terminal settings/helper window from the fast count.
        let candidateCount = windowServerCandidateCount(pid: terminal.processIdentifier)
        guard candidateCount != lastWindowServerCandidateCount else { return }
        lastWindowServerCandidateCount = candidateCount

        guard let count = readTerminalWindowCount() else { return }
        terminalWindowCount = count
        guard count != lastObservedWindowCount else { return }

        lastObservedWindowCount = count
        tileTerminalWindows(knownCount: count)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            guard let self, self.dashboardRequested else { return }
            self.tileTerminalWindows()
        }
    }

    private func launchTerminal() {
        let candidateURLs = [
            URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"),
            URL(fileURLWithPath: "/Applications/Utilities/Terminal.app")
        ]
        guard let appURL = candidateURLs.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            phase = .error("找不到系统 Terminal.app")
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { [weak self] app, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    self.phase = .error("无法启动 Terminal：\(error.localizedDescription)")
                    return
                }
                self.dashboardRequested = true
                self.phase = .visible
                _ = app?.unhide()
                self.scheduleTilePasses()
            }
        }
    }

    private func scheduleTilePasses() {
        lastObservedWindowCount = -1
        for delay in [0.2, 0.8] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.dashboardRequested else { return }
                self.tileTerminalWindows()
            }
        }
    }

    private func tileTerminalWindows(knownCount: Int? = nil) {
        guard terminalApplication() != nil else {
            phase = .terminalNotRunning
            terminalWindowCount = 0
            return
        }

        guard let count = knownCount ?? readTerminalWindowCount() else { return }
        terminalWindowCount = count
        lastObservedWindowCount = count

        guard count > 0 else {
            phase = .visible
            return
        }
        guard let screen = targetScreen ?? NSScreen.main else {
            phase = .error("找不到可用显示器")
            return
        }

        let frames = GridLayout.frames(count: count, within: screen.visibleFrame, gap: 0)
            .map(accessibilityFrame(from:))
        guard frames.count == count else { return }

        let boundsList = frames.map { frame in
            let left = Int(frame.minX.rounded())
            let top = Int(frame.minY.rounded())
            let right = Int(frame.maxX.rounded())
            let bottom = Int(frame.maxY.rounded())
            return "{\(left), \(top), \(right), \(bottom)}"
        }.joined(separator: ", ")

        let source = """
        set targetBounds to {\(boundsList)}
        tell application id "com.apple.Terminal"
            set windowList to every window
            repeat with i from 1 to count of targetBounds
                if i > (count of windowList) then exit repeat
                set currentWindow to item i of windowList
                set miniaturized of currentWindow to false
                set visible of currentWindow to true
                set bounds of currentWindow to item i of targetBounds
            end repeat
        end tell
        return count of targetBounds
        """

        guard executeAppleScript(source) != nil else { return }
        phase = .visible
    }

    private func windowServerCandidateCount(pid: pid_t) -> Int {
        guard let windows = CGWindowListCopyWindowInfo(
            [.optionAll, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return lastWindowServerCandidateCount }

        return windows.reduce(into: 0) { count, window in
            guard (window[kCGWindowOwnerPID as String] as? Int32) == pid,
                  (window[kCGWindowLayer as String] as? Int) == 0,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let width = (bounds["Width"] as? NSNumber)?.doubleValue,
                  let height = (bounds["Height"] as? NSNumber)?.doubleValue,
                  width >= 300,
                  height >= 160 else { return }
            count += 1
        }
    }

    private func readTerminalWindowCount() -> Int? {
        let source = "tell application id \"com.apple.Terminal\" to count every window"
        guard let result = executeAppleScript(source) else { return nil }
        return Int(result.int32Value)
    }

    private func executeAppleScript(_ source: String) -> NSAppleEventDescriptor? {
        guard let script = NSAppleScript(source: source) else {
            phase = .error("无法创建 Terminal 自动化脚本")
            return nil
        }

        var errorInfo: NSDictionary?
        logger.debug("Executing Terminal automation script")
        let result = script.executeAndReturnError(&errorInfo)
        guard errorInfo == nil else {
            let number = (errorInfo?[NSAppleScript.errorNumber] as? NSNumber)?.intValue ?? 0
            let message = (errorInfo?[NSAppleScript.errorMessage] as? String) ?? "未知自动化错误"
            if number == -1743 {
                automationAuthorized = false
                logger.error("Terminal automation permission denied")
                phase = .needsAutomationPermission
            } else {
                logger.error("Terminal automation failed: \(message, privacy: .public)")
                phase = .error("Terminal 自动化失败：\(message)")
            }
            return nil
        }

        automationAuthorized = true
        logger.debug("Terminal automation script completed")
        return result
    }

    private func terminalApplication() -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: terminalBundleIdentifier)
            .first(where: { !$0.isTerminated })
    }

    private func accessibilityFrame(from cocoaFrame: CGRect) -> CGRect {
        guard let primaryScreen = NSScreen.screens.first else { return cocoaFrame }
        return CGRect(
            x: cocoaFrame.minX,
            y: primaryScreen.frame.maxY - cocoaFrame.maxY,
            width: cocoaFrame.width,
            height: cocoaFrame.height
        )
    }

    private func screenUnderPointer() -> NSScreen? {
        let pointer = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(pointer) })
    }
}
