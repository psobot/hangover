//
//  Schema.swift
//  Hangover
//
//  Created by Peter Sobot on 6/2/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation

class Enum : NSObject, Equatable, IntegerLiteralConvertible {
    let representation: NSNumber
    required init(value: NSNumber) {
        self.representation = value
    }

    convenience override init() {
        self.init(value: -1)
    }

    required init(integerLiteral value: IntegerLiteralType) {
        self.representation = value
    }
}

func ==(lhs: Enum, rhs: Enum) -> Bool {
    return lhs.representation == rhs.representation
}

/*
 * Enums
 */
class TypingStatus : Enum {
    static let TYPING: TypingStatus = 1 // The user started typing
    static let PAUSED: TypingStatus = 2 // The user stopped typing with inputted text
    static let STOPPED: TypingStatus = 3 // The user stopped typing with no inputted text
}

class ConversationType : Enum {
    static let STICKY_ONE_TO_ONE: ConversationType = 1
    static let GROUP: ConversationType = 2
}

/*
 *  PBLite Messages
 */

class CONVERSATION_ID : Message {
    var id_: NSString = ""
}

class USER_ID : Message {
    var gaia_id: NSString = ""
    var chat_id: NSString = ""
}

class CLIENT_SET_TYPING_NOTIFICATION : Message {
    var conversation_id = CONVERSATION_ID()
    var user_id = USER_ID()
    var timestamp: NSString = ""
    var status: NSNumber = 0
}

class CLIENT_SET_FOCUS_NOTIFICATION : Message {
    var conversation_id = CONVERSATION_ID()
    var user_id = USER_ID()
    var timestamp: NSString = ""
    var status: NSNumber = 0
    var device: NSNumber = 0
}

class CLIENT_CONVERSATION : Message {
    var conversation_id = CONVERSATION_ID()
    var type_ = ConversationType()
    var name: NSString?

    class STATE : Message {
        var field1: OptionalField = nil
        var field2: OptionalField = nil
        var field3: OptionalField = nil
        var field4: OptionalField = nil
        var field5: OptionalField = nil
        var field6: OptionalField = nil

        class READ_STATE : Message {
            var participant_id = USER_ID()
            var latest_read_timestamp: NSString = ""
        }
        var self_read_state = READ_STATE()

        var status: NSNumber = 0 // ClientConversationStatus,
        var notification_level: NSNumber = 0 // ClientNotificationLevel

        var view = NSArray() // [ClientConversationView]

        var inviter_id = USER_ID()
        var invite_timestamp: NSString = ""
        var sort_timestamp: NSString?
        var active_timestamp: NSString?

        var field7: OptionalField = nil
        var field8: OptionalField = nil
        var field9: OptionalField = nil
        var field10: OptionalField = nil
    }

    var self_conversation_state = STATE()
    var field1: OptionalField = nil
    var field2: OptionalField = nil
    var field3: OptionalField = nil

    class READ_STATE : Message {
        var participant_id = USER_ID()
        var last_read_timestamp: NSString = ""
    }

    var read_state = NSArray() // [READ_STATE]
    var field4: OptionalField = nil
    var otr_status: NSNumber = 0 // OffTheRecordStatus
    var field5: OptionalField = nil
    var field6: OptionalField = nil
    var current_participant = NSArray() // [USER_ID]

    class PARTICIPANT_DATA : Message {
        var id_ = USER_ID()
        var fallback_name: NSString?
        var field: OptionalField = nil
    }
    var participant_data = NSArray() // [PARTICIPANT_DATA]

    var field7: OptionalField = nil
    var field8: OptionalField = nil
    var field9: OptionalField = nil
    var field10: OptionalField = nil
    var field11: OptionalField = nil
}

class MESSAGE_SEGMENT : Message {
    var type_: NSNumber = 0 // SegmentType
    var text: NSString?

    class FORMATTING : Message {
        var bold: NSString?
        var italic: NSString?
        var strikethrough: NSString?
        var underline: NSString?
    }
    var formatting: FORMATTING? = FORMATTING()

    class LINK_DATA : Message {
        var link_target: NSString?
    }
    var link_data: LINK_DATA? = LINK_DATA()
}

//MESSAGE_ATTACHMENT = Message(
//    ('embed_item', Message(
//        # 249 (PLUS_PHOTO), 340, 335, 0
//        ('type_', RepeatedField(Field())),
//        ('data', Field()),  # can be a dict
//    )),
//)

//CLIENT_CHAT_MESSAGE = Message(
//    (None, Field(is_optional=True)),  # always None?
//    ('annotation', RepeatedField(Field(), is_optional=True)),
//('message_content', Message(
//('segment', RepeatedField(MESSAGE_SEGMENT, is_optional=True)),
//('attachment', RepeatedField(MESSAGE_ATTACHMENT, is_optional=True)),
//)),
//is_optional=True,
//)
//
//CLIENT_CONVERSATION_RENAME = Message(
//('new_name', Field()),
//('old_name', Field()),
//is_optional=True,
//)
//
//CLIENT_HANGOUT_EVENT = Message(
//('event_type', EnumField(ClientHangoutEventType)),
//('participant_id', RepeatedField(USER_ID)),
//('hangout_duration_secs', Field(is_optional=True)),
//('transferred_conversation_id', Field(is_optional=True)),  # always None?
//('refresh_timeout_secs', Field(is_optional=True)),
//('is_periodic_refresh', Field(is_optional=True)),
//(None, Field(is_optional=True)),  # always 1?
//is_optional=True,
//)
//
//CLIENT_OTR_MODIFICATION = Message(
//('old_otr_status', EnumField(OffTheRecordStatus)),
//('new_otr_status', EnumField(OffTheRecordStatus)),
//('old_otr_toggle', EnumField(ClientOffTheRecordToggle)),
//('new_otr_toggle', EnumField(ClientOffTheRecordToggle)),
//is_optional=True,
//)
//
//CLIENT_MEMBERSHIP_CHANGE = Message(
//('type_', EnumField(MembershipChangeType)),
//(None, RepeatedField(Field())),
//('participant_ids', RepeatedField(USER_ID)),
//(None, Field()),
//is_optional=True,
//)
//
//CLIENT_EVENT = Message(
//('conversation_id', CONVERSATION_ID),
//('sender_id', OPTIONAL_USER_ID),
//('timestamp', Field()),
//('self_event_state', Message(
//('user_id', USER_ID),
//('client_generated_id', Field(is_optional=True)),
//('notification_level', EnumField(ClientNotificationLevel)),
//is_optional=True,
//)),
//(None, Field(is_optional=True)),  # always None?
//(None, Field(is_optional=True)),  # always 0? (expiration_timestamp?)
//('chat_message', CLIENT_CHAT_MESSAGE),
//(None, Field(is_optional=True)),  # always None?
//('membership_change', CLIENT_MEMBERSHIP_CHANGE),
//('conversation_rename', CLIENT_CONVERSATION_RENAME),
//('hangout_event', CLIENT_HANGOUT_EVENT),
//('event_id', Field(is_optional=True)),
//('advances_sort_timestamp', Field(is_optional=True)),
//('otr_modification', CLIENT_OTR_MODIFICATION),
//(None, Field(is_optional=True)),  # 0, 1 or None? related to notifications?
//('event_otr', EnumField(OffTheRecordStatus)),
//(None, Field()),  # always 1? (advances_sort_timestamp?)
//)
//
//CLIENT_EVENT_NOTIFICATION = Message(
//('event', CLIENT_EVENT),
//is_optional=True,
//)
//
//CLIENT_WATERMARK_NOTIFICATION = Message(
//('participant_id', USER_ID),
//('conversation_id', CONVERSATION_ID),
//('latest_read_timestamp', Field()),
//is_optional=True,
//)
//
//CLIENT_STATE_UPDATE_HEADER = Message(
//('active_client_state', EnumField(ActiveClientState)),
//(None, Field(is_optional=True)),
//('request_trace_id', Field()),
//(None, Field(is_optional=True)),
//('current_server_time', Field()),
//(None, Field(is_optional=True)),
//(None, Field(is_optional=True)),
//# optional ID of the client causing the update?
//(None, Field(is_optional=True)),
//)
//
//CLIENT_STATE_UPDATE = Message(
//('state_update_header', CLIENT_STATE_UPDATE_HEADER),
//('conversation_notification', Field(is_optional=True)),  # always None?
//('event_notification', CLIENT_EVENT_NOTIFICATION),
//('focus_notification', CLIENT_SET_FOCUS_NOTIFICATION),
//('typing_notification', CLIENT_SET_TYPING_NOTIFICATION),
//('notification_level_notification', Field(is_optional=True)),
//('reply_to_invite_notification', Field(is_optional=True)),
//('watermark_notification', CLIENT_WATERMARK_NOTIFICATION),
//(None, Field(is_optional=True)),
//('settings_notification', Field(is_optional=True)),
//('view_modification', Field(is_optional=True)),
//('easter_egg_notification', Field(is_optional=True)),
//('client_conversation', CLIENT_CONVERSATION),
//('self_presence_notification', Field(is_optional=True)),
//('delete_notification', Field(is_optional=True)),
//('presence_notification', Field(is_optional=True)),
//('block_notification', Field(is_optional=True)),
//('invitation_watermark_notification', Field(is_optional=True)),
//)
//
//CLIENT_EVENT_CONTINUATION_TOKEN = Message(
//('event_id', Field(is_optional=True)),
//('storage_continuation_token', Field()),
//('event_timestamp', Field()),
//is_optional=True,
//)
//
//CLIENT_CONVERSATION_STATE = Message(
//('conversation_id', CONVERSATION_ID),
//('conversation', CLIENT_CONVERSATION),
//('event', RepeatedField(CLIENT_EVENT)),
//(None, Field(is_optional=True)),
//('event_continuation_token', CLIENT_EVENT_CONTINUATION_TOKEN),
//(None, Field(is_optional=True)),
//(None, RepeatedField(Field())),
//)
//
//CLIENT_CONVERSATION_STATE_LIST = RepeatedField(CLIENT_CONVERSATION_STATE)

class CLIENT_ENTITY : Message {
    var field1: OptionalField = nil
    var field2: OptionalField = nil
    var field3: OptionalField = nil
    var field4: OptionalField = nil
    var field5: OptionalField = nil
    var field6: OptionalField = nil
    var field7: OptionalField = nil
    var field8: OptionalField = nil
    var id_ = USER_ID()

    class PROPERTIES : Message {
        var type_: NSNumber?
        var display_name: NSString?
        var first_name: NSString?
        var photo_url: NSString?
        var emails = NSArray()
    }

    var properties = PROPERTIES()
}

//ENTITY_GROUP = Message(
//    (None, Field()),  # always 0?
//    (None, Field()),  # some sort of ID
//    ('entity', RepeatedField(Message(
//        ('entity', CLIENT_ENTITY),
//        (None, Field()),  # always 0?
//    ))),
//)

//INITIAL_CLIENT_ENTITIES = Message(
//    (None, Field()),  # 'cgserp'
//    (None, Field()),  # a header
//    ('entities', RepeatedField(CLIENT_ENTITY)),
//(None, Field(is_optional=True)),  # always None?
//('group1', ENTITY_GROUP),
//('group2', ENTITY_GROUP),
//('group3', ENTITY_GROUP),
//('group4', ENTITY_GROUP),
//('group5', ENTITY_GROUP),
//
//)

class CLIENT_GET_SELF_INFO_RESPONSE : Message {
    var cgsirp: NSString = ""
    var response_header: OptionalField = nil
    var self_entity = CLIENT_ENTITY()
}

//CLIENT_RESPONSE_HEADER = Message(
//    ('status', Field()),  # 1 => success
//    (None, Field(is_optional=True)),
//    (None, Field(is_optional=True)),
//    ('request_trace_id', Field()),
//    ('current_server_time', Field()),
//)
//
//CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE = Message(
//    (None, Field()),  # 'csanerp'
//    ('response_header', CLIENT_RESPONSE_HEADER),
//('sync_timestamp', Field()),
//('conversation_state', RepeatedField(CLIENT_CONVERSATION_STATE)),
//)
//
//CLIENT_GET_CONVERSATION_RESPONSE = Message(
//(None, Field()),  # 'cgcrp'
//('response_header', CLIENT_RESPONSE_HEADER),
//('conversation_state', CLIENT_CONVERSATION_STATE),
//)
//
//CLIENT_GET_ENTITY_BY_ID_RESPONSE = Message(
//(None, Field()),  # 'cgebirp'
//('response_header', CLIENT_RESPONSE_HEADER),
//('entities', RepeatedField(CLIENT_ENTITY)),
//)
