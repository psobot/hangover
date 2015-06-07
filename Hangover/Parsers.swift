//
//  Parsers.swift
//  Hangover
//
//  Created by Peter Sobot on 6/5/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation
import JavaScriptCore

func parse_submission(submission: String) -> (client_id: String?, updates: [CLIENT_STATE_UPDATE]) {
    // Yield ClientStateUpdate instances from a channel submission.
    // For each submission payload, yield its messages
    let result = _get_submission_payloads(submission)
    let parsed_submissions = result.updates.flatMap { _parse_payload($0) }
    return (client_id: result.client_id, updates: parsed_submissions)
}


func _get_submission_payloads(submission: String) -> (client_id: String?, updates: [[AnyObject]]) {
    // Yield a submission's payloads.
    // Most submissions only contain one payload, but if the long-polling
    // connection was closed while something happened, there can be multiple
    // payloads.
    let result = JSContext().evaluateScript("a = " + submission)
    let nullResult: (client_id: String?, updates: [[AnyObject]]) = (nil, [])
    let r: [(client_id: String?, updates: [[AnyObject]])] = result.toArray().map { sub in
        if (((sub as! NSArray)[1] as! NSArray)[0] as? String) != "noop" {
            let script = ((sub[1] as! NSArray)[0] as! NSDictionary)["p"] as! String
            let wrapper = JSContext().evaluateScript("a = " + script).toDictionary()
            if let wrapper3 = wrapper["3"] as? NSDictionary {
                if let wrapper32 = wrapper3["2"] as? String {
                    return (client_id: wrapper32, updates: [])
                }
            }
            if let wrapper2 = wrapper["2"] as? NSDictionary {
                if let wrapper22 = wrapper2["2"] as? String {
                    let updates = JSContext().evaluateScript("a = " + wrapper22).toArray()
                    return (client_id: nil, updates: [updates as [AnyObject]])
                }
            }
        }
        return (nil, [])
    }
    return reduce(r, nullResult) { (($1.client_id != nil ? $1.client_id : $0.client_id), $0.updates + $1.updates)  }
}

func flatMap<A,B>(x: [A], y: A -> B?) -> [B] {
    return x.map { y($0) }.filter { $0 != nil }.map { $0! }
}

func _parse_payload(payload: [AnyObject]) -> [CLIENT_STATE_UPDATE] {
    // Yield a list of ClientStateUpdates.
    if payload[0] as? String == "cbu" {
        // payload[1] is a list of state updates.
        return flatMap(payload[1] as! [NSArray]) { CLIENT_STATE_UPDATE.parse($0) }
    } else {
        println("Ignoring payload with header: \(payload[0])")
        return []
    }
}

//##############################################################################
//# Message parsing utils
//##############################################################################
//
//
//def from_timestamp(microsecond_timestamp):
//"""Convert a microsecond timestamp to a UTC datetime instance."""
//# Create datetime without losing precision from floating point (yes, this
//# is actually needed):
//return datetime.datetime.fromtimestamp(
//    microsecond_timestamp // 1000000, datetime.timezone.utc
//    ).replace(microsecond=(microsecond_timestamp % 1000000))
//
//
func to_timestamp(date: NSDate) -> NSNumber {
    // Convert UTC datetime to microsecond timestamp used by Hangouts.
    return date.timeIntervalSince1970 * 1000000.0
}
//
//
//##############################################################################
//# Message types and parsers
//##############################################################################
//
//
//TypingStatusMessage = namedtuple(
//'TypingStatusMessage', ['conv_id', 'user_id', 'timestamp', 'status']
//)
//
//
//def parse_typing_status_message(p):
//"""Return TypingStatusMessage from ClientSetTypingNotification.
//The same status may be sent multiple times consecutively, and when a
//message is sent the typing status will not change to stopped.
//"""
//return TypingStatusMessage(
//    conv_id=p.conversation_id.id_,
//    user_id=user.UserID(chat_id=p.user_id.chat_id,
//        gaia_id=p.user_id.gaia_id),
//    timestamp=from_timestamp(p.timestamp),
//    status=p.status,
//)
//
//
//WatermarkNotification = namedtuple(
//    'WatermarkNotification', ['conv_id', 'user_id', 'read_timestamp']
//)
//
//
//def parse_watermark_notification(client_watermark_notification):
//"""Return WatermarkNotification from ClientWatermarkNotification."""
//return WatermarkNotification(
//    conv_id=client_watermark_notification.conversation_id.id_,
//    user_id=user.UserID(
//        chat_id=client_watermark_notification.participant_id.chat_id,
//        gaia_id=client_watermark_notification.participant_id.gaia_id,
//    ),
//    read_timestamp=from_timestamp(
//        client_watermark_notification.latest_read_timestamp
//    ),
//)