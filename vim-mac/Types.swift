//
//  Types.swift
//  vim-mac
//
//  Created by Antigravity on 8/26/26.
//

import Cocoa

public enum Mode: String {
    case insert = "INSERT"
    case move = "MOVE"
    case command = "COMMAND"
}

public enum Direction {
    case left
    case right
    case up
    case down
}

public enum SnapPosition {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeftCorner
    case topRightCorner
    case bottomLeftCorner
    case bottomRightCorner
    case maximize
    case center
}

public enum LayoutPreset {
    case splitVertical    // 2 windows, left/right 50/50
    case splitHorizontal  // 2 windows, top/bottom 50/50
    case masterStack3     // 3 windows: 1 large left, 2 stacked right
    case grid4            // 4 windows: 2x2 grid (4 corners)
}

public struct Config {
    public static var shared = Config()
    
    public var standardStep: CGFloat = 50.0
    public var fineStep: CGFloat = 10.0
    public var chordThreshold: TimeInterval = 0.45
    public var spaceThrowDelay: TimeInterval = 0.35
    public var windowCenterRatio: CGFloat = 0.70
}
