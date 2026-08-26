//
//  EventTapManager.swift
//  vim-mac
//
//  Created by Antigravity on 8/26/26.
//

import Cocoa
import ApplicationServices

public class EventTapManager {
    public static let shared = EventTapManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var commandBuffer: String = ""
    
    private init() {}
    
    public func start() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("\u{001B}[31m[vim-mac] Failed to create event tap. Ensure your terminal app has Accessibility permissions in System Settings.\u{001B}[0m")
            exit(1)
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    public func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passRetained(event) }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let wm = WindowManager.shared
        
        // Mode toggle: Ctrl + : / Ctrl + ; (Keycode 41)
        if flags.contains(.maskControl) && keyCode == 41 {
            if wm.currentMode == .insert {
                wm.currentMode = .move
                OverlayManager.shared.setMode(.move)
                print("\n\u{001B}[1;32m[vim-mac: MOVE MODE]\u{001B}[0m (Press ? for help, : for commands, Esc for Insert)")
            } else {
                wm.currentMode = .insert
                OverlayManager.shared.setMode(.insert)
                print("\n\u{001B}[1;33m[vim-mac: INSERT MODE]\u{001B}[0m")
            }
            return nil
        }
        
        switch wm.currentMode {
        case .insert:
            return Unmanaged.passRetained(event)
            
        case .command:
            return handleCommandModeInput(event: event, keyCode: keyCode)
            
        case .move:
            return handleMoveModeInput(event: event, keyCode: keyCode, flags: flags)
        }
    }
    
    // MARK: - Command Mode Input Handling
    
    private func handleCommandModeInput(event: CGEvent, keyCode: Int64) -> Unmanaged<CGEvent>? {
        let wm = WindowManager.shared
        
        if keyCode == 53 { // Escape -> Cancel command mode
            commandBuffer = ""
            wm.currentMode = .move
            OverlayManager.shared.setMode(.move)
            print("\n\u{001B}[1;32m[vim-mac: MOVE MODE]\u{001B}[0m")
            return nil
        }
        
        if keyCode == 36 { // Return / Enter -> Execute command
            print("")
            let cmd = commandBuffer
            commandBuffer = ""
            wm.currentMode = .move
            OverlayManager.shared.setMode(.move)
            CommandParser.execute(commandString: cmd)
            return nil
        }
        
        if keyCode == 51 { // Backspace / Delete
            if !commandBuffer.isEmpty {
                commandBuffer.removeLast()
            }
            OverlayManager.shared.updateCommandText(commandBuffer)
            printPrompt()
            return nil
        }
        
        // Extract readable characters from NSEvent
        if let nsEvent = NSEvent(cgEvent: event), let chars = nsEvent.characters, !chars.isEmpty {
            let filtered = chars.filter { !$0.isNewline && !$0.isWhitespace || $0 == " " }
            commandBuffer.append(filtered)
            OverlayManager.shared.updateCommandText(commandBuffer)
            printPrompt()
        }
        
        return nil
    }
    
    private func printPrompt() {
        print("\r\u{001B}[2K\u{001B}[1;36m:\(commandBuffer)\u{001B}[0m", terminator: "")
        fflush(stdout)
    }
    
    // MARK: - Move Mode Input Handling
    
    private func handleMoveModeInput(event: CGEvent, keyCode: Int64, flags: CGEventFlags) -> Unmanaged<CGEvent>? {
        let wm = WindowManager.shared
        
        // 1. Allow macOS native Ctrl + Arrow keys for Desktop/Space switching & Mission Control
        let isCtrl = flags.contains(.maskControl)
        if isCtrl && [123, 124, 125, 126].contains(keyCode) {
            return Unmanaged.passRetained(event)
        }
        
        // 2. Escape handling: If Help menu is visible, dismiss help ONLY; otherwise return to Insert mode
        if keyCode == 53 {
            if OverlayManager.shared.isHelpVisible {
                OverlayManager.shared.hideHelpOverlay()
            } else {
                wm.currentMode = .insert
                OverlayManager.shared.setMode(.insert)
                print("\n\u{001B}[1;33m[vim-mac: INSERT MODE]\u{001B}[0m")
            }
            return nil
        }
        
        let isShift = flags.contains(.maskShift)
        let isOption = flags.contains(.maskAlternate)
        let isSlow = flags.contains(.maskControl) || flags.contains(.maskCommand)
        
        let step = isSlow ? Config.shared.fineStep : Config.shared.standardStep
        
        // Colon (:) -> Enter Command Mode (Keycode 41 with Shift)
        if keyCode == 41 && isShift {
            wm.currentMode = .command
            commandBuffer = ""
            OverlayManager.shared.setMode(.command)
            printPrompt()
            return nil
        }
        
        // Help (?) -> Keycode 44 with Shift
        if keyCode == 44 && isShift {
            OverlayManager.shared.toggleHelpOverlay()
            HelpFormatter.printHelp()
            return nil
        }
        
        switch keyCode {
        // a (Keycode 0) -> Throw active window to Left Space via SkyLight CGS API
        case 0:
            wm.throwToAdjacentSpace(direction: .left)
            return nil
            
        // f (Keycode 3) -> Throw active window to Right Space via SkyLight CGS API
        case 3:
            wm.throwToAdjacentSpace(direction: .right)
            return nil
            
        // [ (Keycode 33) -> Throw window to Left Space
        case 33:
            wm.throwToAdjacentSpace(direction: .left)
            return nil
            
        // ] (Keycode 30) -> Throw window to Right Space
        case 30:
            wm.throwToAdjacentSpace(direction: .right)
            return nil
            
        // 2 (Keycode 19) -> 2-window preset (Vertical or Horizontal with Option)
        case 19:
            if isOption {
                wm.applyPreset(.splitHorizontal)
            } else {
                wm.applyPreset(.splitVertical)
            }
            return nil
            
        // 3 (Keycode 20) -> 3-window preset (Master + Stack)
        case 20:
            wm.applyPreset(.masterStack3)
            return nil
            
        // 4 (Keycode 21) -> 4-window preset (2x2 Quad Grid)
        case 21:
            wm.applyPreset(.grid4)
            return nil
            
        // s (Keycode 1) or x (Keycode 7) -> Swap active window with previous window
        case 1, 7:
            wm.swapActiveWithPrevious()
            return nil
            
        // Maximize (m: Keycode 46) & Center (c: Keycode 8)
        case 46:
            wm.snapWindow(to: .maximize)
            return nil
        case 8:
            wm.snapWindow(to: .center)
            return nil
            
        // H (Left: Keycode 4)
        case 4:
            if isOption {
                wm.handleSnapChord(direction: .left)
            } else if isShift {
                wm.resizeWindow(dw: -step, dh: 0)
            } else {
                wm.moveWindow(dx: -step, dy: 0)
            }
            return nil
            
        // J (Down: Keycode 38)
        case 38:
            if isOption {
                wm.handleSnapChord(direction: .down)
            } else if isShift {
                wm.resizeWindow(dw: 0, dh: step)
            } else {
                wm.moveWindow(dx: 0, dy: step)
            }
            return nil
            
        // K (Up: Keycode 40)
        case 40:
            if isOption {
                wm.handleSnapChord(direction: .up)
            } else if isShift {
                wm.resizeWindow(dw: 0, dh: -step)
            } else {
                wm.moveWindow(dx: 0, dy: -step)
            }
            return nil
            
        // L (Right: Keycode 37)
        case 37:
            if isOption {
                wm.handleSnapChord(direction: .right)
            } else if isShift {
                wm.resizeWindow(dw: step, dh: 0)
            } else {
                wm.moveWindow(dx: step, dy: 0)
            }
            return nil
            
        default:
            // In Move Mode, swallow unmapped keys to avoid typing into the active window
            return nil
        }
    }
}

// C-convention event callback function for CGEventTap
private func eventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passRetained(event) }
    let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
    return manager.handleEvent(proxy: proxy, type: type, event: event)
}
