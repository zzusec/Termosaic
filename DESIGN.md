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

- The main action is one toggle, “显示终端画布”, and its state is the canvas state.
- “重新排列” uses the display under the pointer; an enabled canvas preference hides the complete Terminal group when another application becomes active.
- The top level stays short and stays about the core job: canvas toggle, re-tile, and the global shortcut. Auto-continue and canvas preferences each get one named submenu of their own; update state is one quiet line plus one action.
- Automation permission failures explain both the problem and the exact recovery path in System Settings.
- The menu-bar control is the sole interface and holds every action, quota-aware retry status, and online-update state.
