//
//  WindowManager.swift
//  vim-mac
//
//  Created by Antigravity on 8/26/26.
//

import Cocoa
import ApplicationServices

public class WindowManager {
    public static let shared = WindowManager()
    
    public var currentMode: Mode = .insert
    
    // Chord tracking for corner snaps
    public var lastSnapKey: Direction?
    public var lastSnapTime: Date = Date.distantPast
    
    private init() {}
    
    // MARK: - Active Window & Frame Queries
    
    public func getActiveWindow() -> AXUIElement? {
        return WindowHistoryTracker.shared.getActiveWindow()
    }
    
    public func getWindowFrame(window: AXUIElement) -> CGRect? {
        var positionRef: AnyObject?
        var sizeRef: AnyObject?
        
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success else {
            return nil
        }
        
        var point = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionRef as! AXValue, .cgPoint, &point)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        
        return CGRect(origin: point, size: size)
    }
    
    public func setWindowFrame(window: AXUIElement, frame: CGRect) {
        var newSize = frame.size
        if let sizeVal = AXValueCreate(.cgSize, &newSize) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeVal)
        }
        
        var newPoint = frame.origin
        if let pointVal = AXValueCreate(.cgPoint, &newPoint) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, pointVal)
        }
        
        // Re-apply size after position in case window constrained min dimensions
        if let sizeVal = AXValueCreate(.cgSize, &newSize) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeVal)
        }
    }
    
    public func getCurrentScreen(for windowFrame: CGRect) -> NSScreen {
        let screens = NSScreen.screens
        guard let primaryScreen = screens.first else { return NSScreen.main ?? NSScreen() }
        let primaryHeight = primaryScreen.frame.height
        
        let windowCocoaCenter = CGPoint(
            x: windowFrame.midX,
            y: primaryHeight - windowFrame.midY
        )
        
        for screen in screens {
            if screen.frame.contains(windowCocoaCenter) {
                return screen
            }
        }
        return NSScreen.main ?? primaryScreen
    }
    
    // MARK: - Movement & Resizing
    
    public func moveWindow(dx: CGFloat, dy: CGFloat) {
        guard let window = getActiveWindow(), var frame = getWindowFrame(window: window) else { return }
        frame.origin.x += dx
        frame.origin.y += dy
        
        if let newPoint = AXValueCreate(.cgPoint, &frame.origin) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, newPoint)
        }
    }
    
    public func resizeWindow(dw: CGFloat, dh: CGFloat) {
        guard let window = getActiveWindow(), var frame = getWindowFrame(window: window) else { return }
        frame.size.width = max(100, frame.size.width + dw)
        frame.size.height = max(100, frame.size.height + dh)
        
        if let newSize = AXValueCreate(.cgSize, &frame.size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, newSize)
        }
    }
    
    // MARK: - Snapping & Chords
    
    public func handleSnapChord(direction: Direction) {
        let now = Date()
        let isChording = now.timeIntervalSince(lastSnapTime) <= Config.shared.chordThreshold
        
        if isChording, let previous = lastSnapKey {
            switch (previous, direction) {
            case (.left, .up), (.up, .left):
                snapWindow(to: .topLeftCorner)
            case (.right, .up), (.up, .right):
                snapWindow(to: .topRightCorner)
            case (.left, .down), (.down, .left):
                snapWindow(to: .bottomLeftCorner)
            case (.right, .down), (.down, .right):
                snapWindow(to: .bottomRightCorner)
            default:
                applySingleSnap(direction: direction)
            }
            lastSnapKey = nil
            lastSnapTime = Date.distantPast
        } else {
            applySingleSnap(direction: direction)
            lastSnapKey = direction
            lastSnapTime = now
        }
    }
    
    private func applySingleSnap(direction: Direction) {
        switch direction {
        case .left:  snapWindow(to: .leftHalf)
        case .right: snapWindow(to: .rightHalf)
        case .up:    snapWindow(to: .topHalf)
        case .down:  snapWindow(to: .bottomHalf)
        }
    }
    
    public func snapWindow(to position: SnapPosition) {
        guard let window = getActiveWindow(),
              let currentFrame = getWindowFrame(window: window),
              let primaryScreen = NSScreen.screens.first else { return }
        
        let screen = getCurrentScreen(for: currentFrame)
        let targetFrame = LayoutEngine.calculateSnapFrame(
            position: position,
            screen: screen,
            primaryScreenHeight: primaryScreen.frame.height
        )
        
        setWindowFrame(window: window, frame: targetFrame)
    }
    
    // MARK: - Multi-Window Presets
    
    public func applyPreset(_ preset: LayoutPreset) {
        let requiredCount: Int
        switch preset {
        case .splitVertical, .splitHorizontal: requiredCount = 2
        case .masterStack3: requiredCount = 3
        case .grid4: requiredCount = 4
        }
        
        let windows = WindowHistoryTracker.shared.getTopVisibleWindows(limit: requiredCount)
        guard !windows.isEmpty else {
            print("\u{001B}[33m[vim-mac] No active windows found to arrange.\u{001B}[0m")
            return
        }
        
        guard let primaryScreen = NSScreen.screens.first else { return }
        let referenceFrame = getWindowFrame(window: windows[0]) ?? CGRect(origin: .zero, size: primaryScreen.frame.size)
        let screen = getCurrentScreen(for: referenceFrame)
        
        let targetFrames = LayoutEngine.calculatePresetFrames(
            preset: preset,
            screen: screen,
            primaryScreenHeight: primaryScreen.frame.height
        )
        
        for (index, window) in windows.enumerated() {
            if index < targetFrames.count {
                setWindowFrame(window: window, frame: targetFrames[index])
            }
        }
        print("\u{001B}[32m[vim-mac] Applied preset \(preset) to \(min(windows.count, targetFrames.count)) window(s).\u{001B}[0m")
    }
    
    // MARK: - Window Swapping
    
    public func swapActiveWithPrevious() {
        let windows = WindowHistoryTracker.shared.getTopVisibleWindows(limit: 2)
        guard windows.count >= 2 else {
            print("\u{001B}[33m[vim-mac] Need at least 2 visible windows to swap.\u{001B}[0m")
            return
        }
        
        guard let frame0 = getWindowFrame(window: windows[0]),
              let frame1 = getWindowFrame(window: windows[1]) else {
            print("\u{001B}[31m[vim-mac] Could not get frames for windows to swap.\u{001B}[0m")
            return
        }
        
        setWindowFrame(window: windows[0], frame: frame1)
        setWindowFrame(window: windows[1], frame: frame0)
        print("\u{001B}[32m[vim-mac] Swapped positions of active and previous window.\u{001B}[0m")
    }
    
    // MARK: - Desktop Spaces
    
    public func throwToAdjacentSpace(direction: Direction) {
        let window = getActiveWindow()
        SpacesController.throwWindow(window: window, direction: direction)
    }
}
