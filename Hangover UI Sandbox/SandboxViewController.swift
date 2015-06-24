//
//  ViewController.swift
//  Hangover UI Sandbox
//
//  Created by Peter Sobot on 6/23/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Cocoa

class SandboxViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var conversationTableView: NSTableView!

    let messages = [
//        ("Oh hey, person number 1.", ChatMessageView.Orientation.Left),
//        ("Hey person number 2, what's up?", ChatMessageView.Orientation.Right),
//        ("Not all that much, just testing out this chat client.", ChatMessageView.Orientation.Left),
        ("Coooooooooool beans. Will this longer message wrap onto multiple lines and possibly cause any issues?", ChatMessageView.Orientation.Right),
    ]

    override func viewDidAppear() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("frameDidChangeNotification:"),
            name: NSViewFrameDidChangeNotification,
            object: self.view
        );
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: NSTableViewDataSource
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return messages.count
    }

    // MARK: NSTableViewDelegate
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row < messages.count {
            let message = messages[row]

            let useTextField = true

            if useTextField {
                var view = tableView.makeViewWithIdentifier(ChatMessageView.className(), owner: self) as? NSTextField

                if view == nil {
                    //view = ChatMessageView(frame: NSZeroRect)
                    view = NSTextField(frame: NSZeroRect)
                    view!.bezeled = false
                    view!.bordered = false
                    view!.backgroundColor = NSColor(calibratedRed: 1.0, green: 0.0, blue: 0.0, alpha: 0.1)
                    view!.identifier = ChatMessageView.className()
                }
                view!.stringValue = message.0
                view!.alignment = (message.1 == ChatMessageView.Orientation.Left) ? .Left : .Right
                return view;
            } else {
                var view = tableView.makeViewWithIdentifier(ChatMessageView.className(), owner: self) as? ChatMessageView

                if view == nil {
                    view = ChatMessageView(frame: NSZeroRect)
                    view!.identifier = ChatMessageView.className()
                }
                view!.configureWithText(message.0, orientation: message.1)
                return view
            }
        }

        return nil
    }

    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if row < messages.count {
            // METHOD A (works, but sometimes leaves a border)
//            return NSAttributedString(
//                string: messages[row].0,
//                attributes: [NSFontAttributeName: NSFont.systemFontOfSize(NSFont.systemFontSize())]
//            ).boundingRectWithSize(
//                NSMakeSize(self.conversationTableView.frame.width, 0),
//                options: [.UsesDeviceMetrics, .UsesLineFragmentOrigin, .UsesFontLeading]
//            ).size.height

            // METHOD B (same as method A)
//            let textStorage = NSTextStorage(string: messages[row].0)
//            let textContainer = NSTextContainer(containerSize: NSMakeSize(self.conversationTableView.frame.width, CGFloat.max))
//            let layoutManager = NSLayoutManager()
//            layoutManager.addTextContainer(textContainer)
//            textStorage.addLayoutManager(layoutManager)
//            textStorage.addAttribute(NSFontAttributeName, value:NSFont.systemFontOfSize(NSFont.systemFontSize()), range:NSMakeRange(0, textStorage.length))
//            layoutManager.glyphRangeForTextContainer(textContainer)
//            return layoutManager.usedRectForTextContainer(textContainer).size.height

            // METHOD C
            let attrString =  NSAttributedString(
                string: messages[row].0,
                attributes: [NSFontAttributeName: NSFont.systemFontOfSize(NSFont.systemFontSize())]
            )
            let framesetter = CTFramesetterCreateWithAttributedString(attrString)
            let targetSize = CGSizeMake(self.conversationTableView.frame.width, CGFloat.max);
            let fitSize = CTFramesetterSuggestFrameSizeWithConstraints(
                framesetter,
                CFRangeMake(0, attrString.length),
                nil,
                targetSize,
                nil
            )
            return fitSize.height

            //return ChatMessageView.heightForContainerWidth(
            //    messages[row].0, width: self.conversationTableView.frame.width - 5)
        } else {
            return 0
        }
    }

    // MARK: Notification handlers
    func frameDidChangeNotification(sender: AnyObject?) {
        //  TODO: This is a horrible, horrible way to do this, and super CPU-intensive.
        //  B U T   I T   W O R K S   F O R   N O W
        conversationTableView.reloadData()
    }
}

