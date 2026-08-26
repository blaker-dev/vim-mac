# vim-mac

A lightweight, modal macOS window manager bringing Vim-style keyboard navigation and window orchestration to your desktop with real-time glassmorphic floating overlays.

---

## 🎯 Overview

`vim-mac` runs as a background CLI daemon that intercepts global keyboard events to give you fast, keyboard-driven control over macOS application windows without relying on a mouse or cumbersome modifier combos.

Inspired by Vim's modal editing philosophy, `vim-mac` introduces **Modes** to your desktop:

| Mode | Visual Indicator | Description | How to Enter / Exit |
| :--- | :--- | :--- | :--- |
| **Insert Mode** | *None* | Normal macOS behavior. All keyboard shortcuts and inputs pass through transparently. | Default state; press `Esc` from Move Mode. |
| **Move Mode** | `🟢 Active` *(Bottom-right)* | Modal window control. Keys (`h`, `j`, `k`, `l`, `a`, `f`, `2`, `3`, `4`, etc.) are captured for window operations. | Press `Ctrl + :` (or `Ctrl + ;`). |
| **Command Mode** | *Spotlight Input Bar* | Ex-command line interface (`:vsplit`, `:swap`, `:preset 3`, `:set step=80`, `:q`). | Press `:` while in Move Mode. |

---

## 🍺 Installation via Homebrew

`vim-mac` is packaged as a Homebrew formula with `yabai` as an automated dependency:

### 1. Tap & Install
```bash
# Add the tap
brew tap blaker-dev/vim-mac https://github.com/blaker-dev/vim-mac

# Install vim-mac (automatically installs yabai dependency)
brew install vim-mac
```

### 2. Updating Later
Whenever you push updates to GitHub, you or your users can update effortlessly:
```bash
brew update && brew upgrade vim-mac
```

### 3. Running as a Background Service
```bash
# Start background service
brew services start vim-mac

# Or run directly in your terminal
vim-mac
```

---

## ⌨️ Keybindings Reference

### Motions & Resizing (Move Mode)

| Keybinding | Action |
| :--- | :--- |
| `h` / `j` / `k` / `l` | Move focused window Left / Down / Up / Right (50px) |
| `H` / `J` / `K` / `L` (`Shift + ...`) | Resize focused window width/height (+/- 50px) |
| `Ctrl + motion` *(or `Cmd`)* | Precision / Fine step movement & resizing (10px) |

### Space Navigation & Multi-Window Presets

| Keybinding | Action |
| :--- | :--- |
| `a` / `f` | Throw focused window to **Left / Right Desktop Space** (yabai) |
| `2` | 2-Window **Vertical Split** (50/50) |
| `Option + 2` | 2-Window **Horizontal Split** (50/50) |
| `3` | 3-Window **Master + Stack** (Large left 50%, 2 stacked right) |
| `4` | 4-Window **2x2 Quad Grid** (4 equal corners) |
| `s` / `x` | **Swap** active window position with previous window |
| `m` / `c` | **Maximize** / **Center** active window |
| `Option + h/j/k/l` | Snap to Left / Bottom / Top / Right half |
| `Option + (h, then k)` | Snap to Top-Left corner (Chord within 450ms) |
| `Option + (l, then k)` | Snap to Top-Right corner |
| `Option + (h, then j)` | Snap to Bottom-Left corner |
| `Option + (l, then j)` | Snap to Bottom-Right corner |

### System & Overlays

| Keybinding | Action |
| :--- | :--- |
| `?` | Toggle floating **Help Manual** overlay card |
| `:` | Open **Spotlight-Style Command Bar** |
| `Esc` | Dismiss overlays / Return to **Insert Mode** |
| `Ctrl + Arrow Keys` | Native macOS Space & Mission Control switching (passed through) |

---

## 💻 Colon Commands (`:`)

| Command | Action |
| :--- | :--- |
| `:vsplit` or `:vs` | 2-window vertical 50/50 split |
| `:split` or `:sp` | 2-window horizontal 50/50 split |
| `:swap` or `:sw` | Swap position with previous active window |
| `:preset <2\|2h\|3\|4>` | Apply layout arrangement preset |
| `:max` or `:only` | Maximize focused window |
| `:center` or `:c` | Center focused window (70% size) |
| `:throw <left\|right>` | Throw window to left or right space |
| `:set step=<pixels>` | Configure standard pixel step size (default: 50) |
| `:set finestep=<pixels>` | Configure fine step size (default: 10) |
| `:help` or `:h` | Display keybinding manual |
| `:quit` or `:q` | Quit `vim-mac` daemon |

---

## 🛠️ Local Development & Building from Source

```bash
# Clone the repository
git clone https://github.com/blaker-dev/vim-mac.git
cd vim-mac

# Build using Swift Package Manager
swift build -c release

# Or build & install with Make
make install

# Run locally
./.build/release/vim-mac
```

### Granting Accessibility Permissions

When you first launch `vim-mac`, macOS will request Accessibility permissions:
1. Open **System Settings** > **Privacy & Security** > **Accessibility**.
2. Enable your terminal application (e.g. `Terminal`, `iTerm2`, `Ghostty`, or `Alacritty`) or the `vim-mac` binary.
3. Run `vim-mac`.
