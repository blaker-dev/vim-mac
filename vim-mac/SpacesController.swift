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
        
        // Search PATH via /usr/bin/which
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["yabai"]
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty, FileManager.default.fileExists(atPath: path) {
                    cachedYabaiPath = path
                    return path
                }
            }
        } catch {
            // Ignore
        }
        
        return nil
    }
    
    /// Ensures that yabai is installed and active before vim-mac starts
    @discardableResult
    public static func ensureYabaiRunning() -> Bool {
        guard let yabaiPath = findYabaiPath() else {
            print("\u{001B}[1;31m[vim-mac] Required dependency missing: 'yabai' is not installed.\u{001B}[0m")
            print("Please install yabai via Homebrew:")
            print("  \u{001B}[36mbrew install koekeishiya/formulae/yabai\u{001B}[0m")
            print("  \u{001B}[36myabai --start-service\u{001B}[0m\n")
            return false
        }
        
        // Check if yabai is already responsive
        if isYabaiSocketActive(yabaiPath: yabaiPath) {
            print("\u{001B}[32m[vim-mac] yabai service is active and connected.\u{001B}[0m")
            return true
        }
        
        // Attempt to launch yabai service automatically
        print("\u{001B}[33m[vim-mac] Starting yabai service...\u{001B}[0m")
        let startProcess = Process()
        startProcess.executableURL = URL(fileURLWithPath: yabaiPath)
        startProcess.arguments = ["--start-service"]
        try? startProcess.run()
        startProcess.waitUntilExit()
        
        usleep(400000) // 400ms delay for socket initialization
        
        if isYabaiSocketActive(yabaiPath: yabaiPath) {
            print("\u{001B}[32m[vim-mac] yabai service started successfully.\u{001B}[0m")
            return true
        } else {
            print("\u{001B}[33m[vim-mac] Warning: yabai service not responding. Run 'yabai --start-service' or check Accessibility permissions.\u{001B}[0m")
            return false
        }
    }
    
    private static func isYabaiSocketActive(yabaiPath: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: yabaiPath)
        process.arguments = ["-m", "query", "--spaces"]
        let pipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
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
