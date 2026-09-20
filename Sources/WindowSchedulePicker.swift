import AppKit

/// Lets the user set the start time by scrolling: 5 minutes per notch, one hour with ⇧.
private final class ScrollDatePicker: NSDatePicker {
    override func scrollWheel(with event: NSEvent) {
        guard event.scrollingDeltaY != 0 else { return }
        let step = event.modifierFlags.contains(.shift) ? 60 : 5
        let direction = event.scrollingDeltaY > 0 ? 1 : -1
        dateValue = Calendar.current.date(byAdding: .minute, value: direction * step, to: dateValue) ?? dateValue
    }
}

/// Lets the user pick any start time for the five-hour windows without a 24-row menu.
@MainActor
final class WindowSchedulePicker: NSObject {
    static let shared = WindowSchedulePicker()

    private var panel: NSPanel?
    private var picker: NSDatePicker?

    func show() {
        let controller = AutoContinueController.shared

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 116),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "激活 5h 窗口"
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.center()

        let label = NSTextField(labelWithString: "起始时间")
        label.frame = NSRect(x: 20, y: 62, width: 62, height: 17)
        label.alignment = .right
        panel.contentView?.addSubview(label)

        let picker = ScrollDatePicker(frame: NSRect(x: 88, y: 56, width: 130, height: 28))
        picker.datePickerStyle = .textFieldAndStepper
        picker.datePickerElements = .hourMinute
        picker.dateValue = controller.windowStartDate ?? Date()
        panel.contentView?.addSubview(picker)
        self.picker = picker

        let hint = NSTextField(labelWithString: "滚动微调 5 分钟（⇧ 按小时）· 每 5 小时一轮")
        hint.frame = NSRect(x: 20, y: 32, width: 260, height: 14)
        hint.font = NSFont.systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        panel.contentView?.addSubview(hint)

        let disable = NSButton(frame: NSRect(x: 20, y: 12, width: 84, height: 26))
        disable.title = "停用"
        disable.target = self
        disable.action = #selector(disableWindows)
        disable.bezelStyle = .rounded
        disable.isEnabled = controller.windowStartMinutes != nil
        panel.contentView?.addSubview(disable)

        let cancel = NSButton(frame: NSRect(x: 134, y: 12, width: 74, height: 26))
        cancel.title = "取消"
        cancel.target = self
        cancel.action = #selector(close)
        cancel.bezelStyle = .rounded
        cancel.keyEquivalent = "\u{1b}"
        panel.contentView?.addSubview(cancel)

        let confirm = NSButton(frame: NSRect(x: 208, y: 12, width: 74, height: 26))
        confirm.title = "好"
        confirm.target = self
        confirm.action = #selector(confirmSelection)
        confirm.bezelStyle = .rounded
        confirm.keyEquivalent = "\r"
        panel.contentView?.addSubview(confirm)
        panel.defaultButtonCell = confirm.cell as? NSButtonCell

        self.panel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    @objc private func close() {
        panel?.close()
        panel = nil
        picker = nil
    }

    @objc private func disableWindows() {
        AutoContinueController.shared.setWindowStartMinutes(nil)
        close()
    }

    @objc private func confirmSelection() {
        guard let picker else { return close() }
        let components = Calendar.current.dateComponents([.hour, .minute], from: picker.dateValue)
        guard let hour = components.hour, let minute = components.minute else { return close() }
        AutoContinueController.shared.setWindowStartMinutes(hour * 60 + minute)
        close()
    }
}
