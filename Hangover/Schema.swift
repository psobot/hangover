//
//  Schema.swift
//  Hangover
//
//  Created by Peter Sobot on 6/2/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation

class Enum : NSObject, IntegerLiteralConvertible {
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

class FocusStatus : Enum {
    static let FOCUSED: FocusStatus = 1
    static let UNFOCUSED: FocusStatus = 2
}

class FocusDevice : Enum {
    static let DESKTOP: FocusDevice = 20
    static let MOBILE: FocusDevice = 300
    static let UNSPECIFIED: FocusDevice? = nil
}

class ConversationType : Enum {
    static let STICKY_ONE_TO_ONE: ConversationType = 1
    static let GROUP: ConversationType = 2
}

class ClientConversationView : Enum {
    static let UNKNOWN_CONVERSATION_VIEW: ClientConversationView = 0
    static let INBOX_VIEW: ClientConversationView = 1
    static let ARCHIVED_VIEW: ClientConversationView = 2
}

class ClientNotificationLevel : Enum {
    static let UNKNOWN: ClientNotificationLevel? = nil
    static let QUIET: ClientNotificationLevel = 10
    static let RING: ClientNotificationLevel = 30
}

class ClientConversationStatus : Enum {
    static let UNKNOWN_CONVERSATION_STATUS: ClientConversationStatus = 0
    static let INVITED: ClientConversationStatus = 1
    static let ACTIVE: ClientConversationStatus = 2
    static let LEFT: ClientConversationStatus = 3
}

class SegmentType : Enum {
    static let TEXT: SegmentType = 0
    static let LINE_BREAK: SegmentType = 1
    static let LINK: SegmentType = 2
}

class MembershipChangeType : Enum {
    static let JOIN: MembershipChangeType = 1
    static let LEAVE: MembershipChangeType = 2
}

class ClientHangoutEventType : Enum {
    static let START_HANGOUT: ClientHangoutEventType = 1
    static let END_HANGOUT: ClientHangoutEventType = 2
    static let JOIN_HANGOUT: ClientHangoutEventType = 3
    static let LEAVE_HANGOUT: ClientHangoutEventType = 4
    static let HANGOUT_COMING_SOON: ClientHangoutEventType = 5
    static let ONGOING_HANGOUT: ClientHangoutEventType = 6
}

class OffTheRecordStatus : Enum {
    static let OFF_THE_RECORD: OffTheRecordStatus = 1
    static let ON_THE_RECORD: OffTheRecordStatus = 2
}

class ClientOffTheRecordToggle : Enum {
    static let ENABLED: ClientOffTheRecordToggle = 0
    static let DISABLED: ClientOffTheRecordToggle = 1
}

class ActiveClientState : Enum {
    static let NO_ACTIVE_CLIENT: ActiveClientState = 0
    static let IS_ACTIVE_CLIENT: ActiveClientState = 1
    static let OTHER_CLIENT_IS_ACTIVE: ActiveClientState = 2
}

/*
 *  PBLite Messages
 */

class CONVERSATION_ID : Message {
    var id: NSString = ""
}

class USER_ID : Message {
    var gaia_id: NSString = ""
    var chat_id: NSString = ""
}

class CLIENT_SET_TYPING_NOTIFICATION : Message {
    var conversation_id = CONVERSATION_ID()
    var user_id = USER_ID()
    var timestamp: NSNumber = 0
    var status: TypingStatus = 0
}

class CLIENT_SET_FOCUS_NOTIFICATION : Message {
    var conversation_id = CONVERSATION_ID()
    var user_id = USER_ID()
    var timestamp: NSString = ""
    var status: FocusStatus = 0
    var device: FocusDevice?
}

class CLIENT_CONVERSATION : Message {
    var conversation_id: CONVERSATION_ID?
    var type = ConversationType()
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
            var latest_read_timestamp: NSNumber = 0 // TODO: Verify this is an NSNumber
        }
        var self_read_state = READ_STATE()

        var status: ClientConversationStatus = 0
        var notification_level: ClientNotificationLevel = 0

        var view = [ClientConversationView]()

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

    var read_state = [READ_STATE]()
    var field4: OptionalField = nil
    var otr_status: OffTheRecordStatus = 0
    var field5: OptionalField = nil
    var field6: OptionalField = nil
    var current_participant = [USER_ID]()

    class PARTICIPANT_DATA : Message {
        var id = USER_ID()
        var fallback_name: NSString?
        var field: OptionalField = nil
    }
    var participant_data = [PARTICIPANT_DATA]()

    var field7: OptionalField = nil
    var field8: OptionalField = nil
    var field9: OptionalField = nil
    var field10: OptionalField = nil
    var field11: OptionalField = nil
}

class MESSAGE_SEGMENT : Message {
    var type_: SegmentType = 0
    var text: NSString?

    class FORMATTING : Message {
        var bold: NSNumber?
        var italic: NSNumber?
        var strikethrough: NSNumber?
        var underline: NSNumber?
    }
    var formatting: FORMATTING? = FORMATTING()

    class LINK_DATA : Message {
        var link_target: NSString?
    }
    var link_data: LINK_DATA? = LINK_DATA()
}

class MESSAGE_ATTACHMENT : Message {
    class EMBED_ITEM : Message {
        var type_ = NSArray()
        var data = NSDictionary()
    }
    var embed_item = EMBED_ITEM()
}

class CLIENT_CHAT_MESSAGE : Message {
    var field1: OptionalField = nil
    var annotation: NSArray?

    class CONTENT : Message {
        var segment: [MESSAGE_SEGMENT]?
        var attachment: [MESSAGE_ATTACHMENT]?
    }

    var message_content = CONTENT()
}

class CLIENT_CONVERSATION_RENAME : Message {
    var new_name: NSString = ""
    var old_name: NSString = ""
}

class CLIENT_HANGOUT_EVENT : Message {
    var event_type: ClientHangoutEventType = 0
    var participant_id = [USER_ID]()
    var hangout_duration_secs: NSNumber?
    var transferred_conversation_id: NSString?
    var refresh_timeout_secs: NSNumber?
    var is_periodic_refresh: NSNumber?
    var field1: OptionalField = nil
}

class CLIENT_OTR_MODIFICATION : Message {
    var old_otr_status :OffTheRecordStatus = 0
    var new_otr_status :OffTheRecordStatus = 0
    var old_otr_toggle :ClientOffTheRecordToggle = 0
    var new_otr_toggle :ClientOffTheRecordToggle = 0
}

class CLIENT_MEMBERSHIP_CHANGE : Message {
    var type_: MembershipChangeType = 0
    var field1 = NSArray()
    var participant_ids = [USER_ID]()
    var field2: OptionalField = nil
}

class CLIENT_EVENT : Message {
    var conversation_id = CONVERSATION_ID()
    var sender_id: USER_ID?
    var timestamp: NSNumber = 0

    class EVENT_STATE : Message {
        var user_id = USER_ID()
        var client_generated_id: OptionalField = nil
        var notification_level: ClientNotificationLevel = 0
    }
    var self_event_state : EVENT_STATE?
    var field1: OptionalField = nil
    var field2: OptionalField = nil
    var chat_message: CLIENT_CHAT_MESSAGE?
    var field3: OptionalField = nil
    var membership_change: CLIENT_MEMBERSHIP_CHANGE?
    var conversation_rename: CLIENT_CONVERSATION_RENAME?
    var hangout_event: CLIENT_HANGOUT_EVENT?
    var event_id: NSString?
    var advances_sort_timestamp: NSNumber?
    var otr_modification: CLIENT_OTR_MODIFICATION?
    var field4: OptionalField = nil
    var event_otr: OffTheRecordStatus = 0
    var field5: OptionalField = nil
}

class CLIENT_EVENT_NOTIFICATION : Message {
    var event = CLIENT_EVENT()
}

class CLIENT_WATERMARK_NOTIFICATION : Message {
    var participant_id = USER_ID()
    var conversation_id = CONVERSATION_ID()
    var latest_read_timestamp: NSNumber = 0
}

class CLIENT_STATE_UPDATE_HEADER : Message {
    var active_client_state: ActiveClientState = 0
    var field1: OptionalField = nil
    var request_trace_id: NSString = ""
    var field2: OptionalField = nil
    var current_server_time: NSString = ""
    var field3: OptionalField = nil
    var field4: OptionalField = nil
    var updating_client_id: OptionalField = nil
}

class CLIENT_STATE_UPDATE : Message {
    var state_update_header = CLIENT_STATE_UPDATE_HEADER()
    var conversation_notification: OptionalField = nil
    var event_notification: CLIENT_EVENT_NOTIFICATION?
    var focus_notification = CLIENT_SET_FOCUS_NOTIFICATION()
    var typing_notification: CLIENT_SET_TYPING_NOTIFICATION?
    var notification_level_notification: OptionalField = nil
    var reply_to_invite_notification: OptionalField = nil
    var watermark_notification: CLIENT_WATERMARK_NOTIFICATION?
    var field1: OptionalField = nil
    var settings_notification: OptionalField = nil
    var view_modification: OptionalField = nil
    var easter_egg_notification: OptionalField = nil
    var client_conversation: CLIENT_CONVERSATION?
    var self_presence_notification: OptionalField = nil
    var delete_notification: OptionalField = nil
    var presence_notification: OptionalField = nil
    var block_notification: OptionalField = nil
    var invitation_watermark_notification: OptionalField = nil
}

class CLIENT_EVENT_CONTINUATION_TOKEN : Message {
    var event_id: NSString?
    var storage_continuation_token: NSString = ""
    var event_timestamp: NSString = ""
}


class CLIENT_CONVERSATION_STATE : Message {
    var conversation_id = CONVERSATION_ID()
    var conversation = CLIENT_CONVERSATION()
    var event = [CLIENT_EVENT]()
    var field1: OptionalField = nil
    var event_continuation_token: CLIENT_EVENT_CONTINUATION_TOKEN?
    var field2: OptionalField = nil
    var field3: OptionalField = nil
}

class CLIENT_ENTITY : Message {
    var field1: OptionalField = nil
    var field2: OptionalField = nil
    var field3: OptionalField = nil
    var field4: OptionalField = nil
    var field5: OptionalField = nil
    var field6: OptionalField = nil
    var field7: OptionalField = nil
    var field8: OptionalField = nil
    var id = USER_ID()

    class PROPERTIES : Message {
        var type_: NSNumber?
        var display_name: NSString?
        var first_name: NSString?
        var photo_url: NSString?
        var emails = NSArray()
    }

    var properties = PROPERTIES()
}

class ENTITY_GROUP : Message {
    var field1: OptionalField = nil
    var some_sort_of_id: OptionalField = nil

    class ENTITY : Message {
        var entity = CLIENT_ENTITY()
        var field1: OptionalField = nil
    }

    var entity = [ENTITY]()
}

class INITIAL_CLIENT_ENTITIES : Message {
    var cgserp: NSString = ""
    var header: OptionalField = nil
    var entities = [CLIENT_ENTITY]()
    var field1: OptionalField = nil
    var group1 = ENTITY_GROUP()
    var group2 = ENTITY_GROUP()
    var group3 = ENTITY_GROUP()
    var group4 = ENTITY_GROUP()
    var group5 = ENTITY_GROUP()
}

class CLIENT_GET_SELF_INFO_RESPONSE : Message {
    var cgsirp: NSString = ""
    var response_header: OptionalField = nil
    var self_entity = CLIENT_ENTITY()
}

class CLIENT_RESPONSE_HEADER : Message {
    var status: NSString = ""
    var field1: OptionalField = nil
    var field2: OptionalField = nil
    var request_trace_id: NSString = ""
    var current_server_time: NSString = ""
}

class CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE : Message {
    var csanerp: NSString = ""
    var response_header = CLIENT_RESPONSE_HEADER()
    var sync_timestamp: NSString = ""
    var conversation_state = [CLIENT_CONVERSATION_STATE]()
}

class CLIENT_GET_CONVERSATION_RESPONSE : Message {
    var cgcrp: NSString = ""
    var response_header = CLIENT_RESPONSE_HEADER()
    var conversation_state = CLIENT_CONVERSATION_STATE()
}

class CLIENT_GET_ENTITY_BY_ID_RESPONSE : Message {
    var cgebirp: NSString = ""
    var response_header = CLIENT_RESPONSE_HEADER()
    var entities = [CLIENT_ENTITY]()
}
