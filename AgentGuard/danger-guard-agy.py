#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TermYes shell hook adapter. Normal calls retain native permissions.
Warnings/errors deny; no ask/force_ask and no silent error fallback.
Host hook loading, trust and timeout behavior still require client validation.
"""

import json
import os
import sys


def emit(decision, reason):
    print(json.dumps({
        "decision": decision,
        "reason": "[命令守卫] " + reason,
    }, ensure_ascii=False))


def get_cwd(data, args):
    cwd = args.get("Cwd")
    if isinstance(cwd, str) and cwd:
        return cwd
    paths = data.get("workspacePaths") or []
    if paths and isinstance(paths[0], str):
        return paths[0]
    return os.getcwd()


def main():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import core
    data = json.loads(sys.stdin.read())
    call = data.get("toolCall")
    if not isinstance(call, dict) or not isinstance(call.get("name"), str):
        raise ValueError("缺失工具调用")
    if call.get("name") != "run_command":
        return
    args = call.get("args") or {}
    cmd = core.command_text(args.get("CommandLine"))

    level, reason = core.classify(cmd, get_cwd(data, args))
    if level == "block":
        core.play_sound()
        core.notify_user(cmd, reason)
        emit("deny", reason)

if __name__ == "__main__":
    try:
        main()
    except Exception:
        emit("deny", "守卫无法判定命令，已拒绝；请修复守卫，不要重试或绕过。")
