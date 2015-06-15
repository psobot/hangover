//
//  ChatMessageEventView.swift
//  Hangover
//
//  Created by Peter Sobot on 6/11/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Cocoa

class ChatMessageView : NSTableCellView {
    @IBOutlet weak var textLabel: NSTextField!

    func configureWithMessage(message: ChatMessageEvent, user: User) {
        textLabel.alignment = user.is_self ? NSTextAlignment.Right : NSTextAlignment.Left
        textLabel.stringValue = message.text + message.text + message.text
        layer?.backgroundColor = NSColor.greenColor().CGColor
    }
}