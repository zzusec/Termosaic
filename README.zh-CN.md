<div align="center">
  <img src="Resources/TermosaicIcon-1024.png" width="144" alt="Termosaic 图标">
  <h1>Termosaic</h1>
  <p><strong>将系统 Terminal 窗口组合成统一画布的原生 macOS 菜单栏工具。</strong></p>
  <p>
    <a href="https://github.com/zzusec/Termosaic/actions/workflows/build.yml"><img src="https://github.com/zzusec/Termosaic/actions/workflows/build.yml/badge.svg" alt="构建状态"></a>
    <img src="https://img.shields.io/badge/macOS-13%2B-black" alt="macOS 13+">
    <img src="https://img.shields.io/badge/Swift-native-orange" alt="原生 Swift">
  </p>
  <p><a href="README.md">English</a> · <strong>简体中文</strong></p>
</div>

Termosaic 管理你已经打开的系统 `Terminal.app` 窗口。它不会替换系统终端、不会嵌入 Shell、不会修改 Terminal 配置，也不会调整其他应用的窗口。

## 主要功能

- 将所有 Terminal 窗口排列成无外边距、无窗口间距的画布。
- 4 个窗口使用 2×2 布局，6 个窗口使用 3×2 布局。
- 大约每 0.2 秒检测窗口新增或关闭，并立即重新平铺。
- 保存稳定的窗口身份，按照顺时针方向分配位置。
- 平铺前自动恢复最小化的 Terminal 窗口。
- 将所有 Terminal 窗口作为一个逻辑画布一起显示或隐藏。
- 切换到其他应用时可以自动隐藏终端画布。
- 提供可修改的全局呼出快捷键，默认为 `⌘O`。
- 定时向 Codex/Claude 会话发送“继续”，让额度限制、SSH 或网络中断、卡住的提示都能自动恢复；遇到需要确认的提示会自动回答 yes。
- 在线检查 GitHub Release，并自动下载、校验、安装和重新启动新版本。
- 只驻留在顶部菜单栏，不显示 Dock 图标，也没有常驻桌面控制窗口。
- 同时支持 Apple Silicon 和 Intel Mac。

## 系统要求

- macOS 13 或更高版本。
- 允许 Termosaic 自动化控制系统 Terminal。
- 在线检查更新时需要网络连接。
- 只有从源码构建时才需要 Xcode Command Line Tools。

## 安装

从 [GitHub Releases](https://github.com/zzusec/Termosaic/releases/latest) 下载最新安装包：

1. 打开 `Termosaic-vX.Y.Z-macOS.dmg`。
2. 将 `Termosaic.app` 拖到 `Applications` 快捷方式。
3. 社区版本使用 ad-hoc 签名，尚未经过 Apple notarization。首次打开时，macOS 可能要求使用 **按住 Control 点击 → 打开**。

应用安装位置：

```text
/Applications/Termosaic.app
```

## 权限设置

首次运行时，请允许 Termosaic 控制 Terminal：

```text
系统设置 → 隐私与安全性 → 自动化 → Termosaic → Terminal
```

该权限只在本机用于统计、恢复、移动、调整 Terminal 窗口，以及发送用户明确配置的文字。

## 使用方法

1. 打开 Termosaic，顶部菜单栏会出现四宫格图标。
2. 勾选 **显示终端画布**，显示并排列所有 Terminal 窗口。
3. 在 Terminal 中按 `⌘N` 新建窗口，或关闭已有窗口，画布会自动更新。
4. 切换到其他应用时，终端画布可以自动隐藏；也可以手动取消勾选 **显示终端画布**。
5. Terminal 窗口隐藏后，其中的命令仍会继续运行。

## 顺时针窗口顺序

窗口顺序不会因为点击或切换焦点而改变。新窗口会追加到顺时针序列末尾；关闭窗口后，剩余窗口保持相对顺序并立即补位。

4 个窗口：

```text
左上 → 右上 → 右下 → 左下
```

6 个窗口：

```text
左上 → 上中 → 右上 → 右下 → 下中 → 左下
```

## 快捷键

全局快捷键：

- `⌘O`：从任何应用呼出并立即重新平铺所有 Terminal 窗口
- 可以改为 `⌥⌘O`、`⇧⌘O` 或 `⌃⌥⌘O`
- 也可以关闭全局快捷键

菜单快捷键：

- `⌥⌘1`：显示或隐藏画布
- `⌥⌘2`：在鼠标所在显示器重新平铺
- `⌥⌘3`：立即发送一次“继续”，不用等到下一次定时

自动“继续”的间隔与范围在自动“继续”子菜单里；**激活 5h 窗口** 会打开一个小时间面板，起始时间可以任意指定。更新仍留在顶层一行。切换到其他应用时隐藏画布、退出时隐藏 Terminal 两项始终开启。

> `⌘O` 通常是 macOS 应用的“打开”命令。如果需要保留该功能，请选择其他全局快捷键。

## 自动“继续”

Termosaic 会定时恢复匹配的 Codex/Claude Terminal 会话，让任务自己跑回来——不管打断它的是什么：额度限制界面、SSH 或网络断开、前台进程崩掉，还是卡在等待输入的提示。

每个符合范围的会话都会收到“继续”。如果会话其实在等确认（`(y/n)`、`yes/no`、`是否继续` 这类提示），Termosaic 会改为回答 `yes`，先把卡住的地方放行。

正在运行的会话会被跳过：尾屏出现活动 spinner 或 `esc to interrupt` 时不会发送，避免在跑着的任务上打字。

默认只作用于标题或进程包含 `Codex`、`Claude` 的会话，普通 Shell 不受影响。

- 默认开启
- 默认检查间隔：30 分钟
- 可选间隔：5、10、15、30、45、60 或 120 分钟
- 可选 **激活 5h 窗口**：起始时间可以任意指定（时分），Termosaic 还会在每个 5 小时窗口开始时恢复一次，例如 05:00，之后 10:00、15:00…
- 安全默认范围：标题或进程包含 `Codex`、`Claude` 的会话
- 可选范围：所有 Terminal 窗口
- `⌥⌘3` 立即发送一次，不用等到下一次定时
- 所有设置都会在重新启动后保留

请谨慎使用“所有 Terminal 窗口”，普通 Shell 可能会把“继续”或 `yes` 当成命令执行。

## 在线自动更新

Termosaic 会在启动后检查最新 GitHub Release，之后每 6 小时检查一次，发现新版本即自动下载安装。菜单里只保留当前版本和 **检查更新** 两项。

所有更新信息和操作都保留在菜单栏内部，不会显示遮挡工作的桌面更新弹窗。

替换应用前，Termosaic 会：

1. 通过 HTTPS 下载带版本号的 DMG 和对应 `.sha256` 文件。
2. 验证 DMG 的 SHA-256。
3. 以只读方式挂载 DMG。
4. 验证 Bundle ID 为 `io.github.zzusec.termosaic`，并验证版本更高且与 Release 一致。
5. 执行递归严格 `codesign` 校验。
6. 启动独立的 Universal 更新助手。
7. 在不隐藏 Terminal 任务的情况下退出 Termosaic，备份旧版本、安装新版本并重新启动。
8. 如果替换或重新启动失败，自动恢复旧版本。

自动安装要求 Termosaic 位于 `/Applications/Termosaic.app`，并且当前用户有权限写入该应用。

> 在线自动更新从 Termosaic 1.2.0 开始提供。更旧版本需要先手动升级一次到 1.2.0 或更高版本。

## 从源码构建

```bash
./build.sh
```

只构建、不安装：

```bash
SKIP_INSTALL=1 ./build.sh
```

## 创建 DMG

```bash
./build.sh
./create-dmg.sh
```

生成的 DMG、zip 压缩包和 SHA-256 文件位于 `dist/`。

## 测试

窗口布局测试：

```bash
swiftc Sources/GridLayout.swift Tests/main.swift -o /tmp/termosaic-grid-tests
/tmp/termosaic-grid-tests
```

语义版本测试：

```bash
swiftc Sources/SemanticVersion.swift Tests/VersionTests.swift -o /tmp/termosaic-version-tests
/tmp/termosaic-version-tests
```

构建完成后测试更新助手：

```bash
Tests/test_update_installer.sh
```

## 系统 Terminal 的限制

Termosaic 不会修改或注入代码到 `Terminal.app`。因此，独立的系统 Terminal 窗口仍然会保留带红、黄、绿按钮的 macOS 标题栏。Termosaic 会移除自己的布局外边距，并让完整窗口边缘紧贴排列。

## 隐私

Termosaic 没有分析统计、账户系统、广告或遥测。网络只用于查询和下载 Termosaic GitHub 仓库中的公开 Release。所有 Terminal 自动化操作都只在本机执行。

## 开源协议

Termosaic 使用 [MIT License](LICENSE) 开源。
