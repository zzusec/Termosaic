<div align="center">
  <img src="Resources/TermosaicIcon-1024.png" width="144" alt="Termosaic icon">
  <h1>Termosaic</h1>
  <p><strong>A native macOS menu-bar canvas for Apple Terminal windows.</strong></p>
  <p>
    <a href="https://github.com/zzusec/Termosaic/actions/workflows/build.yml"><img src="https://github.com/zzusec/Termosaic/actions/workflows/build.yml/badge.svg" alt="Build"></a>
    <img src="https://img.shields.io/badge/macOS-13%2B-black" alt="macOS 13+">
    <img src="https://img.shields.io/badge/Swift-native-orange" alt="Native Swift">
  </p>
  <p><strong>English</strong> · <a href="README.zh-CN.md">简体中文</a></p>
</div>

Termosaic organizes the windows you already have in Apple's built-in `Terminal.app`. It does not replace Terminal, embed a shell, modify Terminal profiles, or rearrange windows from other applications.

## Highlights

- Tiles all Terminal windows into an edge-to-edge grid with no outer margin or inter-window gap.
- Uses a 2×2 layout for four windows and a 3×2 layout for six windows.
- Detects opened or closed windows in about 0.2 seconds and immediately re-tiles the canvas.
- Preserves stable window identity and places windows clockwise.
- Restores minimized Terminal windows before arranging them.
- Treats every Terminal window as one logical canvas that can be shown or hidden together.
- Can automatically hide the canvas when another application becomes active.
- Provides a configurable global show-and-rearrange shortcut; the default is `⌘O`.
- Sends `继续` to Codex/Claude sessions on a timer so any interruption—quota screens, SSH or network drops, or stalled prompts—gets resumed, and answers `yes` when a confirmation prompt is waiting.
- Checks GitHub Releases and can securely download, validate, install, and relaunch updates automatically.
- Runs only in the menu bar—no Dock icon and no permanent desktop control window.
- Ships as a universal Apple Silicon and Intel application.

## Requirements

- macOS 13 or later.
- Automation permission to control Apple Terminal windows.
- Internet access for online update checks.
- Xcode Command Line Tools only when building from source.

## Install

Download the latest installer from [GitHub Releases](https://github.com/zzusec/Termosaic/releases/latest):

1. Open `Termosaic-vX.Y.Z-macOS.dmg`.
2. Drag `Termosaic.app` to the `Applications` shortcut.
3. On first launch, macOS may require **Control-click → Open** because community builds are ad-hoc signed and are not Apple-notarized.

Termosaic is installed at:

```text
/Applications/Termosaic.app
```

## Permissions

On first launch, allow Termosaic to control Terminal:

```text
System Settings → Privacy & Security → Automation → Termosaic → Terminal
```

This permission is used locally to count, restore, move, resize, and send explicitly configured text to Terminal windows.

## Usage

1. Launch Termosaic. A four-tile icon appears in the macOS menu bar.
2. Turn on **显示终端画布** to show and arrange every Terminal window.
3. Open a new Terminal window with `⌘N`, or close an existing window. The layout updates automatically.
4. Switch to another application to hide the Terminal canvas automatically, or turn **显示终端画布** off manually.
5. Hidden Terminal windows and their commands continue running.

## Clockwise window order

Window identity remains stable when focus changes. New windows are appended to the end of the clockwise sequence, while closed windows are removed without shuffling the surviving windows.

Four windows:

```text
Top-left → Top-right → Bottom-right → Bottom-left
```

Six windows:

```text
Top-left → Top-center → Top-right → Bottom-right → Bottom-center → Bottom-left
```

## Keyboard shortcuts

Global shortcut:

- `⌘O` — show and immediately re-tile all Terminal windows from any application
- Alternative choices: `⌥⌘O`, `⇧⌘O`, or `⌃⌥⌘O`
- The global shortcut can also be disabled

Menu shortcuts:

- `⌥⌘1` — show or hide the canvas
- `⌥⌘2` — re-tile on the display under the pointer
- `⌥⌘3` — send `继续` now, without waiting for the next scheduled attempt

Auto-continue interval and target live in the 自动“继续” submenu; **激活 5h 窗口** opens a small time panel where the start time is set by scrolling (5 minutes per notch, ⇧ for whole hours). The update line stays on the top level. Hiding the canvas when another application becomes active, and hiding Terminal on quit, are always on.

> `⌘O` normally means “Open” in macOS applications. Select an alternative if you want to preserve that command.

## Automatic continue

Termosaic periodically resumes matching Codex/Claude Terminal sessions so work recovers on its own, whatever interrupted it: a usage-limit screen, an SSH or network drop, a crashed foreground process, or a prompt waiting for input.

Each eligible session receives `继续`. If the session is waiting on a confirmation instead (`(y/n)`, `yes/no`, `是否继续`, and similar prompts), Termosaic answers `yes` so the block clears.

A session that is still working is left alone: Termosaic skips anything showing a live spinner or an `esc to interrupt` line, so it never types over running work.

By default the target is sessions whose title or process list contains `Codex` or `Claude`, so ordinary shells are left alone.

- Enabled by default
- Default interval: 30 minutes
- Available intervals: 5, 10, 15, 30, 45, 60, or 120 minutes
- Optional **激活 5h 窗口**: set any start time and Termosaic also resumes at the start of every five-hour window from there — 05:00, then 10:00, 15:00…
- Safe default target: sessions whose title or process list contains `Codex` or `Claude`
- Optional target: all Terminal windows
- `⌥⌘3` sends one pass immediately, without waiting for the next scheduled attempt
- Settings persist across launches

Use the “all Terminal windows” target carefully: a normal shell may receive `继续` or `yes` as a command.

## Online automatic updates

Termosaic checks the latest public GitHub Release shortly after launch and every six hours, then downloads and installs it automatically. The menu shows only the current version and a **检查更新** action.

Update interaction remains inside the menu bar; Termosaic does not show an intrusive desktop update modal.

Before replacing the installed app, Termosaic:

1. Downloads the versioned DMG and matching `.sha256` asset over HTTPS.
2. Verifies the DMG SHA-256 checksum.
3. Mounts the DMG read-only.
4. Verifies bundle ID `io.github.zzusec.termosaic` and a newer matching version.
5. Runs strict recursive `codesign` verification.
6. Starts a separate universal update helper.
7. Exits without hiding Terminal tasks, backs up the old app, installs the new version, and relaunches it.
8. Restores the backup if replacement or relaunch fails.

Automatic installation requires Termosaic to be installed at `/Applications/Termosaic.app` and the current user to have write access to that application.

> Online updates are available starting with Termosaic 1.2.0. Older versions require one manual update to 1.2.0 or later.

## Build from source

```bash
./build.sh
```

Build without installing:

```bash
SKIP_INSTALL=1 ./build.sh
```

## Build a DMG

```bash
./build.sh
./create-dmg.sh
```

The DMG, zip archive, and SHA-256 files are written to `dist/`.

## Tests

Grid layout tests:

```bash
swiftc Sources/GridLayout.swift Tests/main.swift -o /tmp/termosaic-grid-tests
/tmp/termosaic-grid-tests
```

Semantic version tests:

```bash
swiftc Sources/SemanticVersion.swift Tests/VersionTests.swift -o /tmp/termosaic-version-tests
/tmp/termosaic-version-tests
```

Update installer test, after building the app:

```bash
Tests/test_update_installer.sh
```

## System Terminal limitation

Termosaic does not modify or inject code into `Terminal.app`. Separate system Terminal windows therefore retain the standard macOS title bar with the red, yellow, and green controls. Termosaic removes its own layout margins and places complete window frames edge to edge.

## Privacy

Termosaic has no analytics, account system, advertising, or telemetry. Network access is used only to query and download public releases from the Termosaic GitHub repository. Terminal automation remains local to the Mac.

## License

Termosaic is released under the [MIT License](LICENSE).
