//
//  ConversationList.swift
//  Hangover
//
//  Created by Peter Sobot on 6/9/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Foundation

protocol ConversationListDelegate {
    func conversationList(list: ConversationList, didReceiveEvent event: ConversationEvent)
    func conversationList(list: ConversationList, didChangeTypingStatusTo status: TypingStatus)
    func conversationList(list: ConversationList, didReceiveWatermarkNotification status: WatermarkNotification)
}

class ConversationList : ClientDelegate {
    // Wrapper around Client that maintains a list of Conversations
    let client: Client
    var conv_dict = [String : Conversation]()
    var sync_timestamp: NSDate
    let user_list: UserList

    var delegate: ConversationListDelegate?

    init(client: Client, conv_states: [CLIENT_CONVERSATION_STATE], user_list: UserList, sync_timestamp: NSDate) {
        self.client = client
        self.sync_timestamp = sync_timestamp
        self.user_list = user_list

        // Initialize the list of conversations from Client"s list of
        // ClientConversationStates.
        for conv_state in conv_states {
            self.add_conversation(conv_state.conversation, client_events: conv_state.event)
        }

        client.delegate = self
    }

    func get_all(include_archived: Bool = false) -> [Conversation] {
        // Return list of all Conversations.
        // If include_archived is false, do not return any archived conversations.
        return conv_dict.values.filter { !$0.is_archived || include_archived }
    }

    func get(conv_id: String) -> Conversation? {
        // Return a Conversation from its ID.
        return conv_dict[conv_id]
    }

    func add_conversation(
        client_conversation: CLIENT_CONVERSATION,
        client_events: [CLIENT_EVENT] = []
    ) -> Conversation {
        // Add new conversation from ClientConversation
        let conv_id = client_conversation.conversation_id!.id
        print("Adding new conversation: \(conv_id)")
        let conv = Conversation(client: client, user_list: user_list, client_conversation: client_conversation, client_events: client_events)
        conv_dict[conv_id as String] = conv
        return conv
    }

    func leave_conversation(conv_id: String) {
        // Leave conversation and remove it from ConversationList
        print("Leaving conversation: \(conv_id)")
        conv_dict[conv_id]!.leave {
            conv_dict.removeValueForKey(conv_id)
        }
    }

    func on_client_event(event: CLIENT_EVENT) {
        // Receive a ClientEvent and fan out to Conversations
        sync_timestamp = from_timestamp(event.timestamp)
        if let conv = conv_dict[event.conversation_id.id as String] {
            let conv_event = conv.add_event(event)

            delegate?.conversationList(self, didReceiveEvent: conv_event)
            conv.delegate?.conversation(conv, didReceiveEvent: conv_event)
        } else {
            print("Received ClientEvent for unknown conversation \(event.conversation_id.id)")
        }
    }

    func handle_client_conversation(client_conversation: CLIENT_CONVERSATION) {
        // Receive ClientConversation and create or update the conversation
        let conv_id = client_conversation.conversation_id!.id
        if let conv = conv_dict[conv_id as String] {
            conv.update_conversation(client_conversation)
        } else {
            self.add_conversation(client_conversation)
        }
    }

    func handle_set_typing_notification(set_typing_notification: CLIENT_SET_TYPING_NOTIFICATION) {
        // Receive ClientSetTypingNotification and update the conversation
        let conv_id = set_typing_notification.conversation_id.id
        if let conv = conv_dict[conv_id as String] {
            let res = parse_typing_status_message(set_typing_notification)
            delegate?.conversationList(self, didChangeTypingStatusTo: res.status)
            conv.delegate?.conversation(conv, didChangeTypingStatusTo: res.status)
        } else {
            print("Received ClientSetTypingNotification for unknown conversation \(conv_id)")
        }
    }

    func handle_watermark_notification(watermark_notification: CLIENT_WATERMARK_NOTIFICATION) {
        // Receive ClientWatermarkNotification and update the conversation
        let conv_id = watermark_notification.conversation_id.id
        if let conv = conv_dict[conv_id as String] {
            let res = parse_watermark_notification(watermark_notification)
            delegate?.conversationList(self, didReceiveWatermarkNotification: res)
            conv.delegate?.conversation(conv, didReceiveWatermarkNotification: res)
        } else {
            print("Received WatermarkNotification for unknown conversation \(conv_id)")
        }
    }

    func sync(cb: (() -> Void)? = nil) {
        // Sync conversation state and events that could have been missed
        print("Syncing events since \(sync_timestamp)")
        client.syncAllNewEvents(sync_timestamp) { res in
            if let response = res {
                for conv_state in response.conversation_state {
                    if let conv = self.conv_dict[conv_state.conversation_id.id as String] {
                        conv.update_conversation(conv_state.conversation)
                        for event in conv_state.event {
                            let timestamp = from_timestamp(event.timestamp)
                            if timestamp.compare(self.sync_timestamp) == NSComparisonResult.OrderedDescending {
                                // This updates the sync_timestamp for us, as well
                                // as triggering events.
                                self.on_client_event(event)
                            }
                        }
                    } else {
                        self.add_conversation(conv_state.conversation, client_events: conv_state.event)
                    }
                }
            }
        }
    }

    func clientDidConnect(client: Client, initialData: InitialData) {
        sync()
    }

    func clientDidDisconnect(client: Client) {
    }

    func clientDidReconnect(client: Client) {
        sync()
    }

    func clientDidUpdateState(client: Client, update: CLIENT_STATE_UPDATE) {
        // Receive a ClientStateUpdate and fan out to Conversations
        if let client_conversation = update.client_conversation {
            handle_client_conversation(client_conversation)
        }

        if let typing_notification = update.typing_notification {
            handle_set_typing_notification(typing_notification)
        }
        if let watermark_notification = update.watermark_notification {
            handle_watermark_notification(watermark_notification)
        }
        if let event_notification = update.event_notification {
            on_client_event(event_notification.event)
        }
    }
}