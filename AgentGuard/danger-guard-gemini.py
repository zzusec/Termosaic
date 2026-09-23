#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TermYes shell hook adapter. Normal calls retain native permissions.
Warnings/errors deny; no ask/force_ask and no silent error fallback.
Host hook loading, trust and timeout behavior still require client validation.
"""

import json
import os
import sys


def emit(reason):
    print(json.dumps({
        "decision": "deny",
        "reason": "[命令守卫] " + reason,               # 给模型看的,作为工具错误返回
        "systemMessage": "[命令守卫] 已拦截:" + reason,  # 给终端里的人看的
    }, ensure_ascii=False))


def main():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import core
    data = json.loads(sys.stdin.read())
    if not isinstance(data, dict) or not isinstance(data.get("tool_name"), str):
        raise ValueError("缺失工具名")
    if data.get("tool_name") not in core.TOOL_NAMES:   # Gemini 的 shell 工具叫 run_shell_command
        return
    cmd = core.get_command(data)

    level, reason = core.classify(cmd, data.get("cwd") or os.getcwd(), bypass=True)
    if level in ("block", "warn"):
        core.play_sound()
        core.notify_user(cmd, reason)
        emit(reason)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        emit("守卫无法判定命令，已拒绝；请修复守卫，不要重试或绕过。")
