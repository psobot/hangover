//
//  PBLiteTests.swift
//  Hangover
//
//  Created by Peter Sobot on 6/2/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import XCTest
import Foundation
import JavaScriptCore

func loadJavaScript(filename: String) -> NSDictionary? {
    let path = NSBundle.mainBundle().pathForResource("Data/" + filename, ofType: "js")!

    let err = NSErrorPointer()
    do {
        let content = try String(contentsOfFile:path, encoding: NSUTF8StringEncoding)
        return JSContext().evaluateScript("a = " + content)!.toDictionary()
    } catch var error as NSError {
        err.memory = error
    }

    if err != nil {
        print("Error loading file: \(err)")
    }

    return nil
}

func loadMessage(filename: String) -> String? {
    let path = NSBundle.mainBundle().pathForResource("Data/" + filename, ofType: "message")!

    let err = NSErrorPointer()
    do {
        return try String(contentsOfFile:path, encoding: NSUTF8StringEncoding)
    } catch var error as NSError {
        err.memory = error
    }

    if err != nil {
        print("Error loading file: \(err)")
    }

    return nil
}

class EnumTestMessage : Message {
    var enumValue = ConversationType()
}

class ArrayTestMessage : Message {
    var array = [CONVERSATION_ID]()
}

class PBLiteTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDS20() {
        let data = (loadJavaScript("ds20")!["data"] as? NSArray)![0] as? NSArray
        let r = parse(CLIENT_GET_SELF_INFO_RESPONSE.self, input: data)!
        XCTAssertEqual("cgsirp", r.cgsirp)

        let entity = r.self_entity
        XCTAssertEqual("101968856481625398418", entity.id.gaia_id)
        XCTAssertEqual("101968856481625398418", entity.id.chat_id)

        XCTAssertEqual("Peter Test", entity.properties.display_name!)
    }

    func testMessageSegmentWithFormatting() {
        let segment = parse(MESSAGE_SEGMENT.self, input: [1, NSNull(), ["true", NSNull(), NSNull(), NSNull()], NSNull()])!
        XCTAssert(SegmentType.LINE_BREAK == segment.type_)
        XCTAssertNil(segment.text)
        XCTAssertNil(segment.link_data)

        let formatting = segment.formatting!
        XCTAssertEqual("true", formatting.bold!)
    }

    func testMessageSegmentWithLinkData() {
        let segment = parse(MESSAGE_SEGMENT.self, input: [1, NSNull(), NSNull(), ["link target"]])!
        XCTAssert(1 == segment.type_)
        XCTAssertNil(segment.text)
        XCTAssertNil(segment.formatting)
        XCTAssertEqual("link target", segment.link_data!.link_target!)
    }

    func testEnum() {
        let enumTestMessage = parse(EnumTestMessage.self, input: [2])!
        XCTAssert(enumTestMessage.enumValue == ConversationType.GROUP)
    }

    func testArray() {
        let arrayTestMessage = parse(ArrayTestMessage.self, input: [[["12"], ["23"], ["34"]]])!
        XCTAssertEqual(arrayTestMessage.array.count, 3)
        XCTAssertEqual("12", arrayTestMessage.array[0].id)
        XCTAssertEqual("23", arrayTestMessage.array[1].id)
        XCTAssertEqual("34", arrayTestMessage.array[2].id)
    }

    func testJSON() {
        let json = "{\"response_header\":{\"status\": \"OK\",\"debug_url\": \"\",\"request_trace_id\": \"5919526157227634454\",\"current_server_time\": \"1433707150506000\"},\"sync_timestamp\": \"1433706850507000\"}"
        let data = json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let resp: CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE? = parseJSON(data)
        XCTAssertEqual(resp!.sync_timestamp, "1433706850507000")
        XCTAssertNotNil(resp!.response_header)
        XCTAssertEqual(resp!.response_header.status, "OK")
        XCTAssertEqual(resp!.response_header.request_trace_id, "5919526157227634454")
        XCTAssertEqual(resp!.response_header.current_server_time, "1433707150506000")
    }

    func testIncomingTypingMessage() {
        let message = loadMessage("typing")!
        let parsed = parse_submission(message).updates
        XCTAssertEqual(1, parsed.count)
    }

    func testIncomingCharactersMessage() {
        let message = loadMessage("characters")!
        let parsed = parse_submission(message).updates
        XCTAssertEqual(3, parsed.count)

        let first = parsed[0]

        XCTAssert(first.state_update_header.active_client_state == ActiveClientState.IS_ACTIVE_CLIENT)
        XCTAssertNil(first.state_update_header.field1)
        XCTAssertEqual(first.state_update_header.request_trace_id, "507595749316912651")
        XCTAssertEqual(first.state_update_header.field2 as! Array<Array<NSNumber>>,  [[NSNumber(int: 0)]])
        XCTAssertEqual(first.state_update_header.current_server_time, NSNumber(unsignedLongLong: 1433824369966000))
        XCTAssertEqual(first.state_update_header.field3 as! Array<NSNumber>, [NSNumber(int: 1)])

        //  These two fields are not included.
        XCTAssertNil(first.state_update_header.field4)
        XCTAssertNil(first.state_update_header.updating_client_id)

        XCTAssertNil(first.conversation_notification)

        XCTAssertEqual(first.event_notification!.event.conversation_id.id, "Ugww93XG1Ah_CUEKJzJ4AaABAQ")
    }

}