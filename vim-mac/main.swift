//
//  main.swift
//  vim-mac
//
//  Created by BRobinson (w/ Gemini) on 8/20/26.
//  Refactored & Extended by Antigravity on 8/26/26.
//

import Cocoa
import ApplicationServices

// 1. Accessibility Permissions Check
let promptOptions: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
let isTrusted = AXIsProcessTrustedWithOptions(promptOptions)

if !isTrusted {
    print("\u{001B}[1;31m[vim-mac] Accessibility permissions not granted.\u{001B}[0m")
    print("Please grant Accessibility permissions in System Settings > Privacy & Security > Accessibility.")
    print("Ensure your terminal emulator (e.g. Terminal, iTerm, Ghostty) is enabled.")
    exit(1)
}

// 2. Initialize Application as Silent Accessory (No Dock Icon)
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// 3. Initialize Subsystems & Overlays
_ = WindowHistoryTracker.shared
_ = WindowManager.shared
_ = OverlayManager.shared
EventTapManager.shared.start()

// 4. Display Startup Banner
print("""
\u{001B}[1;32m
      _                             
 ___ (_)__ _ ___ ____ _ ___ _ ____  
/ _/ / //  ' // _ `/ _ `/ _ `/ __/  
\\__/_//_/_/_//\\_,_/\\_,_/\\_,_/\\__/   
                                    
\u{001B}[0m\u{001B}[1m Modal Window Manager for macOS (w/ Floating Overlays)\u{001B}[0m
\u{001B}[36m Version 0.2.0\u{001B}[0m

• \u{001B}[33mCtrl + :\u{001B}[0m Toggle Move Mode (green top-left dot) / Insert Mode
• In Move Mode:
  - \u{001B}[32mh / j / k / l\u{001B}[0m : Move window
  - \u{001B}[32mH / J / K / L\u{001B}[0m : Resize window
  - \u{001B}[32m2 / 3 / 4\u{001B}[0m     : Multi-window presets (splits, master-stack, 2x2 grid)
  - \u{001B}[32ms / x\u{001B}[0m         : Swap with previous window
  - \u{001B}[32m?\u{001B}[0m             : Floating keybinding manual
  - \u{001B}[32m:\u{001B}[0m             : Spotlight-style command bar (:vsplit, :swap, :preset, :q)
  - \u{001B}[32mEsc\u{001B}[0m           : Return to Insert Mode

\u{001B}[32m[vim-mac] Daemon and overlays active and listening.\u{001B}[0m
""")

// 5. Start AppKit Event Loop
app.run()
