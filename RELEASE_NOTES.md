# TermYes v1.4.0

## 简体中文

Termosaic 现更名为 **TermYes**，并整合 bypass-yes 的命令守卫。

### 本次更新

- 保留终端画布、窗口自动排列、快捷键及在线更新功能。
- 新增菜单栏 Agent 命令守卫入口，整合十三类客户端适配器，支持逐客户端安装、更新、备份与恢复。
- 危险与警告规则统一硬拒绝；可捕获的输入或桥接错误不再静默放行。
- 修复组合 Shell 命令中安全删除覆盖其他危险删除的漏拦截问题。
- 移除自动回答 `yes`；对识别出的权限提示、守卫拒绝和未知自动恢复状态不发送“继续”。
- 重写中英文 README，说明依赖、安装方式、能力门槛及安全边界。

### 下载与升级

- **新安装：** `TermYes-v1.4.0-macOS.dmg`。
- **旧版自动更新：** `Termosaic-v1.4.0-macOS.dmg`，为兼容包，不是另一个产品版本。
- 两个包均为 macOS 13+ 的 Apple Silicon / Intel 通用架构，附各自的 `.sha256` 文件。
- 保留原 Bundle ID 与配置路径；旧版自动升级后应用目录可能仍叫 `Termosaic.app`，但显示名称为 TermYes。
- GitHub 仓库暂保留 `zzusec/Termosaic`。请勿同时运行新旧应用副本。

### 重要限制

**本版本不自动开启任何客户端的 YOLO，也不自动批准原生权限请求。** 十三类适配器尚未完成真实客户端端到端验证，已有权限配置保持不变。Hook 加载/信任与宿主超时行为仍可能影响拦截；守卫不是沙箱，不覆盖全部危险语义、独立文件编辑或 MCP 工具。

窗口管理无需 Python；可选守卫需要可用的 `/usr/bin/python3`。社区构建为 ad-hoc 签名，尚未 Apple 公证。

## English

Termosaic is now **TermYes**, with the command-guard module from bypass-yes integrated.

### What's new

- Retains the terminal canvas, automatic tiling, shortcuts, and in-app updates.
- Adds a menu-bar Agent guard entry with thirteen client adapters and per-client install, update, backup, and restore controls.
- Hard-denies danger and warning rules; caught input/bridge failures no longer silently allow calls.
- Fixes a classifier issue where a safe nested deletion could hide another dangerous deletion in a combined shell command.
- Removes automatic `yes` responses; recognized permission prompts, guard denials, and unknown automatic-resume states no longer receive `继续`.
- Rewrites both READMEs with installation instructions, dependencies, capability gates, and safety boundaries.

### Downloads and migration

- **New installs:** `TermYes-v1.4.0-macOS.dmg`.
- **Older automatic updaters:** `Termosaic-v1.4.0-macOS.dmg`, a compatibility image of the same application.
- Both support macOS 13+ on Apple Silicon and Intel, with matching `.sha256` files.
- Existing bundle identity and configuration paths remain stable. Automatic upgrades may keep the installed folder named `Termosaic.app` while displaying TermYes.
- The repository remains `zzusec/Termosaic`. Do not run old and new copies simultaneously.

### Important limitations

**This release does not enable client YOLO modes or auto-approve native permission requests.** All thirteen adapters await real-client end-to-end validation; existing permission settings are unchanged. Hook loading/trust and host timeout behavior can still prevent interception. The guard is not a sandbox and does not cover every dangerous operation, independent file-editing tools, or MCP calls.

Window management does not require Python; optional guards require a working `/usr/bin/python3`. Community builds are ad-hoc signed and not Apple-notarized.
