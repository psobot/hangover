//
//  ChatTypingView.swift
//  Hangover
//
//  Created by Peter Sobot on 6/19/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Cocoa

class ChatTypingView : NSTableCellView {
    enum Orientation {
        case Left
        case Right
    }

    var backgroundView: NSImageView!

    var orientation: Orientation = .Left

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        backgroundView = NSImageView(frame: NSZeroRect)
        backgroundView.imageScaling = .ScaleAxesIndependently
        backgroundView.image = NSImage(named: "gray_bubble_left")
        addSubview(backgroundView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureWithTypingStatus(status: TypingStatus) {
        orientation = .Left
        backgroundView.image = NSImage(named: orientation == .Right ? "gray_bubble_right" : "gray_bubble_left")
    }

    override var frame: NSRect {
        didSet {
            var backgroundFrame = frame
            backgroundFrame.size.width = 40

            switch (orientation) {
            case .Left:
                backgroundFrame.origin.x = frame.origin.x
            case .Right:
                backgroundFrame.origin.x = frame.size.width - backgroundFrame.size.width
            }

            backgroundView.frame = backgroundFrame
        }
    }

    class func heightForWidth(width: CGFloat) -> CGFloat {
        return 33
    }
}
