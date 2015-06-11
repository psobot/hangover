//
//  ChatMessageEventView.swift
//  Hangover
//
//  Created by Peter Sobot on 6/11/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Cocoa

class ChatMessageEventView : NSView {
    var avatarView: NSImageView! {
        get {
            return nil
        }
    }
    var textLabel: NSTextField! {
        get {
            return nil
        }
    }

    func configureWithMessage(message: ChatMessageEvent, user: User) {
        if let photoURLString = user.photo_url, photoURL = NSURL(string: photoURLString) {
            avatarView.loadImageFromURL(photoURL)
        }
        textLabel.stringValue = message.text
    }
}

class ChatMessageLeftView : ChatMessageEventView {
    @IBOutlet weak var _avatarView: NSImageView!
    @IBOutlet weak var _textLabel: NSTextField!
    override var avatarView: NSImageView! {
        get {
            return _avatarView
        }
    }
    override var textLabel: NSTextField! {
        get {
            return _textLabel
        }
    }
}
class ChatMessageRightView : ChatMessageEventView {
    @IBOutlet weak var _avatarView: NSImageView!
    @IBOutlet weak var _textLabel: NSTextField!
    override var avatarView: NSImageView! {
        get {
            return _avatarView
        }
    }
    override var textLabel: NSTextField! {
        get {
            return _textLabel
        }
    }
}