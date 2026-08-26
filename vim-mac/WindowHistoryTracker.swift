//
//  WindowHistoryTracker.swift
//  vim-mac
//
//  Created by Antigravity on 8/26/26.
//

import Cocoa
import ApplicationServices

public class WindowHistoryTracker {
    public static let shared = WindowHistoryTracker()
    
    private var recentPIDs: [pid_t] = []
    private let maxHistory = 10
    
    private init() {
        setupWorkspaceNotifications()
        recordCurrentFrontmostApp()
    }
    
    private func setupWorkspaceNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    @objc private func applicationActivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        recordPID(app.processIdentifier)
    }
    
    private func recordCurrentFrontmostApp() {
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            recordPID(frontApp.processIdentifier)
        }
    }
    
    private func recordPID(_ pid: pid_t) {
        // Keep PID unique and push to front of recentPIDs
        recentPIDs.removeAll(where: { $0 == pid })
        recentPIDs.insert(pid, at: 0)
        if recentPIDs.count > maxHistory {
            recentPIDs = Array(recentPIDs.prefix(maxHistory))
        }
    }
    
    /// Queries the system for top visible normal application windows in z-order (front to back)
    public func getTopVisibleWindows(limit: Int) -> [AXUIElement] {
        var results: [AXUIElement] = []
        var seenPIDs = Set<pid_t>()
        
        // 1. Ensure current frontmost app window is first
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let appRef = AXUIElementCreateApplication(frontApp.processIdentifier)
            var focusedWindow: AnyObject?
            if AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success,
               let windowRef = focusedWindow {
                results.append(windowRef as! AXUIElement)
                seenPIDs.insert(frontApp.processIdentifier)
            }
        }
        
        if results.count >= limit {
            return Array(results.prefix(limit))
        }
        
        // 2. Query CGWindowList for on-screen layer 0 windows in z-order
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return results
        }
        
        for info in windowListInfo {
            if results.count >= limit { break }
            
            // Only examine normal windows (layer 0)
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t else { continue }
            
            // Filter out already captured PIDs (one primary window per app for multi-app presets)
            if seenPIDs.contains(pid) { continue }
            
            // Filter out system processes
            if let runningApp = NSRunningApplication(processIdentifier: pid),
               runningApp.activationPolicy != .regular {
                continue
            }
            
            // Filter out tiny / invisible windows
            if let bounds = info[kCGWindowBounds as String] as? [String: CGFloat] {
                let width = bounds["Width"] ?? 0
                let height = bounds["Height"] ?? 0
                if width < 100 || height < 100 { continue }
            }
            
            // Resolve AXUIElement for this app's primary window
            let appRef = AXUIElementCreateApplication(pid)
            var windowListRef: AnyObject?
            if AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowListRef) == .success,
               let windows = windowListRef as? [AXUIElement], !windows.isEmpty {
                // Pick the first/focused window
                var targetWindow = windows[0]
                var focusedRef: AnyObject?
                if AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedRef) == .success,
                   let focused = focusedRef {
                    targetWindow = focused as! AXUIElement
                }
                
                results.append(targetWindow)
                seenPIDs.insert(pid)
            }
        }
        
        return Array(results.prefix(limit))
    }
    
    /// Returns the currently active (frontmost) window
    public func getActiveWindow() -> AXUIElement? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }
        let appRef = AXUIElementCreateApplication(frontApp.processIdentifier)
        var windowRef: AnyObject?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef)
        return result == .success ? (windowRef as! AXUIElement) : nil
    }
    
    /// Returns the previous active window (2nd in MRU order)
    public func getPreviousWindow() -> AXUIElement? {
        let windows = getTopVisibleWindows(limit: 2)
        return windows.count > 1 ? windows[1] : nil
    }
}
