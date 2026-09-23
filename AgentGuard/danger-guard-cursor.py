#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TermYes shell hook adapter. Normal calls retain native permissions.
Warnings/errors deny; no ask/force_ask and no silent error fallback.
Host hook loading, trust and timeout behavior still require client validation.
"""

import json
import os
import sys


def emit(permission, reason):
    print(json.dumps({
        "permission": permission,
        "userMessage": "[命令守卫] " + reason,
        "agentMessage": "[命令守卫] 已拦下这条命令:" + reason + "。别重试,换别的做法。",
    }, ensure_ascii=False))


def get_cwd(data):
    cwd = data.get("cwd")
    if cwd:
        return cwd
    roots = data.get("workspace_roots") or []
    if roots and isinstance(roots[0], str):
        return roots[0]
    return os.getcwd()


def main():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import core
    data = json.loads(sys.stdin.read())
    cmd = core.command_text(data.get("command"))

    level, reason = core.classify(cmd, get_cwd(data))
    if level == "block":
        core.play_sound()
        core.notify_user(cmd, reason)
        emit("deny", reason)

if __name__ == "__main__":
    try:
        main()
    except Exception:
        emit("deny", "守卫无法判定命令，已拒绝；请修复守卫，不要重试或绕过。")
