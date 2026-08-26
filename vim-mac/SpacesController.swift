//
//  SpacesController.swift
//  vim-mac
//
//  Created by Antigravity on 8/26/26.
//

import Cocoa
import ApplicationServices

public struct SpacesController {
    
    private static var cachedYabaiPath: String?
    
    /// Resolves the absolute path to the `yabai` CLI binary if installed
    public static func findYabaiPath() -> String? {
        if let cached = cachedYabaiPath, FileManager.default.fileExists(atPath: cached) {
            return cached
        }
        
        let possiblePaths = [
            "/opt/homebrew/bin/yabai",
            "/usr/local/bin/yabai",
            "/usr/bin/yabai"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                cachedYabaiPath = path
                return path
            }
        }
        
        return nil
    }
    
    /// Throws the active window to an adjacent space AND switches the desktop view
    public static func throwWindow(window: AXUIElement?, direction: Direction) {
        if let yabaiPath = findYabaiPath() {
            let targetSpace = (direction == .left) ? "prev" : "next"
            
            runYabaiCommand(executable: yabaiPath, arguments: ["-m", "window", "--space", targetSpace, "--focus"]) { success in
                if success {
                    print("\u{001B}[32m[vim-mac] Threw window to Space (\(targetSpace)) via yabai CLI.\u{001B}[0m")
                } else {
                    // yabai daemon not running or socket error -> Fallback to clean Native Drag
                    DispatchQueue.main.async {
                        if let targetWindow = window ?? WindowManager.shared.getActiveWindow() {
                            throwWindowViaNativeDrag(window: targetWindow, direction: direction)
                        }
                    }
                }
            }
        } else {
            // yabai not installed -> Use clean Native Drag
            DispatchQueue.main.async {
                if let targetWindow = window ?? WindowManager.shared.getActiveWindow() {
                    throwWindowViaNativeDrag(window: targetWindow, direction: direction)
                }
            }
        }
    }
    
    private static func runYabaiCommand(executable: String, arguments: [String], completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errStr = String(data: errData, encoding: .utf8) ?? ""
                
                let outData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let outStr = String(data: outData, encoding: .utf8) ?? ""
                
                let combinedOutput = errStr + outStr
                if combinedOutput.contains("failed to connect to socket") || process.terminationStatus != 0 {
                    completion(false)
                } else {
                    completion(true)
                }
            } catch {
                completion(false)
            }
        }
    }
    
    /// Throws the active window to an adjacent space using clean native macOS window dragging
    /// This keeps Dock.app, Mission Control, and 3-finger swipe gestures completely intact and functional.
    public static func throwWindowViaNativeDrag(window: AXUIElement, direction: Direction) {
        guard let frame = WindowManager.shared.getWindowFrame(window: window) else {
            print("\u{001B}[31m[vim-mac] Could not query window frame for space throw.\u{001B}[0m")
            return
        }
        
        let source = CGEventSource(stateID: .hidSystemState)
        let originalMouseLocation = CGEvent(source: nil)?.location ?? .zero
        
        // Grab titlebar point (offset from left edge to avoid close/minimize traffic light buttons)
        let grabX = frame.origin.x + min(180, max(60, frame.width / 2))
        let grabY = frame.origin.y + 12
        let grabPoint = CGPoint(x: grabX, y: grabY)
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Move cursor to titlebar & press Left Mouse Down
            let mouseMove = CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: grabPoint, mouseButton: .left)
            mouseMove?.post(tap: .cghidEventTap)
            usleep(15000) // 15ms
            
            let mouseDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: grabPoint, mouseButton: .left)
            mouseDown?.post(tap: .cghidEventTap)
            usleep(35000) // 35ms grab hold
            
            // 2. Synthesize Ctrl + Left Arrow (123) or Ctrl + Right Arrow (124) to switch Space while holding window
            let arrowKey: CGKeyCode = (direction == .left) ? 123 : 124
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: arrowKey, keyDown: true)
            keyDown?.flags = .maskControl
            keyDown?.post(tap: .cghidEventTap)
            
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: arrowKey, keyDown: false)
            keyUp?.flags = .maskControl
            keyUp?.post(tap: .cghidEventTap)
            
            // 3. Release window on the new Space after macOS slide transition initiates
            usleep(380000) // 380ms transition delay
            let mouseUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: grabPoint, mouseButton: .left)
            mouseUp?.post(tap: .cghidEventTap)
            
            // 4. Restore original cursor position
            if originalMouseLocation != .zero {
                let restoreMove = CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: originalMouseLocation, mouseButton: .left)
                restoreMove?.post(tap: .cghidEventTap)
            }
            
            print("\u{001B}[32m[vim-mac] Successfully threw window to adjacent space.\u{001B}[0m")
        }
    }
}
