//
//  ChatMessageEventView.swift
//  Hangover
//
//  Created by Peter Sobot on 6/11/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Cocoa

class ChatMessageView : NSView {
    enum Orientation {
        case Left
        case Right
    }

    var textLabel: NSTextField!
    var backgroundView: NSImageView!

    var orientation: Orientation = .Left
    static let font = NSFont.systemFontOfSize(NSFont.systemFontSize())

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

//        backgroundView = NSImageView(frame: NSZeroRect)
//        backgroundView.imageScaling = .ScaleAxesIndependently
//        backgroundView.image = NSImage(named: "gray_bubble_left")
//        addSubview(backgroundView)

        textLabel = NSTextField(frame: NSZeroRect)
        textLabel.drawsBackground = true
        textLabel.backgroundColor = NSColor(calibratedRed: 1.0, green: 0.0, blue: 0.0, alpha: 0.2)
        textLabel.bezeled = false
        textLabel.bordered = false
        textLabel.editable = false
        //textLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        textLabel.font = ChatMessageView.font
        addSubview(textLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureWithText(string: String, orientation: Orientation) {
        self.orientation = orientation
        textLabel.alignment = (orientation == .Left) ? .Left : .Right
        textLabel.stringValue = string
        //backgroundView.image = NSImage(named: orientation == .Right ? "gray_bubble_right" : "gray_bubble_left")
    }

    static let WidthPercentage: CGFloat = 1//0.75
    static let TextPointySideBorder: CGFloat = 0//8
    static let TextRoundSideBorder: CGFloat = 0//4
    static let TextTopBorder: CGFloat = 0//4
    static let TextBottomBorder: CGFloat = 0//4
    static let VerticalTextPadding: CGFloat = 0//4

    override var frame: NSRect {
        didSet {
            self.textLabel.frame = frame
            return
            var backgroundFrame = frame


            backgroundFrame.size.width *= ChatMessageView.WidthPercentage

            let textMaxWidth = ChatMessageView.widthOfText(backgroundWidth: backgroundFrame.size.width)
            let textSize = ChatMessageView.textSizeInWidth(self.textLabel.stringValue, width: textMaxWidth - 5)

            backgroundFrame.size.width = ChatMessageView.widthOfBackground(textWidth: textSize.width)

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
                    width: textSize.width,
                    height: textSize.height + ChatMessageView.VerticalTextPadding / 2
                )
            case .Right:
                textLabel.frame = NSRect(
                    x: backgroundView.frame.origin.x + ChatMessageView.TextPointySideBorder,
                    y: backgroundView.frame.origin.y + ChatMessageView.TextTopBorder - (ChatMessageView.VerticalTextPadding / 2),
                    width: textSize.width,
                    height: textSize.height + ChatMessageView.VerticalTextPadding / 2
                )
            }
        }
    }

    class func widthOfText(backgroundWidth backgroundWidth: CGFloat) -> CGFloat {
        return backgroundWidth - ChatMessageView.TextRoundSideBorder - ChatMessageView.TextPointySideBorder
    }

    class func widthOfBackground(textWidth textWidth: CGFloat) -> CGFloat {
        return textWidth + ChatMessageView.TextRoundSideBorder + ChatMessageView.TextPointySideBorder
    }

    class func textSizeInWidth(text: String, width: CGFloat) -> CGSize {
//        let textStorage = NSTextStorage(string: text)
//        let textContainer = NSTextContainer(containerSize: NSMakeSize(width, CGFloat.max))
//        let layoutManager = NSLayoutManager()
//        layoutManager.addTextContainer(textContainer)
//        textStorage.addLayoutManager(layoutManager)
//        textStorage.addAttribute(NSFontAttributeName, value:font, range:NSMakeRange(0, textStorage.length))
//        layoutManager.glyphRangeForTextContainer(textContainer)
//        return layoutManager.usedRectForTextContainer(textContainer).size
        return NSAttributedString(
            string: text,
            attributes: [NSFontAttributeName: font]
        ).boundingRectWithSize(
            NSMakeSize(width, 0),
            options: [.UsesDeviceMetrics, .UsesLineFragmentOrigin, .UsesFontLeading]
        ).size
    }

    class func heightForContainerWidth(text: String, width: CGFloat) -> CGFloat {
        let size = textSizeInWidth(text, width: widthOfText(backgroundWidth: (width * WidthPercentage)))
        Swift.print("Size of text in width \(width): \(size)")
        let height = size.height + TextTopBorder + TextBottomBorder
        Swift.print("Height of in width \(width): \(height)")
        return height
    }
}