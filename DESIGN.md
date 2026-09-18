# Termosaic — Design

<!-- impeccable:design-schema 1 -->

## Direction

A quiet, menu-bar-only macOS utility. It must remain available without creating a desktop window or Dock presence that competes with the terminal wall.

## Visual System

- Use macOS semantic colors so light mode, dark mode, contrast settings, and accent color work automatically.
- Use SF Symbols for all icons.
- Use standard bordered and bordered-prominent controls with clear text labels.
- Reserve green for an actively displayed terminal wall, amber for hidden/idle state, and red only for actionable errors.
- Use the standard compact menu-bar menu; do not create a desktop control window.
- Use system typography with monospaced digits only for the live window count.

## Interaction

- The main action is always “显示并平铺”.
- “隐藏终端” is explicit, while an enabled canvas preference hides the complete Terminal group when another application becomes active.
- “重新排列” uses the display under the pointer.
- Automation permission failures explain both the problem and the exact recovery path in System Settings.
- The menu-bar control is the sole interface and contains every action, status, and global-shortcut choice.
