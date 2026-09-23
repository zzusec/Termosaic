import AppKit

@main
struct TerminalResumeTests {
    static func main() {
        func evaluate(_ text: String, handler: String = "mustPauseResume") -> Bool {
            let escaped = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            let source = TerminalResumePolicy.appleScriptHandlers + "\nreturn \(handler)(\"\(escaped)\")"
            var error: NSDictionary?
            guard let script = NSAppleScript(source: source) else { fatalError("Invalid policy script") }
            let result = script.executeAndReturnError(&error)
            precondition(error == nil, "\(String(describing: error))")
            return result.booleanValue
        }
        for text in ["Proceed? (y/n)", "YES/NO", "是否继续", "[命令守卫] 已拦截", "Permission denied",
                     "Would you like to run this command?", "Password:", "需要授权", "Hook failed", "Trust this hook?"] {
            precondition(evaluate(text), "Must not type into: \(text)")
        }
        precondition(!evaluate("Usage limit reached; retry later"))
        precondition(!evaluate("Connection interrupted"))
        for text in ["Usage limit reached; retry later", "Connection interrupted", "网络错误"] {
            precondition(evaluate(text, handler: "canAutomaticallyResume"))
        }
        for text in ["Task completed", "Waiting for input", "Usage limit reached; approve?", "[命令守卫] 已拦截 Network error"] {
            precondition(!evaluate(text, handler: "canAutomaticallyResume"))
        }
        print("Terminal resume policy tests passed (no Terminal events sent).")
    }
}
