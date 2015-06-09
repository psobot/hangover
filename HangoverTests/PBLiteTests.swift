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
    let path = NSBundle.mainBundle().pathForResource(filename, ofType: "js")!

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
        let r = CLIENT_GET_SELF_INFO_RESPONSE.parse(data)!
        XCTAssertEqual("cgsirp", r.cgsirp)

        let entity = r.self_entity
        XCTAssertEqual("101968856481625398418", entity.id.gaia_id)
        XCTAssertEqual("101968856481625398418", entity.id.chat_id)

        XCTAssertEqual("Peter Test", entity.properties.display_name!)
    }

    func testMessageSegmentWithFormatting() {
        let segment = MESSAGE_SEGMENT.parse([1, NSNull(), ["true", NSNull(), NSNull(), NSNull()], NSNull()])!
        XCTAssert(SegmentType.LINE_BREAK == segment.type_)
        XCTAssertNil(segment.text)
        XCTAssertNil(segment.link_data)

        let formatting = segment.formatting!
        XCTAssertEqual("true", formatting.bold!)
    }

    func testMessageSegmentWithLinkData() {
        let segment = MESSAGE_SEGMENT.parse([1, NSNull(), NSNull(), ["link target"]])!
        XCTAssert(1 == segment.type_)
        XCTAssertNil(segment.text)
        XCTAssertNil(segment.formatting)
        XCTAssertEqual("link target", segment.link_data!.link_target!)
    }

    func testEnum() {
        let enumTestMessage = EnumTestMessage.parse([2])!
        XCTAssert(enumTestMessage.enumValue == ConversationType.GROUP)
    }

    func testArray() {
        let arrayTestMessage = ArrayTestMessage.parse([[["12"], ["23"], ["34"]]])!
        XCTAssertEqual(arrayTestMessage.array.count, 3)
        XCTAssertEqual("12", arrayTestMessage.array[0].id_)
        XCTAssertEqual("23", arrayTestMessage.array[1].id_)
        XCTAssertEqual("34", arrayTestMessage.array[2].id_)
    }

    func testJSON() {
        let json = "{\"response_header\":{\"status\": \"OK\",\"debug_url\": \"\",\"request_trace_id\": \"5919526157227634454\",\"current_server_time\": \"1433707150506000\"},\"sync_timestamp\": \"1433706850507000\"}"
        let data = json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let resp = CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE.parseRawJSON(data)
        XCTAssertEqual(resp!.sync_timestamp, "1433706850507000")
        XCTAssertNotNil(resp!.response_header)
        XCTAssertEqual(resp!.response_header.status, "OK")
        XCTAssertEqual(resp!.response_header.request_trace_id, "5919526157227634454")
        XCTAssertEqual(resp!.response_header.current_server_time, "1433707150506000")
    }
}