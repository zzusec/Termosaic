<div align="center">
  <img src="Resources/TermosaicIcon-1024.png" width="144" alt="Termosaic icon">
  <h1>Termosaic</h1>
  <p><strong>A focused macOS menu-bar utility that turns Apple Terminal windows into a live, balanced mosaic.</strong></p>
  <p><a href="https://github.com/zzusec/Termosaic/actions/workflows/build.yml"><img src="https://github.com/zzusec/Termosaic/actions/workflows/build.yml/badge.svg" alt="Build"></a> <img src="https://img.shields.io/badge/macOS-13%2B-black" alt="macOS 13+"></p>
</div>

Termosaic manages the windows you already have in Apple's built-in `Terminal.app`. It does not replace your terminal, embed shells, or rearrange windows from other apps.

## Features

- Tiles all existing Terminal windows into a balanced, edge-to-edge grid with no outer margin or inter-window gap.
- Uses an exact 2×2 layout for four windows and a 3×2 layout for six windows.
- Restores minimized Terminal windows before including them in the grid.
- Detects opened or closed Terminal windows in about 0.2 seconds and immediately re-tiles the remaining canvas.
- Preserves stable window IDs and assigns positions clockwise; new windows append to the end of the clockwise sequence.
- Hides every Terminal window without stopping the commands running inside.
- Lives only in the macOS menu bar—no Dock icon and no desktop control window.
- Treats all Terminal windows as one logical canvas and can hide that canvas automatically when another app becomes active.
- Provides a configurable global show-and-rearrange shortcut; the default is `⌘O`.
- Can conditionally send `继续` to quota-blocked Codex/Claude Terminal sessions on a configurable retry interval (30 minutes by default), and stops typing once the limit screen disappears.
- Checks GitHub Releases online and can download, verify, install, and relaunch updates automatically.
- Re-tiles onto the display currently under the pointer.
- Uses only native Swift, SwiftUI, AppKit, and Apple Events automation.
- Ships as a universal Apple Silicon + Intel app.

## Requirements

- macOS 13 or later.
- Automation permission to control Apple Terminal windows.
- Xcode Command Line Tools when building from source.

## Install

Download the latest **DMG** from GitHub Releases, open it, and drag `Termosaic.app` to the `Applications` shortcut. A zip archive is also provided. Because community builds are ad-hoc signed rather than Apple-notarized, macOS may require the first launch through **Control-click → Open**.

## Online updates

Termosaic checks the latest public GitHub Release shortly after launch and every six hours. Automatic checking and automatic installation are enabled by default and can be changed from the menu. Update availability and actions stay inside a compact menu-bar submenu; Termosaic does not show an intrusive desktop update modal.

Before replacing the installed app, the updater:

1. Downloads the versioned DMG and matching `.sha256` asset over HTTPS.
2. Verifies the DMG SHA-256 checksum.
3. Mounts the DMG read-only.
4. Verifies the staged app uses bundle ID `io.github.zzusec.termosaic` and a newer matching version.
5. Runs strict recursive `codesign` verification.
6. Starts a separate universal update helper, exits Termosaic without hiding Terminal windows, backs up the current app, installs the new copy, and relaunches it.
7. Restores the backup if replacement or launch fails.

The automatic installer requires Termosaic to be installed at `/Applications/Termosaic.app` and the current user to have write access to that application. This community build remains ad-hoc signed and is not Apple-notarized.

## Build from source

```bash
./build.sh
```

The app is installed at:

```text
/Applications/Termosaic.app
```

On first launch, allow **Termosaic** to control **Terminal**. You can review this permission under:

```text
System Settings → Privacy & Security → Automation → Termosaic → Terminal
```

## Usage

1. Launch Termosaic. A four-tile icon appears in the menu bar.
2. Choose **显示并平铺** to reveal and tile all Terminal windows.
3. Open a Terminal window with `⌘N`, or close one. The grid updates automatically.
4. Switch to another application to hide the Terminal canvas automatically, or choose **隐藏终端** manually. Terminal processes continue running.

Global shortcut:

- `⌘O` — show and immediately re-tile every Terminal window from any application (default)
- Change it from the menu to `⌥⌘O`, `⇧⌘O`, or `⌃⌥⌘O`, or disable it

Menu shortcuts:

- `⌥⌘1` — show and tile
- `⌥⌘2` — hide Terminal
- `⌥⌘3` — re-tile on the display under the pointer

> `⌘O` normally means “Open” in macOS apps. Choose one of the alternative global shortcuts if you want to preserve that command.

## Automatic continue

Termosaic periodically checks the current screen of matching Terminal windows. It sends `继续` only while a recognized quota/rate-limit message is currently visible. Once Codex replies, starts working, or returns to its normal input prompt and the limit screen disappears, Termosaic stops typing. It is enabled by default at a 30-minute check interval.

- Intervals: 5, 10, 15, 30, 45, 60, or 120 minutes
- Safe default target: windows whose title or process list contains `Codex` or `Claude`
- Optional target: every Terminal window
- Manual **立即发送一次“继续”** action that bypasses quota-screen detection
- Settings persist across launches

Use the “all Terminal windows” target carefully: normal shell sessions may receive `继续` as a command.

## 中文说明

Termosaic 是一个只驻留在 macOS 顶部菜单栏的系统终端窗口管理工具。它会平铺现有的 `Terminal.app` 窗口；新增或关闭窗口后自动重排；隐藏窗口时不会停止正在运行的命令。它不会管理其他应用的窗口。

## Build a DMG

```bash
./build.sh
./create-dmg.sh
```

The DMG and its SHA-256 checksum are written to `dist/`.

## Tests

```bash
swiftc Sources/GridLayout.swift Tests/main.swift -o /tmp/termosaic-grid-tests
/tmp/termosaic-grid-tests
```

## System Terminal limitation

Termosaic does not modify Terminal profiles or default window-creation settings. Separate system Terminal windows retain the macOS title bar with the red, yellow, and green controls because that window chrome is owned by `Terminal.app`. Termosaic removes its own layout margins and places window frames edge to edge, but it does not inject code into or patch the system Terminal application.

## Privacy

Termosaic has no analytics, networking, account system, or data collection. Apple Events automation is used locally only to count, restore, move, resize, and send explicitly configured retry text to Apple Terminal windows.

## License

MIT License. See [LICENSE](LICENSE).
