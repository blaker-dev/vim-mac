//
//  OverlayManager.swift
//  vim-mac
//
//  Created by Antigravity on 8/26/26.
//

import Cocoa

public class OverlayManager {
    public static let shared = OverlayManager()
    
    private var moveIndicatorWindow: MoveModeIndicatorWindow?
    private var commandBarWindow: CommandBarWindow?
    private var helpOverlayWindow: HelpOverlayWindow?
    
    public private(set) var isHelpVisible: Bool = false
    
    private init() {
        DispatchQueue.main.async {
            self.setupWindows()
        }
    }
    
    private func setupWindows() {
        self.moveIndicatorWindow = MoveModeIndicatorWindow()
        self.commandBarWindow = CommandBarWindow()
        self.helpOverlayWindow = HelpOverlayWindow()
    }
    
    private func getActiveScreen() -> NSScreen {
        if let activeWindow = WindowManager.shared.getActiveWindow(),
           let frame = WindowManager.shared.getWindowFrame(window: activeWindow) {
            return WindowManager.shared.getCurrentScreen(for: frame)
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }
    
    // MARK: - Public Overlay API
    
    public func setMode(_ mode: Mode) {
        DispatchQueue.main.async {
            let screen = self.getActiveScreen()
            
            switch mode {
            case .move:
                self.commandBarWindow?.orderOut(nil)
                self.moveIndicatorWindow?.updatePosition(on: screen)
                self.moveIndicatorWindow?.orderFront(nil)
                
            case .command:
                self.moveIndicatorWindow?.orderOut(nil)
                self.commandBarWindow?.updatePosition(on: screen)
                self.commandBarWindow?.updateCommandText("")
                self.commandBarWindow?.orderFront(nil)
                
            case .insert:
                self.moveIndicatorWindow?.orderOut(nil)
                self.commandBarWindow?.orderOut(nil)
                self.helpOverlayWindow?.orderOut(nil)
                self.isHelpVisible = false
            }
        }
    }
    
    public func updateCommandText(_ text: String) {
        DispatchQueue.main.async {
            self.commandBarWindow?.updateCommandText(text)
        }
    }
    
    public func toggleHelpOverlay() {
        DispatchQueue.main.async {
            guard let helpWin = self.helpOverlayWindow else { return }
            if helpWin.isVisible {
                helpWin.orderOut(nil)
                self.isHelpVisible = false
            } else {
                let screen = self.getActiveScreen()
                helpWin.updatePosition(on: screen)
                helpWin.orderFront(nil)
                self.isHelpVisible = true
            }
        }
    }
    
    public func hideHelpOverlay() {
        DispatchQueue.main.async {
            self.helpOverlayWindow?.orderOut(nil)
            self.isHelpVisible = false
        }
    }
}
