//
//  LayoutEngine.swift
//  vim-mac
//
//  Created by Antigravity on 8/26/26.
//

import Cocoa

public struct LayoutEngine {
    
    /// Converts Cocoa NSScreen coordinates to Accessibility (top-left origin) coordinates
    public static func getUsableScreenBounds(for screen: NSScreen, primaryScreenHeight: CGFloat) -> CGRect {
        let visibleFrame = screen.visibleFrame
        let axX = visibleFrame.origin.x
        let axY = primaryScreenHeight - (visibleFrame.origin.y + visibleFrame.height)
        return CGRect(x: axX, y: axY, width: visibleFrame.width, height: visibleFrame.height)
    }
    
    /// Computes target frame for single window snapping
    public static func calculateSnapFrame(
        position: SnapPosition,
        screen: NSScreen,
        primaryScreenHeight: CGFloat
    ) -> CGRect {
        let bounds = getUsableScreenBounds(for: screen, primaryScreenHeight: primaryScreenHeight)
        let x = bounds.origin.x
        let y = bounds.origin.y
        let w = bounds.width
        let h = bounds.height
        
        switch position {
        case .leftHalf:
            return CGRect(x: x, y: y, width: w / 2, height: h)
        case .rightHalf:
            return CGRect(x: x + (w / 2), y: y, width: w / 2, height: h)
        case .topHalf:
            return CGRect(x: x, y: y, width: w, height: h / 2)
        case .bottomHalf:
            return CGRect(x: x, y: y + (h / 2), width: w, height: h / 2)
        case .topLeftCorner:
            return CGRect(x: x, y: y, width: w / 2, height: h / 2)
        case .topRightCorner:
            return CGRect(x: x + (w / 2), y: y, width: w / 2, height: h / 2)
        case .bottomLeftCorner:
            return CGRect(x: x, y: y + (h / 2), width: w / 2, height: h / 2)
        case .bottomRightCorner:
            return CGRect(x: x + (w / 2), y: y + (h / 2), width: w / 2, height: h / 2)
        case .maximize:
            return CGRect(x: x, y: y, width: w, height: h)
        case .center:
            let ratio = Config.shared.windowCenterRatio
            let targetW = w * ratio
            let targetH = h * ratio
            let targetX = x + (w - targetW) / 2
            let targetY = y + (h - targetH) / 2
            return CGRect(x: targetX, y: targetY, width: targetW, height: targetH)
        }
    }
    
    /// Computes array of target frames for multi-window presets
    public static func calculatePresetFrames(
        preset: LayoutPreset,
        screen: NSScreen,
        primaryScreenHeight: CGFloat
    ) -> [CGRect] {
        let bounds = getUsableScreenBounds(for: screen, primaryScreenHeight: primaryScreenHeight)
        let x = bounds.origin.x
        let y = bounds.origin.y
        let w = bounds.width
        let h = bounds.height
        
        switch preset {
        case .splitVertical:
            return [
                CGRect(x: x, y: y, width: w / 2, height: h),             // Left
                CGRect(x: x + (w / 2), y: y, width: w / 2, height: h)      // Right
            ]
            
        case .splitHorizontal:
            return [
                CGRect(x: x, y: y, width: w, height: h / 2),             // Top
                CGRect(x: x, y: y + (h / 2), width: w, height: h / 2)      // Bottom
            ]
            
        case .masterStack3:
            return [
                CGRect(x: x, y: y, width: w / 2, height: h),             // Master (Big Left)
                CGRect(x: x + (w / 2), y: y, width: w / 2, height: h / 2), // Stack Top Right
                CGRect(x: x + (w / 2), y: y + (h / 2), width: w / 2, height: h / 2) // Stack Bottom Right
            ]
            
        case .grid4:
            return [
                CGRect(x: x, y: y, width: w / 2, height: h / 2),             // Top Left
                CGRect(x: x + (w / 2), y: y, width: w / 2, height: h / 2),     // Top Right
                CGRect(x: x, y: y + (h / 2), width: w / 2, height: h / 2),     // Bottom Left
                CGRect(x: x + (w / 2), y: y + (h / 2), width: w / 2, height: h / 2) // Bottom Right
            ]
        }
    }
}
