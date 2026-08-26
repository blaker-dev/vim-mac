# vim-mac Project Memory & Context

This file serves as persistent memory and technical context across development sessions for `vim-mac`.

---

## 📌 Project Overview
- **Name**: `vim-mac`
- **Language**: Swift (Swift 6.0 / macOS 13+)
- **Type**: macOS CLI Daemon / Window Manager
- **Core Purpose**: Modal window management using Vim keys (`h/j/k/l`, modes, chords, presets, and colon commands).

---

## 🗺️ Keycode Reference Map (macOS Virtual Keycodes)

| Key | Keycode | Purpose in Move Mode |
| :--- | :--- | :--- |
| `;` / `:` | `41` | Mode switch toggle (`Ctrl + :` / `Ctrl + ;`) |
| `Esc` | `53` | Return to Insert Mode / Cancel command mode |
| `h` | `4` | Move Left / Resize Width- |
| `j` | `38` | Move Down / Resize Height+ |
| `k` | `40` | Move Up / Resize Height- |
| `l` | `37` | Move Right / Resize Width+ |
| `m` | `46` | Maximize window |
| `c` | `8` | Center window |
| `[` | `33` | Throw active window to Left Space |
| `]` | `30` | Throw active window to Right Space |
| `?` | `44` (`Shift + /`) | Display Help menu |
| `:` | `41` (`Shift + ;`) | Enter Command Mode |
| `2` | `19` | 2-window split preset |
| `3` | `20` | 3-window master+stack preset |
| `4` | `21` | 4-window 2x2 grid preset |
| `s` / `x` | `1` / `7` | Swap current window with previous window |
| `Left Arrow` | `123` | Used in synthetic desktop space switching |
| `Right Arrow`| `124` | Used in synthetic desktop space switching |

---

## ⚙️ Technical Constraints & macOS Specifics

1. **Coordinate System Inversion**:
   - `NSScreen` (Cocoa): Origin $(0,0)$ is at the **bottom-left** of the primary screen.
   - `AXUIElement` (Accessibility): Origin $(0,0)$ is at the **top-left** of the primary screen.
   - Usable screen frame must account for menu bar ($y$-offset) and dock ($y$-height or $x$-offset). Always use `screen.visibleFrame`.

2. **Event Tap Interception**:
   - Event tap must be installed at `.headInsertEventTap` in `.cghidEventTap` mode to ensure it catches keys before applications process them.
   - Swallowing keystrokes requires returning `nil` from the `eventCallback`. Returning `Unmanaged.passRetained(event)` allows standard passthrough.

3. **Accessibility Permission Checks**:
   - `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])` prompts the user on startup if permissions are missing.
   - If running inside a terminal emulator (e.g. iTerm, Terminal, Ghostty), the **terminal application itself** must be granted Accessibility permissions.

4. **Multi-Window Tracking across Apps**:
   - `AXUIElement` can only directly access windows for a specific PID.
   - To find the last 2, 3, or 4 active windows across different apps, query `CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)`, then instantiate `AXUIElementCreateApplication(pid)` and extract the relevant `AXUIElement` window handles.

5. **Space Throwing Timing**:
   - macOS desktop transition animation takes ~300ms.
   - Synthetic mouse down must occur on the window title bar, followed by `Ctrl + Arrow`, with a `usleep`/`DispatchQueue` delay of ~350ms before mouse up to prevent dropping the window back on the original space.

---

## 📁 Repository Structure

```
vim-mac/
├── README.md                      # User guide, keybindings, setup
├── ARCHITECTURE.md                # System architecture, APIs, coordinates
├── ROADMAP.md                     # Feature gaps, colon command ideas, milestones
├── PROJECT_MEMORY.md              # Persistent context, keycodes, constraints
├── vim-mac.xcodeproj/             # Xcode project (Synchronized root group)
└── vim-mac/
    ├── main.swift                 # Current single-file implementation
    └── Planning Doc - Vim Mac v0.0.1.pdf # Original specification PDF
```
