//
//  ConversationEvent.swift
//  Hangover
//
//  Created by Peter Sobot on 6/8/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Foundation

struct UserID : Hashable {
    let chat_id: String
    let gaia_id: String

    var hashValue: Int {
        get {
            return chat_id.hashValue ^ gaia_id.hashValue
        }
    }
}

func ==(lhs: UserID, rhs: UserID) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

class ConversationEvent {
    // An event which becomes part of the permanent record of a conversation.
    // This corresponds to ClientEvent in the API.
    // This is the base class for such events.
    let event: CLIENT_EVENT

    init(client_event: CLIENT_EVENT) {
        event = client_event
    }

    var timestamp: NSDate {
        get {
            // A timestamp of when the event occurred.
            return from_timestamp(self.event.timestamp)
        }
    }

    var user_id: UserID {
        get {
            // A UserID indicating who created the event.
            return UserID(
                chat_id: self.event.sender_id!.chat_id as String,
                gaia_id: self.event.sender_id!.gaia_id as String
            )
        }
    }

    var conversation_id: NSString {
        get {
            // The ID of the conversation the event belongs to.
            return self.event.conversation_id.id
        }
    }

    var id: Conversation.EventID {
        get {
            // The ID of the ConversationEvent.
            return self.event.event_id! as Conversation.EventID
        }
    }
}

class ChatMessageSegment {
    let type: SegmentType
    let text: String
    let is_bold: Bool
    let is_italic: Bool
    let is_strikethrough: Bool
    let is_underline: Bool
    let link_target: String?

    // A segment of a chat message.
    init(text: String,
        segment_type: SegmentType?=nil,
        is_bold: Bool=false,
        is_italic: Bool=false,
        is_strikethrough: Bool=false,
        is_underline: Bool=false,
        link_target: String?=nil
    ) {
        // Create a new chat message segment.
        if let type = segment_type {
            self.type = type
        } else if link_target != nil {
            self.type = SegmentType.LINK
        } else {
            self.type = SegmentType.TEXT
        }

        self.text = text
        self.is_bold = is_bold
        self.is_italic = is_italic
        self.is_strikethrough = is_strikethrough
        self.is_underline = is_underline
        self.link_target = link_target
    }

    // static func from_str(string: text) -> [ChatMessageSegment] {
    //     // Generate ChatMessageSegment list parsed from a string.
    //     // This method handles automatically finding line breaks, URLs and
    //     // parsing simple formatting markup (simplified Markdown and HTML).

    //     segment_list = chat_message_parser.parse(text)
    //     return [ChatMessageSegment(segment.text, **segment.params) for segment in segment_list]
    // }

    init(segment: MESSAGE_SEGMENT) {
        // Create a chat message segment from a parsed MESSAGE_SEGMENT.

        text = segment.text! as String
        type = segment.type_
        // The formatting options are optional.
        is_bold = segment.formatting?.bold?.boolValue ?? false
        is_italic = segment.formatting?.italic?.boolValue ?? false
        is_strikethrough = segment.formatting?.strikethrough?.boolValue ?? false
        is_underline = segment.formatting?.underline?.boolValue ?? false
        link_target = (segment.link_data?.link_target as String?) ?? nil
    }

    func serialize() -> NSArray {
        // Serialize the segment to pblite.
        return [self.type.representation, self.text, [
            self.is_bold ? 1 : 0,
            self.is_italic ? 1 : 0,
            self.is_strikethrough ? 1 : 0,
            self.is_underline ? 1 : 0,
            ], [self.link_target ?? NSNull()]]
    }
}

class ChatMessageEvent : ConversationEvent {
    // An event containing a chat message.
    // Corresponds to ClientChatMessage in the API.

    var text: String {
        get {
            // A textual representation of the message.
            var lines = [""]
            for segment in self.segments {
                if segment.type == SegmentType.TEXT {
                    lines[-1] += segment.text
                } else if segment.type == SegmentType.LINK {
                    lines[-1] += segment.text
                } else if segment.type == SegmentType.LINE_BREAK {
                    lines.append("")
                } else {
                    print("Ignoring unknown chat message segment type: \(segment.type)")
                }
            }
            lines += self.attachments
            return "\n".join(lines)
        }
    }

    var segments: [ChatMessageSegment] {
        get {
            // List of ChatMessageSegments in the message.
            if let list = self.event.chat_message?.message_content.segment {
                return list.map { ChatMessageSegment(segment: $0) }
            } else {
                return []
            }
        }
    }

    var attachments: [String] {
        get {
            // Attachments in the message.
            let raw_attachments = self.event.chat_message?.message_content.attachment ?? [MESSAGE_ATTACHMENT]()
            var attachments = [String]()
            for attachment in raw_attachments {
                if attachment.embed_item.type_ == [249] { // PLUS_PHOTO
                    // Try to parse an image message. Image messages contain no
                    // message segments, and thus have no automatic textual
                    // fallback.
                    if let data = attachment.embed_item.data["27639957"] as? NSArray,
                        zeroth = data[0] as? NSArray,
                        third = zeroth[3] as? String {
                            attachments.append(third)
                    }
                } else if attachment.embed_item.type_ == [340, 335, 0] {
                    // Google Maps URL that's already in the text.
                } else {
                    print("Ignoring unknown chat message attachment: \(attachment)")
                }
            }
            return attachments
        }
    }
}

class RenameEvent : ConversationEvent {
    // An event that renames a conversation.
    // Corresponds to ClientConversationRename in the API.

    var new_name: String {
        get {
            // The conversation's new name.
            // An empty string if the conversation's name was cleared.
            return self.event.conversation_rename!.new_name as String
        }
    }

    var old_name: String {
        get {
            // The conversation's old name.
            // An empty string if the conversation had no previous name.
            return self.event.conversation_rename!.old_name as String
        }
    }
}

class MembershipChangeEvent : ConversationEvent {

    // An event that adds or removes a conversation participant.
    // Corresponds to ClientMembershipChange in the API.

    var type: MembershipChangeType {
        get {
            // The membership change type (MembershipChangeType).
            return self.event.membership_change!.type_
        }
    }

    var participant_ids: [UserID] {
        get {
            // Return the UserIDs involved in the membership change.
            // Multiple users may be added to a conversation at the same time.
            return self.event.membership_change!.participant_ids.map {
                UserID(chat_id: $0.chat_id as String, gaia_id: $0.gaia_id as String)
            }
        }
    }
}