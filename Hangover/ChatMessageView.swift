//
//  ChatMessageEventView.swift
//  Hangover
//
//  Created by Peter Sobot on 6/11/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Cocoa

class ChatMessageView : NSTableCellView {
    enum Orientation {
        case Left
        case Right
    }

    var textLabel: NSTextField!
    var backgroundView: NSImageView!
    var orientation: Orientation = .Left
    static let font = NSFont.systemFontOfSize(13)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        backgroundView = NSImageView(frame: NSZeroRect)
        backgroundView.imageScaling = .ScaleAxesIndependently
        backgroundView.image = NSImage(named: "gray_bubble_left")
        addSubview(backgroundView)

        textLabel = NSTextField(frame: NSZeroRect)
        textLabel.drawsBackground = false
        textLabel.bezeled = false
        textLabel.bordered = false
        textLabel.editable = false
        textLabel.font = ChatMessageView.font
        addSubview(textLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureWithMessage(message: ChatMessageEvent, user: User) {
        orientation = user.is_self ? .Right : .Left
        textLabel.stringValue = message.text
        textLabel.alignment = orientation == .Right ? .Right : .Left
        //textLabel.lineBreakMode = .ByClipping
        toolTip = message.text
        backgroundView.image = NSImage(named: orientation == .Right ? "gray_bubble_right" : "gray_bubble_left")
    }


    static let WidthPercentage: CGFloat = 0.75
    static let TextPointySideBorder: CGFloat = 8
    static let TextRoundSideBorder: CGFloat = 2
    static let TextTopBorder: CGFloat = 4
    static let TextBottomBorder: CGFloat = 4
    static let VerticalTextPadding: CGFloat = 4

    override func layout() {
        super.layout()
    }

    override var frame: NSRect {
        didSet {
            var backgroundFrame = frame

            backgroundFrame.size.width *= ChatMessageView.WidthPercentage

            let textMaxWidth = backgroundFrame.size.width - ChatMessageView.TextRoundSideBorder - ChatMessageView.TextPointySideBorder
            let textSize = ChatMessageView.textSizeInWidth(self.textLabel.stringValue, width: textMaxWidth)

            backgroundFrame.size.width = textSize.width + ChatMessageView.TextRoundSideBorder + ChatMessageView.TextPointySideBorder

            switch (orientation) {
            case .Left:
                backgroundFrame.origin.x = frame.origin.x
            case .Right:
                backgroundFrame.origin.x = frame.size.width - backgroundFrame.size.width
            }

            backgroundView.frame = backgroundFrame

            switch (orientation) {
            case .Left:
                textLabel.frame = NSRect(
                    x: backgroundView.frame.origin.x + ChatMessageView.TextPointySideBorder,
                    y: backgroundView.frame.origin.y + ChatMessageView.TextTopBorder - (ChatMessageView.VerticalTextPadding / 2),
                    width: textSize.width - ChatMessageView.TextRoundSideBorder,
                    height: textSize.height + ChatMessageView.VerticalTextPadding / 2
                )
            case .Right:
                textLabel.frame = NSRect(
                    x: backgroundView.frame.origin.x + ChatMessageView.TextRoundSideBorder,
                    y: backgroundView.frame.origin.y + ChatMessageView.TextTopBorder - (ChatMessageView.VerticalTextPadding / 2),
                    width: textSize.width,
                    height: textSize.height + ChatMessageView.VerticalTextPadding / 2
                )
            }
        }
    }

    class func textSizeInWidth(text: String, width: CGFloat) -> CGSize {
        let textStorage = NSTextStorage(string: text)
        let textContainer = NSTextContainer(containerSize: NSMakeSize(width, CGFloat.max))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textStorage.addAttribute(NSFontAttributeName, value:font, range:NSMakeRange(0, textStorage.length))
        layoutManager.glyphRangeForTextContainer(textContainer)

        return layoutManager.usedRectForTextContainer(textContainer).size;
    }

    class func heightForWidth(text: String, width: CGFloat) -> CGFloat {
        return textSizeInWidth(
            text,
            width: (width * WidthPercentage) - TextRoundSideBorder - TextPointySideBorder
        ).height + TextTopBorder + TextBottomBorder
    }
}