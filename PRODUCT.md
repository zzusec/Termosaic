# Termosaic — Product

<!-- impeccable:product-schema 1 -->

## Platform

Termosaic is a native macOS menu-bar utility.

## Stack

Swift 6, SwiftUI, AppKit, and Apple Events automation. No third-party runtime dependencies.

## Primary User

A macOS user who runs several long-lived processes in Apple's built-in Terminal.app and wants to inspect them together without allowing a global window manager to rearrange unrelated work.

## Core Job

Show every existing Terminal.app shell window as one balanced wall on the current display, then hide the wall without stopping the processes running inside those windows.

## Confirmed Capabilities

- Manage Apple's system Terminal.app only.
- Show, hide, and manually re-tile Terminal windows with edge-to-edge, zero-gap placement.
- Automatically re-tile when a Terminal window is added or closed.
- Restore minimized Terminal windows and include them in the grid.
- Keep Terminal processes running while their windows are hidden.
- Treat Terminal windows as one logical canvas and optionally hide the canvas when another application becomes active.
- Never reposition windows belonging to other applications.
- Remain available only from the macOS menu bar, with no Dock icon or desktop control window.
- Provide a persisted, configurable global shortcut that shows and forcibly re-tiles the complete Terminal mosaic.
- Optionally send “继续” to matching Codex/Claude Terminal sessions on a persisted, configurable retry interval.

## Durable Constraints

- Existing Terminal sessions remain owned by Terminal.app; the utility does not embed or migrate shells.
- Window movement requires permission for Termosaic to automate Apple Terminal.
- Interacting with a tiled terminal naturally makes Terminal.app the active application; the manager remains available from its menu-bar item.
- The utility must not require a third-party window manager or terminal emulator.

## Success

Four Terminal windows form a clean 2×2 wall. Adding or closing a window causes the remaining windows to form a balanced grid automatically. Hiding the wall removes Terminal windows from the workspace while their commands continue running.
