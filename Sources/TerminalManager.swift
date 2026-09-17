@preconcurrency import AppKit
import ApplicationServices
import Combine

@MainActor
final class TerminalManager: NSObject, ObservableObject {
    static let shared = TerminalManager()

    enum Phase: Equatable {
        case starting
        case needsPermission
        case hidden
        case visible
        case terminalNotRunning
        case error(String)
    }

    @Published private(set) var phase: Phase = .starting
    @Published private(set) var terminalWindowCount = 0
    @Published private(set) var accessibilityGranted = AXIsProcessTrusted()

    private let terminalBundleIdentifier = "com.apple.Terminal"
    private let pollInterval: TimeInterval = 0.65
    private var pollTimer: Timer?
    private var lastObservedWindowCount = -1
    private var targetScreen: NSScreen?
    private var started = false
    private var dashboardRequested = false

    override private init() {
        super.init()
    }

    func start() {
        guard !started else { return }
        started = true
        requestAccessibilityPermission(showSystemPrompt: true)
        startPolling()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.showDashboard()
        }
    }

    func requestAccessibilityPermission(showSystemPrompt: Bool) {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        accessibilityGranted = AXIsProcessTrustedWithOptions([promptKey: showSystemPrompt] as CFDictionary)
        if !accessibilityGranted {
            phase = .needsPermission
        }
    }

    func openAccessibilitySettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        ]
        for value in candidates {
            if let url = URL(string: value), NSWorkspace.shared.open(url) { return }
        }
    }

    func showDashboard() {
        dashboardRequested = true
        requestAccessibilityPermission(showSystemPrompt: false)
        guard accessibilityGranted else {
            phase = .needsPermission
            NSApp.activate(ignoringOtherApps: true)
            return
        }

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

    func hideDashboard(activateManager: Bool = true) {
        dashboardRequested = false
        if let terminal = terminalApplication() {
            _ = terminal.hide()
        }

        let count = currentTerminalWindows().count
        terminalWindowCount = count
        lastObservedWindowCount = count
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
        requestAccessibilityPermission(showSystemPrompt: false)
        guard accessibilityGranted else {
            phase = .needsPermission
            return
        }
        if targetScreen == nil {
            targetScreen = screenUnderPointer() ?? NSScreen.main
        }
        tileTerminalWindows()
    }

    func useDisplayUnderPointerAndRetile() {
        targetScreen = screenUnderPointer() ?? NSScreen.main
        retile()
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
        let trustedNow = AXIsProcessTrusted()
        if trustedNow != accessibilityGranted {
            accessibilityGranted = trustedNow
            if trustedNow, dashboardRequested {
                showDashboard()
                return
            } else if !trustedNow {
                phase = .needsPermission
            }
        }

        guard accessibilityGranted else { return }
        guard let terminal = terminalApplication() else {
            terminalWindowCount = 0
            lastObservedWindowCount = 0
            if dashboardRequested { phase = .terminalNotRunning }
            return
        }

        if terminal.isHidden {
            dashboardRequested = false
            phase = .hidden
        } else if dashboardRequested {
            phase = .visible
        }

        let count = currentTerminalWindows(pid: terminal.processIdentifier).count
        terminalWindowCount = count

        guard dashboardRequested, !terminal.isHidden else {
            lastObservedWindowCount = count
            return
        }

        if count != lastObservedWindowCount {
            lastObservedWindowCount = count
            // New and closed windows share this path, so both events rebalance the grid.
            tileTerminalWindows()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self] in
                guard let self, self.dashboardRequested else { return }
                self.tileTerminalWindows()
            }
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
        for delay in [0.18, 0.48, 0.9] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.dashboardRequested else { return }
                self.tileTerminalWindows()
            }
        }
    }

    private func tileTerminalWindows() {
        guard accessibilityGranted else { return }
        guard let terminal = terminalApplication() else {
            phase = .terminalNotRunning
            terminalWindowCount = 0
            return
        }

        let windows = currentTerminalWindows(pid: terminal.processIdentifier)
        terminalWindowCount = windows.count
        lastObservedWindowCount = windows.count

        guard !windows.isEmpty else {
            phase = .visible
            return
        }
        guard let screen = targetScreen ?? NSScreen.main else {
            phase = .error("找不到可用显示器")
            return
        }

        let frames = GridLayout.frames(count: windows.count, within: screen.visibleFrame, gap: 10)
        guard frames.count == windows.count else { return }

        for (window, cocoaFrame) in zip(windows, frames) {
            setBooleanAttribute(window, name: kAXMinimizedAttribute, value: false)
            setFrame(accessibilityFrame(from: cocoaFrame), for: window)
        }
        phase = .visible
    }

    private func terminalApplication() -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: terminalBundleIdentifier)
            .first(where: { !$0.isTerminated })
    }

    private func currentTerminalWindows(pid: pid_t? = nil) -> [AXUIElement] {
        guard accessibilityGranted else { return [] }
        guard let processID = pid ?? terminalApplication()?.processIdentifier else { return [] }

        let application = AXUIElementCreateApplication(processID)
        var rawValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(application, kAXWindowsAttribute as CFString, &rawValue) == .success,
              let windows = rawValue as? [AXUIElement] else { return [] }

        return windows.filter { window in
            if booleanAttribute(window, name: kAXModalAttribute) == true { return false }
            guard stringAttribute(window, name: kAXRoleAttribute) == (kAXWindowRole as String) else { return false }
            let subrole = stringAttribute(window, name: kAXSubroleAttribute)
            return subrole == nil || subrole == (kAXStandardWindowSubrole as String)
        }
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

    private func setFrame(_ frame: CGRect, for element: AXUIElement) {
        var size = frame.size
        var point = frame.origin
        guard let sizeValue = AXValueCreate(.cgSize, &size),
              let pointValue = AXValueCreate(.cgPoint, &point) else { return }

        // Terminal quantizes sizes to character cells; a second pass keeps edges aligned.
        AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue)
        AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, pointValue)
        AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue)
        AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, pointValue)
    }

    private func setBooleanAttribute(_ element: AXUIElement, name: String, value: Bool) {
        AXUIElementSetAttributeValue(element, name as CFString, value ? kCFBooleanTrue : kCFBooleanFalse)
    }

    private func stringAttribute(_ element: AXUIElement, name: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value as? String
    }

    private func booleanAttribute(_ element: AXUIElement, name: String) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value as? Bool
    }

    private func screenUnderPointer() -> NSScreen? {
        let pointer = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(pointer) })
    }
}
