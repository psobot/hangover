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

    var err = NSErrorPointer()
    if let content = String(contentsOfFile:path, encoding: NSUTF8StringEncoding, error: err) {
        return JSContext().evaluateScript("a = " + content)!.toDictionary()
    }

    if err != nil {
        println("Error loading file: \(err)")
    }

    return nil
}

class EnumTestMessage : Message {
    var enumValue = ConversationType()
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
        XCTAssertEqual("101968856481625398418", entity.id_.gaia_id)
        XCTAssertEqual("101968856481625398418", entity.id_.chat_id)

        XCTAssertEqual("Peter Test", entity.properties.display_name!)
    }

    func testMessageSegmentWithFormatting() {
        let segment = MESSAGE_SEGMENT.parse([1, NSNull(), ["true", NSNull(), NSNull(), NSNull()], NSNull()])!
        XCTAssertEqual(1, segment.type_)
        XCTAssertNil(segment.text)
        XCTAssertNil(segment.link_data)

        let formatting = segment.formatting!
        XCTAssertEqual("true", formatting.bold!)
    }

    func testMessageSegmentWithLinkData() {
        let segment = MESSAGE_SEGMENT.parse([1, NSNull(), NSNull(), ["link target"]])!
        XCTAssertEqual(1, segment.type_)
        XCTAssertNil(segment.text)
        XCTAssertNil(segment.formatting)
        XCTAssertEqual("link target", segment.link_data!.link_target!)
    }

    func testEnum() {
        let enumTestMessage = EnumTestMessage.parse([2])!
        XCTAssertEqual(enumTestMessage.enumValue, ConversationType.GROUP)
    }
}