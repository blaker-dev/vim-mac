//
//  HelpFormatter.swift
//  vim-mac
//
//  Created by Antigravity on 8/26/26.
//

import Cocoa

public struct HelpFormatter {
    
    public static func printHelp() {
        let helpText = """
        \u{001B}[1;36m╔══════════════════════════════════════════════════════════════════════╗\u{001B}[0m
        \u{001B}[1;36m║                         vim-mac Keybindings                          ║\u{001B}[0m
        \u{001B}[1;36m╚══════════════════════════════════════════════════════════════════════╝\u{001B}[0m
        
        \u{001B}[1mModes:\u{001B}[0m
          \u{001B}[33mCtrl + :\u{001B}[0m          Toggle Move Mode / Insert Mode
          \u{001B}[33mEsc\u{001B}[0m               Return to Insert Mode (or exit Command Mode)
          \u{001B}[33m:\u{001B}[0m                 Enter Command Mode (type :help, :vsplit, etc.)
          \u{001B}[33m?\u{001B}[0m                 Display this help menu
        
        \u{001B}[1mMovement & Resizing:\u{001B}[0m
          \u{001B}[32mh / j / k / l\u{001B}[0m     Move window Left / Down / Up / Right (50px)
          \u{001B}[32mH / J / K / L\u{001B}[0m     Resize window width/height (+/- 50px)
          \u{001B}[32mCtrl + motion\u{001B}[0m     Slow / Fine step movement & resizing (10px)
        
        \u{001B}[1mSnapping & Chords:\u{001B}[0m
          \u{001B}[35mOption + h/j/k/l\u{001B}[0m  Snap to Left / Bottom / Top / Right half
          \u{001B}[35mOption + (h, k)\u{001B}[0m   Snap to Top-Left corner (chord within 450ms)
          \u{001B}[35mOption + (l, k)\u{001B}[0m   Snap to Top-Right corner
          \u{001B}[35mOption + (h, j)\u{001B}[0m   Snap to Bottom-Left corner
          \u{001B}[35mOption + (l, j)\u{001B}[0m   Snap to Bottom-Right corner
          \u{001B}[35mm\u{001B}[0m                 Maximize window to visible screen
          \u{001B}[35mc\u{001B}[0m                 Center window (70% size)
        
        \u{001B}[1mMulti-Window Presets & Swapping:\u{001B}[0m
          \u{001B}[34m2\u{001B}[0m                 Preset: 2 Windows Vertical Split (50/50)
          \u{001B}[34mOption + 2\u{001B}[0m        Preset: 2 Windows Horizontal Split (50/50)
          \u{001B}[34m3\u{001B}[0m                 Preset: 3 Windows (Master Left + 2 Stacked Right)
          \u{001B}[34m4\u{001B}[0m                 Preset: 4 Windows (2x2 Quad Grid)
          \u{001B}[34ma / f\u{001B}[0m             Throw window to Left / Right Space (via yabai CLI)
          \u{001B}[34m[ / ]\u{001B}[0m             Throw window to Left / Right Space
        
        \u{001B}[1mColon Commands (:):\u{001B}[0m
          \u{001B}[36m:vsplit\u{001B}[0m, \u{001B}[36m:vs\u{001B}[0m      2-window vertical split
          \u{001B}[36m:split\u{001B}[0m, \u{001B}[36m:sp\u{001B}[0m       2-window horizontal split
          \u{001B}[36m:swap\u{001B}[0m, \u{001B}[36m:sw\u{001B}[0m        Swap position with previous window
          \u{001B}[36m:preset <2|2h|3|4>\u{001B}[0m Apply layout preset
          \u{001B}[36m:max\u{001B}[0m, \u{001B}[36m:only\u{001B}[0m       Maximize focused window
          \u{001B}[36m:center\u{001B}[0m, \u{001B}[36m:c\u{001B}[0m       Center focused window
          \u{001B}[36m:throw <l|r>\u{001B}[0m      Throw window to left/right space
          \u{001B}[36m:set step=<n>\u{001B}[0m     Configure standard move/resize step (px)
          \u{001B}[36m:set finestep=<n>\u{001B}[0m Configure fine step (px)
          \u{001B}[36m:help\u{001B}[0m, \u{001B}[36m:h\u{001B}[0m         Display this help menu
          \u{001B}[36m:quit\u{001B}[0m, \u{001B}[36m:q\u{001B}[0m         Quit vim-mac daemon
        """
        print(helpText)
    }
}
