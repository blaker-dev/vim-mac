//
//  CommandParser.swift
//  vim-mac
//
//  Created by Antigravity on 8/26/26.
//

import Cocoa

public struct CommandParser {
    
    public static func execute(commandString: String) {
        let trimmed = commandString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let components = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard let command = components.first?.lowercased() else { return }
        let args = Array(components.dropFirst())
        
        let wm = WindowManager.shared
        
        switch command {
        case "vsplit", "vs":
            wm.applyPreset(.splitVertical)
            
        case "split", "sp":
            wm.applyPreset(.splitHorizontal)
            
        case "swap", "sw":
            wm.swapActiveWithPrevious()
            
        case "preset", "p":
            handlePresetCommand(args: args)
            
        case "max", "only":
            wm.snapWindow(to: .maximize)
            print("\u{001B}[32m[vim-mac] Maximized active window.\u{001B}[0m")
            
        case "center", "c":
            wm.snapWindow(to: .center)
            print("\u{001B}[32m[vim-mac] Centered active window.\u{001B}[0m")
            
        case "left":
            wm.snapWindow(to: .leftHalf)
            print("\u{001B}[32m[vim-mac] Snapped to left half.\u{001B}[0m")
            
        case "right":
            wm.snapWindow(to: .rightHalf)
            print("\u{001B}[32m[vim-mac] Snapped to right half.\u{001B}[0m")
            
        case "top":
            wm.snapWindow(to: .topHalf)
            print("\u{001B}[32m[vim-mac] Snapped to top half.\u{001B}[0m")
            
        case "bottom":
            wm.snapWindow(to: .bottomHalf)
            print("\u{001B}[32m[vim-mac] Snapped to bottom half.\u{001B}[0m")
            
        case "throw":
            if let target = args.first?.lowercased(), target == "left" || target == "l" {
                wm.throwToAdjacentSpace(direction: .left)
                print("\u{001B}[32m[vim-mac] Threw window to Left Space.\u{001B}[0m")
            } else if let target = args.first?.lowercased(), target == "right" || target == "r" {
                wm.throwToAdjacentSpace(direction: .right)
                print("\u{001B}[32m[vim-mac] Threw window to Right Space.\u{001B}[0m")
            } else {
                print("\u{001B}[31m[vim-mac] Usage: :throw <left|right>\u{001B}[0m")
            }
            
        case "set":
            handleSetCommand(args: args)
            
        case "help", "h":
            HelpFormatter.printHelp()
            
        case "quit", "q", "exit":
            print("\u{001B}[33m[vim-mac] Terminating vim-mac daemon. Goodbye!\u{001B}[0m")
            exit(0)
            
        default:
            print("\u{001B}[31m[vim-mac] Unknown command ':\(trimmed)'. Type :help for commands.\u{001B}[0m")
        }
    }
    
    private static func handlePresetCommand(args: [String]) {
        guard let choice = args.first?.lowercased() else {
            print("\u{001B}[31m[vim-mac] Usage: :preset <2|2h|3|4>\u{001B}[0m")
            return
        }
        
        switch choice {
        case "2", "vertical", "vert", "v":
            WindowManager.shared.applyPreset(.splitVertical)
        case "2h", "horizontal", "horiz", "h":
            WindowManager.shared.applyPreset(.splitHorizontal)
        case "3":
            WindowManager.shared.applyPreset(.masterStack3)
        case "4":
            WindowManager.shared.applyPreset(.grid4)
        default:
            print("\u{001B}[31m[vim-mac] Unknown preset '\(choice)'. Available: 2, 2h, 3, 4\u{001B}[0m")
        }
    }
    
    private static func handleSetCommand(args: [String]) {
        guard let pair = args.first else {
            print("\u{001B}[31m[vim-mac] Usage: :set <option>=<value>\u{001B}[0m")
            return
        }
        
        let split = pair.components(separatedBy: "=")
        guard split.count == 2 else {
            print("\u{001B}[31m[vim-mac] Invalid set syntax. Example: :set step=75\u{001B}[0m")
            return
        }
        
        let key = split[0].lowercased().trimmingCharacters(in: .whitespaces)
        let valueStr = split[1].trimmingCharacters(in: .whitespaces)
        
        if key == "step", let val = Double(valueStr) {
            Config.shared.standardStep = CGFloat(val)
            print("\u{001B}[32m[vim-mac] standardStep set to \(val)px\u{001B}[0m")
        } else if key == "finestep" || key == "fine_step", let val = Double(valueStr) {
            Config.shared.fineStep = CGFloat(val)
            print("\u{001B}[32m[vim-mac] fineStep set to \(val)px\u{001B}[0m")
        } else if key == "chord", let val = Double(valueStr) {
            Config.shared.chordThreshold = TimeInterval(val)
            print("\u{001B}[32m[vim-mac] chordThreshold set to \(val)s\u{001B}[0m")
        } else {
            print("\u{001B}[31m[vim-mac] Unknown configuration option '\(key)'\u{001B}[0m")
        }
    }
}
