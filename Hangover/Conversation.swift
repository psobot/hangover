//
//  Conversation.swift
//  Hangover
//
//  Created by Peter Sobot on 6/7/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation

protocol ConversationDelegate {
    func conversation(conversation: Conversation, didChangeTypingStatusTo: TypingStatus)
    func conversation(conversation: Conversation, didReceiveEvent: ConversationEvent)
    func conversation(conversation: Conversation, didReceiveWatermarkNotification: WatermarkNotification)
}

class Conversation {
    // Wrapper around Client for working with a single chat conversation.

    typealias EventID = String

    var client: Client
    var user_list: UserList
    var conversation: CLIENT_CONVERSATION
    var events = [ConversationEvent]()
    var events_dict = Dictionary<EventID, ConversationEvent>()

    var delegate: ConversationDelegate?

    init(client: Client,
        user_list: UserList,
        client_conversation: CLIENT_CONVERSATION,
        client_events: [CLIENT_EVENT] = []
    ) {
        self.client = client
        self.user_list = user_list
        self.conversation = client_conversation

        for event in client_events {
            add_event(event)
        }
    }

    func on_watermark_notification(notif: WatermarkNotification) {
        // Update the conversations latest_read_timestamp.
        if self.get_user(notif.user_id).is_self {
            print("latest_read_timestamp for \(self.id) updated to \(notif.read_timestamp)")
            self.conversation.self_conversation_state.self_read_state.latest_read_timestamp = to_timestamp(notif.read_timestamp)
        }
    }

    func update_conversation(client_conversation: CLIENT_CONVERSATION) {
        // Update the internal ClientConversation.
        // When latest_read_timestamp is 0, this seems to indicate no change
        // from the previous value. Word around this by saving and restoring the
        // previous value.

        let old_timestamp = self.latest_read_timestamp
        self.conversation = client_conversation
        
        if to_timestamp(self.latest_read_timestamp) == 0 {
            self.conversation.self_conversation_state.self_read_state.latest_read_timestamp = (
                to_timestamp(old_timestamp)
            )
        }
    }

    private class func wrap_event(event: CLIENT_EVENT) -> ConversationEvent {
        // Wrap ClientEvent in ConversationEvent subclass.
        if event.chat_message != nil {
            return ChatMessageEvent(client_event: event)
        } else if event.conversation_rename != nil {
            return RenameEvent(client_event: event)
        } else if event.membership_change != nil {
            return MembershipChangeEvent(client_event: event)
        } else {
            return ConversationEvent(client_event: event)
        }
    }

    func add_event(event: CLIENT_EVENT) -> ConversationEvent {
        // Add a ClientEvent to the Conversation.
        // Returns an instance of ConversationEvent or subclass.
        let conv_event = Conversation.wrap_event(event)
        self.events.append(conv_event)
        self.events_dict[conv_event.id] = conv_event
        return conv_event
    }

    func get_user(user_id: UserID) -> User {
        // Return the User instance with the given UserID.
        return self.user_list.get_user(user_id)
    }

    func sendMessage(segments: [ChatMessageSegment],
        image_file: String? = nil,
        image_id: String? = nil,
        cb: (() -> Void)? = nil
    ) {
        // Send a message to this conversation.

        // A per-conversation lock is acquired to ensure that messages are sent in
        // the correct order when this method is called multiple times
        // asynchronously.

        // segments is a list of ChatMessageSegments to include in the message.

        // image_file is an optional file-like object containing an image to be
        // attached to the message.

        // image_id is an optional ID of an image to be attached to the message
        // (if you specify both image_file and image_id together, image_file
        // takes precedence and supplied image_id will be ignored)

        //with (yield from self._send_message_lock) {
        // Send messages with OTR status matching the conversation's status.
        let otr_status = (is_off_the_record ? OffTheRecordStatus.OFF_THE_RECORD : OffTheRecordStatus.ON_THE_RECORD)

        if let image_file = image_file {
            //client.upload_image(image_file) { image_id in
                self.sendMessage(segments, image_file: nil, image_id: image_id, cb: cb)
            //}
            return
        }

        client.sendChatMessage(id,
            segments: segments.map { $0.serialize() },
            image_id: image_id,
            otr_status: otr_status,
            cb: cb
        )
        //}
    }

    func leave(cb: (() -> Void)? = nil) {
        switch (self.conversation.type) {
        case ConversationType.GROUP:
            print("Remove")
            //client.removeUser(id, cb)
        case ConversationType.STICKY_ONE_TO_ONE:
            client.deleteConversation(id, cb: cb)
        default:
            break
        }
    }
    

    func rename(name: String, cb: (() -> Void)?) {
        // Rename the conversation.

        // Hangouts only officially supports renaming group conversations, so
        // custom names for one-to-one conversations may or may not appear in all
        // first party clients.
        self.client.setChatName(self.id, name: name, cb: cb)
    }

//    func set_notification_level(level, cb: (() -> Void)?) {
//        // Set the notification level of the conversation.
//        // Pass ClientNotificationLevel.QUIET to disable notifications,
//        // or ClientNotificationLevel.RING to enable them.
//        self.client.setconversationnotificationlevel(self.id_, level, cb)
//    }

    func set_typing(typing: TypingStatus = TypingStatus.TYPING, cb: (() -> Void)? = nil) {
        // Set typing status.
        // TODO: Add rate-limiting to avoid unnecessary requests.
        client.setTyping(id, typing: typing, cb: cb)
    }

    func updateReadTimestamp(var read_timestamp: NSDate? = nil, cb: (() -> Void)? = nil) {
        // Update the timestamp of the latest event which has been read.
        // By default, the timestamp of the newest event is used.
        // This method will avoid making an API request if it will have no effect.

        if read_timestamp == nil {
            read_timestamp = self.events[-1].timestamp
        }
        if let new_read_timestamp = read_timestamp {
            if new_read_timestamp.compare(self.latest_read_timestamp) == NSComparisonResult.OrderedDescending {
                print("Setting \(id) latest_read_timestamp from \(latest_read_timestamp) to \(read_timestamp)")

                // Prevent duplicate requests by updating the conversation now.
                let state = conversation.self_conversation_state
                state.self_read_state.latest_read_timestamp = to_timestamp(new_read_timestamp)

                client.updateWatermark(id, read_timestamp: new_read_timestamp, cb: cb)
            }
        }
    }

    var messages: [ChatMessageEvent] {
        get {
            return events.flatMap { $0 as? ChatMessageEvent }
        }
    }

//    func get_events(event_id=nil, max_events=50, cb: (() -> Void)?) {
//        // Return list of ConversationEvents ordered newest-first.
//        // If event_id is specified, return events preceeding this event.
//        // This method will make an API request to load historical events if
//        // necessary. If the beginning of the conversation is reached, an empty
//        // list will be returned.
//
//        if event_id is nil:
//        # If no event_id is provided, return the newest events in this
//        # conversation.
//        conv_events = self._events[-1 * max_events:]
//        else:
//        # If event_id is provided, return the events we have that are
//        # older, or request older events if event_id corresponds to the
//        # oldest event we have.
//        conv_event = self.get_event(event_id)
//        if self._events[0].id_ != event_id:
//        conv_events = self._events[self._events.index(conv_event) + 1:]
//        else:
//        logger.info('Loading events for conversation {} before {}'
//        .format(self.id_, conv_event.timestamp))
//        res = yield from self.client.getconversation(
//        self.id_, conv_event.timestamp, max_events
//        )
//        conv_events = [self._wrap_event(client_event) for client_event
//        in res.conversation_state.event]
//        logger.info('Loaded {} events for conversation {}'
//            .format(len(conv_events), self.id_))
//        for conv_event in reversed(conv_events) {
//            self._events.insert(0, conv_event)
//            self._events_dict[conv_event.id_] = conv_event
//            return conv_events
//        }
//
//        func next_event(event_id, prev=False) {
//            // Return ConversationEvent following the event with given event_id.
//            // If prev is True, return the previous event rather than the following
//            // one.
//            // Raises KeyError if no such ConversationEvent is known.
//            // Return nil if there is no following event.
//
//            i = self.events.index(self._events_dict[event_id])
//            if prev and i > 0:
//            return self.events[i - 1]
//            elif not prev and i + 1 < len(self.events) {
//                return self.events[i + 1]
//                else:
//                return nil
//            }
//        }
//
//        func get_event(event_id: EventID) -> ConversationEvent {
//            return events_dict[event_id]
//        }

    var id: String {
        get {
            // The conversation's ID.
            return self.conversation.conversation_id!.id as String
        }
    }

//        var users {
//            get {
//                // User instances of the conversation's current participants.
//                return [self._user_list.get_user(user.UserID(chat_id=part.id_.chat_id,
//                    gaia_id=part.id_.gaia_id))
//                    for part in self._conversation.participant_data]
//            }
//        }
//
//        var name {
//            get {
//                // The conversation's custom name, or nil if it doesn't have one.
//                return self._conversation.name
//            }
//        }
//
//        var last_modified {
//            get {
//                // datetime timestamp of when the conversation was last modified.
//                return from_timestamp(
//                    self._conversation.self_conversation_state.sort_timestamp
//                )
//            }
//        }

    var latest_read_timestamp: NSDate {
        get {
            // datetime timestamp of the last read ConversationEvent.
            return from_timestamp(conversation.self_conversation_state.self_read_state.latest_read_timestamp)
        }
    }

//        var unread_events {
//            get {
//                // List of ConversationEvents that are unread.
//
//                // Events are sorted oldest to newest.
//
//                // Note that some Hangouts clients don't update the read timestamp for
//                // certain event types, such as membership changes, so this method may
//                // return more unread events than these clients will show. There's also a
//                // delay between sending a message and the user's own message being
//                // considered read.
//
//                return [conv_event for conv_event in self._events
//                    if conv_event.timestamp > self.latest_read_timestamp]
//            }
//        }

    var is_archived: Bool {
        get {
            // True if this conversation has been archived.
            return self.conversation.self_conversation_state.view.contains(ClientConversationView.ARCHIVED_VIEW)
        }
    }
    
//        var is_quiet {
//            get {
//                // True if notification level for this conversation is quiet.
//                level = self._conversation.self_conversation_state.notification_level
//                return level == ClientNotificationLevel.QUIET
//            }
//        }
//        
    var is_off_the_record: Bool {
        get {
            // True if conversation is off the record (history is disabled).
            return self.conversation.otr_status == OffTheRecordStatus.OFF_THE_RECORD
        }
    }
}