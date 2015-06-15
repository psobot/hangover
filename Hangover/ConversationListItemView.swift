//
//  ConversationListItemView.swift
//  Hangover
//
//  Created by Peter Sobot on 6/11/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Cocoa

class ConversationListItemView : NSTableCellView {
    @IBOutlet weak var avatarView: NSImageView!
    @IBOutlet weak var nameView: NSTextField!
    @IBOutlet weak var lastMessageView: NSTextField!
    @IBOutlet weak var timeView: NSTextField!

    func configureWithConversation(conversation: Conversation) {
        avatarView.wantsLayer = true

        avatarView.layer?.borderWidth = 0.0
        avatarView.layer?.cornerRadius = avatarView.frame.width / 2.0
        avatarView.layer?.masksToBounds = true

        if let user = conversation.user_list.get_all().first,
                photoURLString = user.photo_url,
                photoURL = NSURL(string: photoURLString) {
            avatarView.loadImageFromURL(photoURL)
        }
        nameView.stringValue = conversation.name
        lastMessageView.stringValue = conversation.messages.last?.text ?? ""
        timeView.stringValue = conversation.messages.last?.timestamp.shortFormat() ?? ""
    }
}