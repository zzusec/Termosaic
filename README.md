<div align="center">
  <img src="Resources/TermosaicIcon-1024.png" width="144" alt="Termosaic icon">
  <h1>Termosaic</h1>
  <p><strong>A focused macOS menu-bar utility that turns Apple Terminal windows into a live, balanced mosaic.</strong></p>
  <p><a href="https://github.com/zzusec/Termosaic/actions/workflows/build.yml"><img src="https://github.com/zzusec/Termosaic/actions/workflows/build.yml/badge.svg" alt="Build"></a> <img src="https://img.shields.io/badge/macOS-13%2B-black" alt="macOS 13+"></p>
</div>

Termosaic manages the windows you already have in Apple's built-in `Terminal.app`. It does not replace your terminal, embed shells, or rearrange windows from other apps.

## Features

- Tiles all existing Terminal windows into a balanced grid.
- Uses an exact 2×2 layout for four windows.
- Automatically re-tiles when a Terminal window is opened or closed.
- Hides every Terminal window without stopping the commands running inside.
- Lives only in the macOS menu bar—no Dock icon and no desktop control window.
- Re-tiles onto the display currently under the pointer.
- Uses only native Swift, SwiftUI, AppKit, and Accessibility APIs.
- Ships as a universal Apple Silicon + Intel app.

## Requirements

- macOS 13 or later.
- Accessibility permission, used only to read and move Terminal windows.
- Xcode Command Line Tools when building from source.

## Install

Download the latest **DMG** from GitHub Releases, open it, and drag `Termosaic.app` to the `Applications` shortcut. A zip archive is also provided. Because community builds are ad-hoc signed rather than Apple-notarized, macOS may require the first launch through **Control-click → Open**.

## Build from source

```bash
./build.sh
```

The app is installed at:

```text
/Applications/Termosaic.app
```

On first launch, enable **Termosaic** under:

```text
System Settings → Privacy & Security → Accessibility
```

## Usage

1. Launch Termosaic. A four-tile icon appears in the menu bar.
2. Choose **显示并平铺** to reveal and tile all Terminal windows.
3. Open a Terminal window with `⌘N`, or close one. The grid updates automatically.
4. Choose **隐藏终端** to clear the workspace while terminal processes continue running.

Keyboard shortcuts while the Termosaic menu is open:

- `⌥⌘1` — show and tile
- `⌥⌘2` — hide Terminal
- `⌥⌘3` — re-tile on the display under the pointer

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

## Privacy

Termosaic has no analytics, networking, account system, or data collection. Accessibility access is used locally to read, move, resize, minimize, and reveal Apple Terminal windows.

## License

MIT License. See [LICENSE](LICENSE).
