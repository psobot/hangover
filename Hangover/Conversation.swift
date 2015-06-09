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

//    var client: Client
//    var user_list: UserList
//    var conversation: ClientConversation
//    var events = [ConversationEvent]()
//    var events_dict = Dictionary<EventID, ConversationEvent>()
//    var send_message_lock = false//asyncio.Lock()
//
//    init(client, user_list, client_conversation, client_events=[]) {
//        // Initialize a new Conversation.
//        for event_ in client_events:
//        self.add_event(event_)
//    }
//
//    func _on_watermark_notification(notif) {
//        // Update the conversations latest_read_timestamp.
//        if self.get_user(notif.user_id).is_self:
//        logger.info('latest_read_timestamp for {} updated to {}'
//        .format(self.id_, notif.read_timestamp))
//        self_conversation_state = (
//        self._conversation.self_conversation_state
//        )
//        self_conversation_state.self_read_state.latest_read_timestamp = (
//        to_timestamp(notif.read_timestamp)
//        )
//    }
//
//    func update_conversation(client_conversation) {
//        // Update the internal ClientConversation.
//        // When latest_read_timestamp is 0, this seems to indicate no change
//        // from the previous value. Word around this by saving and restoring the
//        // previous value.
//        old_timestamp = self.latest_read_timestamp
//        self._conversation = client_conversation
//        if to_timestamp(self.latest_read_timestamp) == 0 {
//            self_conversation_state = (
//                self._conversation.self_conversation_state
//            )
//            self_conversation_state.self_read_state.latest_read_timestamp = (
//                to_timestamp(old_timestamp)
//            )
//        }
//    }
//
//    class func _wrap_event(event_: ClientEvent) -> ConversationEvent {
//        // Wrap ClientEvent in ConversationEvent subclass.
//        if event_.chat_message != nil {
//            return conversation_event.ChatMessageEvent(event_)
//        } else if event_.conversation_rename != nil {
//            return conversation_event.RenameEvent(event_)
//        } else if event_.membership_change != nil {
//            return conversation_event.MembershipChangeEvent(event_)
//        } else {
//            return conversation_event.ConversationEvent(event_)
//        }
//    }
//
//    func add_event(event_) -> ConversationEvent {
//        // Add a ClientEvent to the Conversation.
//        // Returns an instance of ConversationEvent or subclass.
//        let conv_event = self._wrap_event(event_)
//        self._events.append(conv_event)
//        self._events_dict[conv_event.id_] = conv_event
//        return conv_event
//    }
//
//    func get_user(user_id) -> User {
//        // Return the User instance with the given UserID.
//        return self._user_list.get_user(user_id)
//    }
//
//    func send_message(segments, image_file=None, image_id=None, cb: (() -> Void)?) {
//        // Send a message to this conversation.
//
//        // A per-conversation lock is acquired to ensure that messages are sent in
//        // the correct order when this method is called multiple times
//        // asynchronously.
//
//        // segments is a list of ChatMessageSegments to include in the message.
//
//        // image_file is an optional file-like object containing an image to be
//        // attached to the message.
//
//        // image_id is an optional ID of an image to be attached to the message
//        // (if you specify both image_file and image_id together, image_file
//        // takes precedence and supplied image_id will be ignored)
//
//        with (yield from self._send_message_lock) {
//            // Send messages with OTR status matching the conversation's status.
//            otr_status = (OffTheRecordStatus.OFF_THE_RECORD
//                if self.is_off_the_record
//                else OffTheRecordStatus.ON_THE_RECORD)
//            if image_file {
//                image_id = self._client.upload_image(image_file) {
//                    self.send_message(segments, nil, image_id, cb)
//                }
//                return
//            }
//
//            self._client.sendchatmessage(
//                self.id_, segments.map { $0.serialize },
//                image_id=image_id, otr_status=otr_status, cb
//            )
//        }
//
//        func leave(cb: (() -> Void)?) {
//            // Leave conversation.
//            if self._conversation.type_ == ConversationType.GROUP {}
//            self._client.removeUser(self.id_, cb)
//        } else {
//            self._client.deleteConversation(self.id_, cb)
//        }
//    }
//
//    func rename(name, cb: (() -> Void)?) {
//        // Rename the conversation.
//
//        // Hangouts only officially supports renaming group conversations, so
//        // custom names for one-to-one conversations may or may not appear in all
//        // first party clients.
//        self._client.setchatname(self.id_, name, cb)
//    }
//
//    func set_notification_level(level, cb: (() -> Void)?) {
//        // Set the notification level of the conversation.
//        // Pass ClientNotificationLevel.QUIET to disable notifications,
//        // or ClientNotificationLevel.RING to enable them.
//        self._client.setconversationnotificationlevel(self.id_, level, cb)
//    }
//
//    func set_typing(typing: TypingStatus=TypingStatus.TYPING, cb: (() -> Void)?=nil) {
//        // Set typing status.
//        // TODO: Add rate-limiting to avoid unnecessary requests.
//        client?.setTyping(id_, typing, cb)
//    }
//
//    func update_read_timestamp(read_timestamp: NSDate?=nil, cb: (() -> Void)?=nil) {
//        // Update the timestamp of the latest event which has been read.
//        // By default, the timestamp of the newest event is used.
//        // This method will avoid making an API request if it will have no effect.
//
//        if read_timestamp is None {
//            read_timestamp = self.events[-1].timestamp
//        }
//
//        if read_timestamp > self.latest_read_timestamp {
//            logger.info(
//                'Setting {} latest_read_timestamp from {} to {}'
//                .format(self.id_, self.latest_read_timestamp, read_timestamp)
//            )
//            // Prevent duplicate requests by updating the conversation now.
//            state = self._conversation.self_conversation_state
//            state.self_read_state.latest_read_timestamp = (
//                to_timestamp(read_timestamp)
//            )
//            self._client.updatewatermark(self.id_, read_timestamp, cb)
//        }
//    }
//
//    func get_events(event_id=None, max_events=50, cb: (() -> Void)?) {
//        // Return list of ConversationEvents ordered newest-first.
//        // If event_id is specified, return events preceeding this event.
//        // This method will make an API request to load historical events if
//        // necessary. If the beginning of the conversation is reached, an empty
//        // list will be returned.
//
//        if event_id is None:
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
//        res = yield from self._client.getconversation(
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
//            // Return None if there is no following event.
//
//            i = self.events.index(self._events_dict[event_id])
//            if prev and i > 0:
//            return self.events[i - 1]
//            elif not prev and i + 1 < len(self.events) {
//                return self.events[i + 1]
//                else:
//                return None
//            }
//        }
//
//        func get_event(event_id: EventID) -> ConversationEvent {
//            return events_dict[event_id]
//        }
//
//        var id_ {
//            get {
//                // The conversation's ID.
//                return self._conversation.conversation_id.id_
//            }
//        }
//
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
//                // The conversation's custom name, or None if it doesn't have one.
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
//
//        var latest_read_timestamp {
//            get {
//                // datetime timestamp of the last read ConversationEvent.
//                timestamp = (self._conversation.self_conversation_state.
//                    self_read_state.latest_read_timestamp)
//                return from_timestamp(timestamp)
//            }
//        }
//
//        var events {
//            get {
//                // The list of ConversationEvents, sorted oldest to newest.
//                return list(self._events)
//            }
//        }
//
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
//
//        var is_archived {
//            get {
//                // True if this conversation has been archived.
//                return (ClientConversationView.ARCHIVED_VIEW in
//                    self._conversation.self_conversation_state.view)
//            }
//        }
//        
//        var is_quiet { 
//            get {
//                // True if notification level for this conversation is quiet.
//                level = self._conversation.self_conversation_state.notification_level
//                return level == ClientNotificationLevel.QUIET
//            }
//        }
//        
//        var is_off_the_record { 
//            get {
//                // True if conversation is off the record (history is disabled).
//                status = self._conversation.otr_status
//                return status == OffTheRecordStatus.OFF_THE_RECORD
//            }
//        }
}