//
//  MoveModeIndicatorWindow.swift
//  vim-mac
//
//  Created by Antigravity on 8/26/26.
//

import Cocoa

public class MoveModeIndicatorWindow: NSPanel {
    
    public init() {
        let width: CGFloat = 104
        let height: CGFloat = 32
        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        super.init(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.ignoresMouseEvents = true
        self.hasShadow = true
        
        let pillView = MoveActivePillView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        self.contentView = pillView
    }
    
    public func updatePosition(on screen: NSScreen) {
        let visibleFrame = screen.visibleFrame
        // Bottom right corner of the screen visible area (above dock / inset by 24px)
        let x = visibleFrame.origin.x + visibleFrame.width - self.frame.width - 24
        let y = visibleFrame.origin.y + 24
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

private class MoveActivePillView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // 1. Draw Translucent Capsule Background
        let capsulePath = CGPath(
            roundedRect: bounds.insetBy(dx: 1, dy: 1),
            cornerWidth: bounds.height / 2,
            cornerHeight: bounds.height / 2,
            transform: nil
        )
        
        context.saveGState()
        context.addPath(capsulePath)
        context.setFillColor(NSColor.black.withAlphaComponent(0.65).cgColor)
        context.fillPath()
        
        context.addPath(capsulePath)
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.2).cgColor)
        context.setLineWidth(1.0)
        context.strokePath()
        context.restoreGState()
        
        // 2. Draw Glowing Green Dot
        let dotCenter = CGPoint(x: 18, y: bounds.midY)
        let dotRadius: CGFloat = 5.0
        
        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: 0),
            blur: 5.0,
            color: NSColor.systemGreen.cgColor
        )
        
        let dotPath = CGPath(ellipseIn: CGRect(
            x: dotCenter.x - dotRadius,
            y: dotCenter.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ), transform: nil)
        
        context.addPath(dotPath)
        context.setFillColor(NSColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1.0).cgColor)
        context.fillPath()
        context.restoreGState()
        
        // 3. Draw "Active" Text Label
        let text = "Active" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.95)
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: 30,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)
    }
}
