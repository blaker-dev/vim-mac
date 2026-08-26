//
//  CommandBarWindow.swift
//  vim-mac
//
//  Created by Antigravity on 8/26/26.
//

import Cocoa

public class CommandBarWindow: NSPanel {
    
    private let textLabel = NSTextField(labelWithString: "")
    private let placeholderLabel = NSTextField(labelWithString: "type a command (vsplit, swap, preset 3, help, quit)...")
    
    public init() {
        let width: CGFloat = 620
        let height: CGFloat = 54
        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        
        super.init(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.alphaValue = 0.90 // Semi-transparent overlay
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.hasShadow = true
        
        setupViews(width: width, height: height)
    }
    
    private func setupViews(width: CGFloat, height: CGFloat) {
        // Visual Effect Container with dark blur transparency
        let effectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 16
        effectView.layer?.masksToBounds = true
        effectView.layer?.borderWidth = 1.0
        effectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
        
        // Colon Prompt Label (Green)
        let colonLabel = NSTextField(labelWithString: ":")
        colonLabel.frame = NSRect(x: 20, y: 12, width: 24, height: 30)
        colonLabel.font = NSFont.monospacedSystemFont(ofSize: 24, weight: .bold)
        colonLabel.textColor = NSColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1.0)
        colonLabel.backgroundColor = .clear
        colonLabel.isBezeled = false
        colonLabel.isEditable = false
        
        // Command Input Text Label
        textLabel.frame = NSRect(x: 44, y: 12, width: width - 64, height: 30)
        textLabel.font = NSFont.monospacedSystemFont(ofSize: 20, weight: .medium)
        textLabel.textColor = .white
        textLabel.backgroundColor = .clear
        textLabel.isBezeled = false
        textLabel.isEditable = false
        textLabel.lineBreakMode = .byTruncatingHead
        
        // Placeholder Label
        placeholderLabel.frame = NSRect(x: 44, y: 12, width: width - 64, height: 30)
        placeholderLabel.font = NSFont.monospacedSystemFont(ofSize: 17, weight: .regular)
        placeholderLabel.textColor = NSColor.white.withAlphaComponent(0.35)
        placeholderLabel.backgroundColor = .clear
        placeholderLabel.isBezeled = false
        placeholderLabel.isEditable = false
        
        effectView.addSubview(colonLabel)
        effectView.addSubview(placeholderLabel)
        effectView.addSubview(textLabel)
        
        self.contentView = effectView
    }
    
    public func updateCommandText(_ text: String) {
        textLabel.stringValue = text
        placeholderLabel.isHidden = !text.isEmpty
    }
    
    public func updatePosition(on screen: NSScreen) {
        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.origin.x + (visibleFrame.width - self.frame.width) / 2
        let y = visibleFrame.origin.y + (visibleFrame.height * 0.65) // Upper 35% like Spotlight
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
