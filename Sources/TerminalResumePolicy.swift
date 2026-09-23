// ponytail: conservative text fallback only; actual command approval belongs to agent hooks.
// A false positive pauses a session rather than typing into a permission/password prompt.
enum TerminalResumePolicy {
    static let appleScriptHandlers = """
    on mustPauseResume(screenText)
        ignoring case
            repeat with marker in {"y/n", "yes/no", "want to continue", "输入 yes", "是否继续", "确认继续", "requires approval", "approval required", "would you like", "allow this", "approve", "permission denied", "命令守卫", "已拦截", "已拦下", "guard blocked", "hook failed", "blocked by", "password", "passphrase", "verification code", "密码", "验证码", "登录", "sign in", "trust", "授权", "拒绝", "确认", "choose", "请选择"}
                if screenText contains (marker as text) then return true
            end repeat
        end ignoring
        return false
    end mustPauseResume

    on canAutomaticallyResume(screenText)
        if my mustPauseResume(screenText) then return false
        ignoring case
            repeat with marker in {"usage limit reached", "rate limit exceeded", "rate limit reached", "too many requests", "connection interrupted", "connection timed out", "network error", "service unavailable", "额度已用完", "额度用尽", "请求过于频繁", "连接中断", "网络错误"}
                if screenText contains (marker as text) then return true
            end repeat
        end ignoring
        return false
    end canAutomaticallyResume
    """
}
