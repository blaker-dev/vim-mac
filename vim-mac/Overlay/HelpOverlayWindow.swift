//
//  HelpOverlayWindow.swift
//  vim-mac
//
//  Created by Antigravity on 8/26/26.
//

import Cocoa

public class HelpOverlayWindow: NSPanel {
    
    public init() {
        let width: CGFloat = 740
        let height: CGFloat = 580
        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        
        super.init(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.alphaValue = 0.90 // Semi-transparent modal card
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.hasShadow = true
        
        setupViews(width: width, height: height)
    }
    
    private func setupViews(width: CGFloat, height: CGFloat) {
        let effectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 20
        effectView.layer?.masksToBounds = true
        effectView.layer?.borderWidth = 1.0
        effectView.layer?.borderColor = NSColor.white.withAlphaComponent(0.2).cgColor
        
        // Header Title
        let titleLabel = NSTextField(labelWithString: "⌘ vim-mac Manual & Keybindings")
        titleLabel.frame = NSRect(x: 32, y: height - 52, width: width - 64, height: 32)
        titleLabel.font = NSFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = NSColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1.0)
        titleLabel.backgroundColor = .clear
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        effectView.addSubview(titleLabel)
        
        // Scrollable or structured stack view layout
        let sections: [(title: String, items: [(String, String)])] = [
            ("MODES & CONTROLS", [
                ("Ctrl + :", "Toggle Move Mode (capture keys) vs Insert Mode"),
                ("Esc", "Return to Insert Mode / Dismiss overlays"),
                (":", "Enter Command Mode (Spotlight bar)"),
                ("?", "Toggle this floating help manual")
            ]),
            ("MOTIONS & RESIZING", [
                ("h / j / k / l", "Move window Left / Down / Up / Right (50px)"),
                ("Shift + h/j/k/l", "Resize window width/height (+/- 50px)"),
                ("Ctrl + motion", "Precision / Fine step movement & resize (10px)")
            ]),
            ("SNAPPING & PRESETS", [
                ("Option + h/j/k/l", "Snap to Left / Bottom / Top / Right half"),
                ("Option + chord", "Corner chords (Option+h then k -> Top-Left)"),
                ("2 / Option+2", "2-Window Vertical / Horizontal Split (50/50)"),
                ("3 / 4", "3-Window Master-Stack / 4-Window 2x2 Grid"),
                ("a / f", "Throw window to Left / Right Space (yabai)"),
                ("s / x", "Swap current window with last used window"),
                ("m / c", "Maximize / Center focused window")
            ]),
            ("COLON COMMANDS (:)", [
                (":vsplit / :split", "Vertical or Horizontal 2-window split"),
                (":swap", "Swap position with previous window"),
                (":preset 2|2h|3|4", "Apply multi-window arrangements"),
                (":max / :center", "Maximize or Center active window"),
                (":set step=75", "Configure pixel movement step size"),
                (":quit / :q", "Exit vim-mac background daemon")
            ])
        ]
        
        var currentY: CGFloat = height - 85
        let marginX: CGFloat = 32
        
        for section in sections {
            // Section Header
            let sectionHeader = NSTextField(labelWithString: section.title)
            sectionHeader.frame = NSRect(x: marginX, y: currentY - 16, width: width - (marginX * 2), height: 18)
            sectionHeader.font = NSFont.systemFont(ofSize: 11, weight: .black)
            sectionHeader.textColor = NSColor.white.withAlphaComponent(0.45)
            sectionHeader.backgroundColor = .clear
            sectionHeader.isBezeled = false
            sectionHeader.isEditable = false
            effectView.addSubview(sectionHeader)
            
            currentY -= 22
            
            // Section Items
            for (key, desc) in section.items {
                let keyLabel = NSTextField(labelWithString: key)
                keyLabel.frame = NSRect(x: marginX, y: currentY - 18, width: 170, height: 20)
                keyLabel.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .bold)
                keyLabel.textColor = NSColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)
                keyLabel.backgroundColor = .clear
                keyLabel.isBezeled = false
                keyLabel.isEditable = false
                
                let descLabel = NSTextField(labelWithString: desc)
                descLabel.frame = NSRect(x: marginX + 175, y: currentY - 18, width: width - marginX - 175 - marginX, height: 20)
                descLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
                descLabel.textColor = NSColor.white.withAlphaComponent(0.9)
                descLabel.backgroundColor = .clear
                descLabel.isBezeled = false
                descLabel.isEditable = false
                
                effectView.addSubview(keyLabel)
                effectView.addSubview(descLabel)
                
                currentY -= 20
            }
            
            currentY -= 10 // Spacing between sections
        }
        
        self.contentView = effectView
    }
    
    public func updatePosition(on screen: NSScreen) {
        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.origin.x + (visibleFrame.width - self.frame.width) / 2
        let y = visibleFrame.origin.y + (visibleFrame.height - self.frame.height) / 2
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
