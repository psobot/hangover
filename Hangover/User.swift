//
//  User.swift
//  Hangover
//
//  Created by Peter Sobot on 6/8/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Foundation

class User {
    static let DEFAULT_NAME = "Unknown"

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
        self.full_name = full_name == nil ? User.DEFAULT_NAME : full_name!
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

let ClientStateUpdatedNotification = "ClientStateUpdated"
let ClientStateUpdatedNewStateKey = "ClientStateNewState"

class UserList {
    // Collection of User instances.

    private let client: Client
    private let self_user: User
    private var user_dict: [UserID : User]

    init(client: Client, self_entity: CLIENT_ENTITY, entities: [CLIENT_ENTITY], conv_parts: [CLIENT_CONVERSATION.PARTICIPANT_DATA]) {
        // Initialize the list of Users.
        // Creates users from the given ClientEntity and
        // ClientConversationParticipantData instances. The latter is used only as
        // a fallback, because it doesn't include a real first_name.

        self.client = client
        self.self_user = User(entity: self_entity, self_user_id: nil)
        self.user_dict = [self.self_user.id: self.self_user]
        // Add each entity as a new User.
        for entity in entities {
            let user = User(entity: entity, self_user_id: self.self_user.id)
            self.user_dict[user.id] = user
        }
        // Add each conversation participant as a new User if we didn't already
        // add them from an entity.
        for participant in conv_parts {
            self.add_user_from_conv_part(participant)
        }
        print("UserList initialized with \(user_dict.count) users.")
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("on_state_update_notification"),
            name: ClientStateUpdatedNotification,
            object: self.client
        )
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func get_user(user_id: UserID) -> User {
        // Return a User by their UserID.
        // Raises KeyError if the User is not available.
        if let elem = self.user_dict[user_id] {
            return elem
        } else {
            print("UserList returning unknown User for UserID \(user_id)")
            return User(user_id: user_id,
                full_name: User.DEFAULT_NAME,
                first_name: nil,
                photo_url: nil,
                emails: [],
                is_self: false
            )
        }
    }

    func get_all() -> [User] {
        // Returns all the users known
        return Array(self.user_dict.values)
    }

    func add_user_from_conv_part(conv_part: CLIENT_CONVERSATION.PARTICIPANT_DATA) -> User {
        // Add new User from ClientConversationParticipantData
        let user = User(conv_part_data: conv_part, self_user_id: self.self_user.id)
        if self.user_dict[user.id] == nil {
            print("Adding fallback User: \(user)")
            self.user_dict[user.id] = user
        }
        return user
    }

    private func on_state_update_notification(notification: NSNotification) {
        if let userInfo = notification.userInfo, state_update = userInfo[ClientStateUpdatedNewStateKey as NSString] {
            on_state_update(state_update as! CLIENT_STATE_UPDATE)
        }
    }

    private func on_state_update(state_update: CLIENT_STATE_UPDATE) {
        // Receive a ClientStateUpdate
        if let conversation = state_update.client_conversation {
            self.handle_client_conversation(conversation)
        }
    }

    private func handle_client_conversation(client_conversation: CLIENT_CONVERSATION) {
        // Receive ClientConversation and update list of users
        for participant in client_conversation.participant_data {
            self.add_user_from_conv_part(participant)
        }
    }
}