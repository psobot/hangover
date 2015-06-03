//
//  Schema.swift
//  Hangover
//
//  Created by Peter Sobot on 6/2/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation

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
    var type_: NSNumber = 0 // ConversationType
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

class CLIENT_GET_SELF_INFO_RESPONSE : Message {
    var cgsirp: NSString = ""
    var response_header: OptionalField = nil
    var self_entity = CLIENT_ENTITY()
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
