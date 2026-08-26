# vim-mac Architecture Guide

This document describes the architectural design, subsystem interactions, and low-level macOS APIs utilized in `vim-mac`.

---

## 🏗️ System Overview

`vim-mac` operates as a lightweight daemon running on the macOS Core Foundation RunLoop. It bridges low-level Quartz Event Services (`CGEventTap`) with the macOS Accessibility Framework (`AXUIElement`) to deliver high-performance, modal window management.

```
┌─────────────────────────────────────────────────────────────┐
│                    macOS HID Event Stream                   │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │     CGEventTap      │ (Captures keyDown events)
                    └──────────┬──────────┘
                               │
                ┌──────────────┴──────────────┐
                ▼                             ▼
        [ Insert Mode ]               [ Move Mode ]
        (Passes events)               (Consumes events)
                                              │
                      ┌───────────────────────┼───────────────────────┐
                      ▼                       ▼                       ▼
            ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
            │ Window Motions   │    │  Layout Engine   │    │ Command Mode (:) │
            │ (Move / Resize)  │    │ (Presets / Swap) │    │ (REPL / Parser)  │
            └─────────┬────────┘    └────────┬─────────┘    └────────┬─────────┘
                      │                      │                       │
                      └──────────────────────┼───────────────────────┘
                                             ▼
                               ┌───────────────────────────┐
                               │     AXUIElement APIs      │
                               │  (Position, Size, Focus)  │
                               └─────────────┬─────────────┘
                                             │
                                             ▼
                               ┌───────────────────────────┐
                               │   Target Window Frames    │
                               └───────────────────────────┘
```

---

## 🧩 Core Subsystems

### 1. Event Interception & Mode Manager (`EventTapManager`)
- **API**: `CGEvent.tapCreate(tap: .cghidEventTap, place: .headInsertEventTap, ...)`
- **Behavior**:
  - In **Insert Mode**, events return `Unmanaged.passRetained(event)` to allow normal typing.
  - When `Ctrl + :` (Keycode 41) is intercepted, the state machine switches to **Move Mode**.
  - In **Move Mode**, keystrokes (`h`, `j`, `k`, `l`, `H`, `J`, `K`, `L`, etc.) are mapped to actions and return `nil`, blocking them from reaching foreground applications.
  - Pressing `Esc` (Keycode 53) resets the state machine back to **Insert Mode**.

### 2. Accessibility Window Controller (`WindowManager`)
- **APIs**:
  - `NSWorkspace.shared.frontmostApplication`
  - `AXUIElementCreateApplication(pid)`
  - `AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute, ...)`
  - `AXUIElementSetAttributeValue(windowRef, kAXPositionAttribute, ...)`
  - `AXUIElementSetAttributeValue(windowRef, kAXSizeAttribute, ...)`
- **Coordinate Space Translation**:
  - macOS `NSScreen.frame` uses a **bottom-left origin** (Cocoa coordinates).
  - Accessibility API (`kAXPositionAttribute`) uses a **top-left origin** based on the primary screen.
  - Conversion formula:
    $$\text{axY} = \text{primaryScreenHeight} - (\text{screen.visibleFrame.origin.y} + \text{screen.visibleFrame.height})$$

### 3. Window History & MRU Tracker (`WindowHistoryTracker`)
- **Purpose**: Tracks the most recently active application windows to support multi-window preset layouts and window swapping.
- **Mechanisms**:
  1. Subscribes to `NSWorkspace.didActivateApplicationNotification`.
  2. Queries `CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)` to obtain z-order sorted list of visible window IDs.
  3. Maintains an MRU (Most Recently Used) list of `AXUIElement` handles for the top 4 active application windows.

### 4. Layout Engine (`LayoutEngine`)
Calculates target bounding boxes based on the current screen's `visibleFrame` (excluding menu bar and dock):

- **2-Window Split**:
  - Left / Right: $W / 2$, full usable height.
  - Top / Bottom (Option modifier): $H / 2$, full usable width.
- **3-Window Master & Stack**:
  - Master (Left): $(X, Y, W/2, H)$
  - Stack Top (Right-Top): $(X + W/2, Y, W/2, H/2)$
  - Stack Bottom (Right-Bottom): $(X + W/2, Y + H/2, W/2, H/2)$
- **4-Window 2x2 Grid**:
  - Top-Left: $(X, Y, W/2, H/2)$
  - Top-Right: $(X + W/2, Y, W/2, H/2)$
  - Bottom-Left: $(X, Y + H/2, W/2, H/2)$
  - Bottom-Right: $(X + W/2, Y + H/2, W/2, H/2)$

### 5. Spaces / Virtual Desktop Controller (`SpacesController`)
- **API**: Synthetic mouse & keyboard events (`CGEvent(mouseType: .leftMouseDown, ...)` + `flags = .maskControl` with Arrow keycodes).
- **Mechanism**:
  1. Simulates grabbing the active window's title bar (30ms hold).
  2. Synthesizes `Ctrl + LeftArrow` (Keycode 123) or `Ctrl + RightArrow` (Keycode 124).
  3. Dispatches delayed release (350ms) after macOS completes the desktop slide animation.

### 6. Command Mode (`:`) & Command Engine
- When `:` is pressed in Move Mode, `vim-mac` enters interactive string input mode or triggers a CLI sub-command execution loop.
- Parses command tokens and arguments: e.g., `:preset 3`, `:swap`, `:split`, `:help`, `:q`.

---

## 🔒 Permissions & Security Requirements

1. **Accessibility (`AXIsProcessTrusted`)**: Required to query and alter window attributes (`kAXPositionAttribute`, `kAXSizeAttribute`).
2. **Event Tap Privileges**: `CGEvent.tapCreate` requires process elevation (or terminal approval in Accessibility settings) to intercept global keystrokes.
3. **Hardened Runtime & Entitlements**: If packaged as a signed `.app`, requires accessibility entitlements and disable sandbox for global window orchestration.
