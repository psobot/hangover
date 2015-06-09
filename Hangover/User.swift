//
//  User.swift
//  Hangover
//
//  Created by Peter Sobot on 6/8/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Foundation

class User {
    let DEFAULT_NAME = "Unknown"

    // A chat user.
    // Handles full_name or first_name being nil by creating an approximate
    // first_name from the full_name, or setting both to DEFAULT_NAME.

    let id: UserID
    let full_name: String
    let first_name: String
    let photo_url: String?
    let emails: [String]
    let is_self: Bool

    init(user_id: UserID, full_name: String?=nil, first_name: String?=nil, photo_url: String?, emails: [String], is_self: Bool) {
        // Initialize a User.
        self.id = user_id
        self.full_name = full_name == nil ? DEFAULT_NAME : full_name!
        self.first_name = first_name == nil ? self.full_name.componentsSeparatedByString(" ").first! : first_name!
        self.photo_url = photo_url
        self.emails = emails
        self.is_self = is_self
    }

    convenience init(entity: CLIENT_ENTITY, self_user_id: UserID?) {
        // Initialize from a ClientEntity.
        // If self_user_id is nil, assume this is the self user.
        let user_id = UserID(chat_id: entity.id.chat_id as String, gaia_id: entity.id.gaia_id as String)
        var is_self = false
        if let sui = self_user_id {
            is_self = sui == user_id
        } else {
            is_self = true
        }
        self.init(user_id: user_id,
            full_name: entity.properties.display_name as String?,
            first_name: entity.properties.first_name as String?,
            photo_url: entity.properties.photo_url as String?,
            emails: entity.properties.emails.map { $0 as! String },
            is_self: is_self
        )

    }

    convenience init(conv_part_data: CLIENT_CONVERSATION.PARTICIPANT_DATA, self_user_id: UserID?) {
        // Initialize from ClientConversationParticipantData.
        // If self_user_id is nil, assume this is the self user.
        let user_id = UserID(chat_id: conv_part_data.id.chat_id as String, gaia_id: conv_part_data.id.gaia_id as String)
        var is_self = false
        if let sui = self_user_id {
            is_self = sui == user_id
        } else {
            is_self = true
        }
        self.init(user_id: user_id,
            full_name: conv_part_data.fallback_name as? String,
            first_name: nil,
            photo_url: nil,
            emails: [],
            is_self: is_self
        )
    }
}