#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TermYes shell hook adapter. Normal calls retain native permissions.
Warnings/errors deny; no ask/force_ask and no silent error fallback.
Host hook loading, trust and timeout behavior still require client validation.
"""

import json
import os
import sys


def read_payload():
    raw = sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()
    data = json.loads(raw)
    if not isinstance(data, dict):
        raise ValueError("无效的 hook 输入")
    return data


def emit(level, reason=""):
    print(json.dumps({"level": level, "reason": reason}, ensure_ascii=False))


def main():
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import core
    data = read_payload()
    cmd = core.command_text(data.get("command"))

    cwd = data.get("cwd") or os.getcwd()
    level, reason = core.classify(cmd, cwd, bypass=False)
    if level in ("block", "warn"):
        core.play_sound()
    emit(level, reason)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        emit("block", "守卫无法判定命令，已拒绝；请修复守卫，不要重试或绕过。")
