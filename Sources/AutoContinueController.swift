import AppKit
import Combine

enum AutoContinueInterval: Int, CaseIterable, Identifiable {
    case five = 5
    case ten = 10
    case fifteen = 15
    case thirty = 30
    case fortyFive = 45
    case sixty = 60
    case oneTwenty = 120

    var id: Int { rawValue }
    var displayName: String { "\(rawValue) 分钟" }

    static var saved: AutoContinueInterval {
        let value = UserDefaults.standard.integer(forKey: "autoContinueIntervalMinutes")
        return AutoContinueInterval(rawValue: value) ?? .thirty
    }
}

enum AutoContinueTarget: String, CaseIterable, Identifiable {
    case agentWindows
    case allTerminalWindows

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .agentWindows: return "仅 Codex / Claude 窗口"
        case .allTerminalWindows: return "所有 Terminal 窗口"
        }
    }

    static var saved: AutoContinueTarget {
        guard let raw = UserDefaults.standard.string(forKey: "autoContinueTarget"),
              let target = AutoContinueTarget(rawValue: raw) else {
            return .agentWindows
        }
        return target
    }
}

@MainActor
final class AutoContinueController: NSObject, ObservableObject {
    static let shared = AutoContinueController()

    @Published private(set) var isEnabled: Bool
    @Published private(set) var interval: AutoContinueInterval
    @Published private(set) var target: AutoContinueTarget
    @Published private(set) var windowStartMinutes: Int?
    @Published private(set) var nextAttemptAt: Date?
    @Published private(set) var lastAttemptAt: Date?
    @Published private(set) var lastSentCount: Int?
    @Published private(set) var lastStatusMessage: String?

    private let windowHours: TimeInterval = 5 * 60 * 60
    private var timer: Timer?
    private var windowTimer: Timer?
    private var started = false

    override private init() {
        if UserDefaults.standard.object(forKey: "autoContinueEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "autoContinueEnabled")
        }
        isEnabled = UserDefaults.standard.bool(forKey: "autoContinueEnabled")
        interval = AutoContinueInterval.saved
        target = AutoContinueTarget.saved
        let savedMinutes = UserDefaults.standard.integer(forKey: "autoContinueWindowStartMinutes")
        windowStartMinutes = (0..<1440).contains(savedMinutes) ? savedMinutes : nil
        lastAttemptAt = UserDefaults.standard.object(forKey: "lastAutoContinueAttempt") as? Date
        super.init()
    }

    func start() {
        guard !started else { return }
        started = true
        scheduleNextAttempt()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "autoContinueEnabled")
        scheduleNextAttempt()
    }

    func setInterval(_ newInterval: AutoContinueInterval) {
        interval = newInterval
        UserDefaults.standard.set(newInterval.rawValue, forKey: "autoContinueIntervalMinutes")
        scheduleNextAttempt()
    }

    func setTarget(_ newTarget: AutoContinueTarget) {
        target = newTarget
        UserDefaults.standard.set(newTarget.rawValue, forKey: "autoContinueTarget")
    }

    func setWindowStartMinutes(_ minutes: Int?) {
        windowStartMinutes = minutes
        if let minutes {
            UserDefaults.standard.set(minutes, forKey: "autoContinueWindowStartMinutes")
        } else {
            UserDefaults.standard.set(-1, forKey: "autoContinueWindowStartMinutes")
        }
        scheduleWindow()
    }

    var windowScheduleDescription: String {
        guard let windowStartMinutes else { return "关闭" }
        return String(format: "%02d:%02d 起", windowStartMinutes / 60, windowStartMinutes % 60)
    }

    /// Today's anchor date, used to seed the time picker.
    var windowStartDate: Date? {
        guard let windowStartMinutes else { return nil }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = windowStartMinutes / 60
        components.minute = windowStartMinutes % 60
        components.second = 0
        return Calendar.current.date(from: components)
    }

    func sendNow() {
        performAttempt(automatic: false)
    }

    var nextAttemptDescription: String? {
        guard let nextAttemptAt else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: nextAttemptAt)
    }

    private func scheduleNextAttempt() {
        timer?.invalidate()
        timer = nil
        nextAttemptAt = nil
        guard isEnabled else {
            scheduleWindow()
            return
        }

        let fireDate = Date().addingTimeInterval(TimeInterval(interval.rawValue * 60))
        nextAttemptAt = fireDate
        let timer = Timer(fireAt: fireDate, interval: 0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        scheduleWindow()
    }

    /// Resumes sessions again whenever a new usage window opens, even if the interval has not elapsed.
    private func scheduleWindow() {
        windowTimer?.invalidate()
        windowTimer = nil
        guard isEnabled, let windowStartMinutes else { return }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = windowStartMinutes / 60
        components.minute = windowStartMinutes % 60
        components.second = 0
        var fireDate = Calendar.current.date(from: components) ?? Date()
        while fireDate <= Date() {
            fireDate = fireDate.addingTimeInterval(windowHours)
        }

        let timer = Timer(fireAt: fireDate, interval: 0, target: self, selector: #selector(windowOpened), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        windowTimer = timer
    }

    @objc private func timerFired() {
        performAttempt(automatic: true)
    }

    @objc private func windowOpened() {
        performAttempt(automatic: true)
    }

    private func performAttempt(automatic: Bool) {
        let now = Date()
        lastAttemptAt = now

        guard let result = TerminalManager.shared.sendContinueToTerminalSessions(
            includeAllWindows: target == .allTerminalWindows
        ) else {
            lastSentCount = nil
            lastStatusMessage = "无法检查 Terminal 会话"
            UserDefaults.standard.set(now, forKey: "lastAutoContinueAttempt")
            scheduleNextAttempt()
            return
        }

        lastSentCount = result.sent

        if result.sent > 0 {
            lastStatusMessage = automatic
                ? "已自动继续 \(result.sent) 个会话"
                : "已手动继续 \(result.sent) 个会话"
        } else if result.busy > 0 {
            lastStatusMessage = "\(result.busy) 个会话正在运行中，已跳过"
        } else if !automatic {
            lastStatusMessage = "没有找到匹配的 Codex / Claude 会话"
        } else {
            lastStatusMessage = "本轮没有可继续的会话"
        }

        UserDefaults.standard.set(now, forKey: "lastAutoContinueAttempt")
        scheduleNextAttempt()
    }
}
