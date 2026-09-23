# -*- coding: utf-8 -*-
"""Shared TermYes shell-text rules, migrated from bypass-yes.
Both BLOCK and WARN become deny. This is not a sandbox or a complete threat model.
Native-client permission settings and old prefix rules are intentionally untouched.
"""

# 系统关键目录(chmod/chown 等仅当作用于这些目录时才视为危险)
SYS = r"(?:/(?:etc|usr|bin|sbin|var|lib|lib64|boot|opt|root|System|Library|Applications)\b|\s/\s|\s/$|\s/\*)"

# BLOCK:不可逆毁灭 → 拒绝
BLOCK = [
    (r"\bmkfs(\.\w+)?\b",                                     "mkfs 格式化文件系统"),
    (r"\bdd\b[^\n]*\bof=/dev/r?(disk|sd|hd|nvme)",            "dd 写入物理磁盘"),
    (r">\s*/dev/r?(disk|sd|hd|nvme)",                         "重定向覆写物理磁盘"),
    (r":\s*\(\s*\)\s*\{\s*:\s*\|\s*:&\s*\}\s*;\s*:",          "fork bomb 炸弹"),
    (r"\bdiskutil\b[^\n]*\beraseDisk\b",                      "diskutil 抹掉整盘"),
]

# WARN:危险但可能合理 → 在 TermYes 中同样硬拒绝
# 只保留「系统级 / 难以撤销 / 对外发布」的操作。日常 dev 命令(kill、killall、rmdir、
# unlink、git branch -D、sudo 本身等)一律不在此列,避免误拦。
WARN = [
    (r"\bdiskutil\b[^\n]*\b(erase|partition|reformat|eraseVolume|eraseDisk)\b", "diskutil 抹盘/分区"),
    (r"\bfdisk\b",                                                              "fdisk 分区"),
    (r"\bshutdown\b",                                                           "shutdown 关机"),
    (r"\breboot\b",                                                             "reboot 重启"),
    (r"\bhalt\b",                                                               "halt 停机"),
    (r"\bpoweroff\b",                                                           "poweroff 断电"),
    (r"\bchmod\b[^\n]*(?:-R|--recursive)[^\n]*" + SYS,                          "chmod -R 改系统目录权限"),
    (r"\bchown\b[^\n]*(?:-R|--recursive)[^\n]*" + SYS,                          "chown -R 改系统目录属主"),
    (r">\s*/etc/",                                                             "写入 /etc 系统文件"),
    (r"\bcurl\b[^|]*\|\s*(sudo\s+)?(ba|z)?sh\b",                               "curl 管道执行远程脚本"),
    (r"\bwget\b[^|]*\|\s*(sudo\s+)?(ba|z)?sh\b",                               "wget 管道执行远程脚本"),
    # 选项只在本命令段内找(不跨 ; && |):否则 `git push origin main && rm -f x`
    # 里 rm 的 -f 会被算成 git push -f,误判成强制推送
    (r"\bgit\s+push\b[^;&|\n]*(--force\b|--force-with-lease\b|\s-f\b)",         "git 强制推送"),
    (r"\bgit\s+reset\b[^;&|\n]*--hard\b",                                       "git reset --hard 丢弃改动"),
    (r"\bgit\s+clean\b[^;&|\n]*\s-\w*f",                                        "git clean -f 删未跟踪文件"),
    (r"\bnpm\s+publish\b",                                                      "npm publish 发布包"),
    (r"\bcrontab\b[^\n]*\s-r\b",                                                "crontab -r 清空定时任务"),
    (r"\bdocker\b[^\n]*\bprune\b[^\n]*(--volumes|--all|\s-a\b)",                "docker prune 清理(含数据卷/全部)"),
]

# 被拦时除了响铃,要不要再发一条 macOS 通知中心横幅(不带按钮、不抢焦点)。
# 终端提示可能被 TUI 重绘盖掉,开着这个能保证看得见。
NOTIFY_CENTER = False

# rm 目标分级参数:这些根目录下的路径视为临时目录,可静默删除
TEMP_ROOTS = ("/tmp", "/private/tmp")

# rm 分级的 reason 文案。这几条不在 BLOCK/WARN 表里(由 rm 目标分级动态产生),
# 由 core.py 路径判定返回，各适配器共享。
RM_BLOCK_REASON = "rm 递归删除根目录/家目录/整个用户目录/一级系统目录"
RM_WARN_REASON = "rm -rf 删除整个项目/系统路径或目标不明"
RM_SAFE_REASON = "rm -rf 目标为普通目录，未命中删除保护规则"
