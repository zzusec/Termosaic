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
    @Published private(set) var nextAttemptAt: Date?
    @Published private(set) var lastAttemptAt: Date?
    @Published private(set) var lastSentCount: Int?

    private var timer: Timer?
    private var started = false

    override private init() {
        if UserDefaults.standard.object(forKey: "autoContinueEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "autoContinueEnabled")
        }
        isEnabled = UserDefaults.standard.bool(forKey: "autoContinueEnabled")
        interval = AutoContinueInterval.saved
        target = AutoContinueTarget.saved
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

    func sendNow() {
        performAttempt()
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
        guard isEnabled else { return }

        let delay = TimeInterval(interval.rawValue * 60)
        let fireDate = Date().addingTimeInterval(delay)
        nextAttemptAt = fireDate
        let timer = Timer(fireAt: fireDate, interval: 0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    @objc private func timerFired() {
        performAttempt()
    }

    private func performAttempt() {
        let sentCount = TerminalManager.shared.sendContinueToTerminalSessions(
            includeAllWindows: target == .allTerminalWindows
        )
        let now = Date()
        lastAttemptAt = now
        lastSentCount = sentCount
        UserDefaults.standard.set(now, forKey: "lastAutoContinueAttempt")
        scheduleNextAttempt()
    }
}
