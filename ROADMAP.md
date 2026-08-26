# vim-mac Development Roadmap & Next Steps

This document outlines the implementation plan, feature gap analysis compared to the planning document, and recommended next steps.

---

## 📊 Feature Gap Analysis (Planning Doc vs Current Code)

| Feature | Planning Doc Spec | Current Status | Priority |
| :--- | :--- | :--- | :--- |
| **Move Mode / Insert Mode** | Toggle with `ctrl-:`; swallow keys in Move mode | ✅ Working (`Ctrl+:` / `Ctrl+;` / `Esc`) | Complete |
| **Window Movement** | `h`, `j`, `k`, `l` (left, down, up, right) | ✅ Implemented (50px steps) | Complete |
| **Window Resizing** | `H`, `J`, `K`, `L` (Shift + vim keys) | ✅ Implemented (50px steps) | Complete |
| **Slow/Precision Movement** | Press `Ctrl` to slow down movement & resize | ✅ Implemented (`Ctrl` / `Cmd` 10px fine steps) | Complete |
| **Preset Layout: 3 Windows** | Big left (master), small top right, small bottom right | ✅ Implemented (`3` or `:preset 3`) | Complete |
| **Preset Layout: 4 Windows** | 4 Corners (2x2 grid) | ✅ Implemented (`4` or `:preset 4`) | Complete |
| **Preset Layout: 2 Windows** | Vertical split screen (Horizontal if `$OPTION_KEY`) | ✅ Implemented (`2`, `Option+2`, `:vsplit`, `:split`) | Complete |
| **Window Swap** | Swap position of current window with last used window | ✅ Implemented (`s` / `x` or `:swap`) | Complete |
| **Help Menu (`?`)** | Display keybindings cheatsheet | ✅ Implemented (`?` or `:help`) | Complete |
| **Colon Commands (`:`)** | Ex-style command line interface (`:split`, `:swap`, `:q`, etc.) | ✅ Implemented (Interactive prompt & parser) | Complete |
| **Modular Code Architecture** | Clean separation of files instead of monolithic `main.swift` | ✅ Modular architecture in `vim-mac/` | Complete |
| **Visual HUD / Status Bar** | Visual indicator for mode status | ⏳ Next milestone | Future |

---

## 🎯 Proposed Colon (`:`) Commands

As requested in the planning doc ("Give me some ideas ;)"), here is a comprehensive set of proposed colon commands:

### 1. Window & Layout Commands
- `:split` or `:sp` - Split screen horizontally with the last active window.
- `:vsplit` or `:vs` - Split screen vertically (50/50) with the last active window.
- `:swap` or `:sw` - Swap frame and size between the active window and previous window.
- `:preset <2|2h|3|4>` or `:layout <name>` - Apply preset arrangements directly:
  - `:preset 2` - 50/50 vertical split
  - `:preset 2h` - 50/50 horizontal split
  - `:preset 3` - Master left + 2 stacked right
  - `:preset 4` - 2x2 four corner grid
- `:only` or `:max` - Maximize current window to fill usable screen area.
- `:center` or `:c` - Center window at 70% width & height.
- `:grid <cols> <rows>` - Dynamic layout grid (e.g. `:grid 3 1` for three equal columns).

### 2. Multi-Monitor & Spaces Commands
- `:throw <left|right>` or `:throw <1-9>` - Throw window to adjacent space or specific desktop space.
- `:display <next|prev|1|2>` - Move active window to next/previous physical monitor.

### 3. Application & Focus Commands
- `:focus <app_name>` or `:f <app>` - Switch focus directly to an application (e.g. `:focus Ghostty`, `:focus Chrome`).
- `:close` or `:wclose` - Gracefully close focused window.
- `:minimize` or `:m` - Minimize focused window.

### 4. Configuration & System Commands
- `:set step=<n>` - Set standard pixel step size (default: 50).
- `:set finestep=<n>` - Set fine pixel step size (default: 10).
- `:reload` or `:r` - Reload configuration file (`~/.vim-macrc`).
- `:help` or `:h` - Open keybinding cheatsheet and command reference.
- `:quit` or `:q` - Safely terminate the `vim-mac` daemon.

---

## 🛣️ Implementation Phases

### 🔹 Phase 1: Architecture Refactoring & Code Modularization
- Split `main.swift` into modular Swift components:
  - `Models/Mode.swift`, `Models/Direction.swift`, `Models/LayoutPreset.swift`
  - `Core/WindowManager.swift` (AXUIElement interactions, window moving & resizing)
  - `Core/EventTapManager.swift` (CGEventTap creation, key event routing)
  - `Core/WindowHistoryTracker.swift` (MRU tracking of active windows)
  - `Core/SpacesController.swift` (Synthetic space throwing)
  - `Layouts/LayoutEngine.swift` (Arrangement algorithms for 2, 3, and 4 windows)
  - `Commands/CommandParser.swift` (Colon command parsing and execution)
  - `UI/HelpOverlay.swift` (Terminal/CLI help display)
- Update modifier key handling: Ensure `Ctrl` accurately triggers `fineStep` (as specified in planning doc).

### 🔹 Phase 2: Window History Tracking & Multi-Window Presets
- Implement `WindowHistoryTracker`:
  - Query visible windows using `CGWindowListCopyWindowInfo`.
  - Filter out desktop elements, dock, menu bar, and hidden/off-screen windows.
  - Maintain a rolling list of the top 4 MRU window references.
- Implement Preset Layouts:
  - **3-Window Layout** (`big left, small top right, small bottom right`).
  - **4-Window Layout** (`2x2 corners`).
  - **2-Window Layout** (`vertical split`, with `Option` for `horizontal split`).
- Implement Window Swapping:
  - Atomic exchange of position and size between the active window and `history[1]`.
- Map hotkeys in Move Mode:
  - `3` -> Apply 3-window layout
  - `4` -> Apply 4-window layout
  - `2` -> Apply 2-window vertical layout (`Option + 2` -> Horizontal)
  - `s` or `x` -> Swap window positions

### 🔹 Phase 3: Colon (`:`) Command Mode & Interactive Help
- Implement command line buffer state in `EventTapManager`:
  - Triggered by `:` in Move Mode.
  - Intercepts alphanumeric keys and backspace, echoing to stdout or an overlay.
  - Pressing `Enter` executes the command through `CommandParser`.
  - Pressing `Esc` cancels command entry.
- Implement Help Menu (`?`):
  - Formatted terminal table / HUD displaying all bindings and colon commands.

### 🔹 Phase 4: User Experience Polish & Configuration
- Mode Status Indicator:
  - Terminal status line updates or optional lightweight floating HUD overlay / menu bar icon.
- Configuration File Support (`~/.vim-macrc` or `~/.config/vim-mac/config.json`):
  - Custom step sizes, custom hotkeys, app exclusions/floating apps.
