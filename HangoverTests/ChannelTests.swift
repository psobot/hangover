//
//  ChannelTests.swift
//  Hangover
//
//  Created by Peter Sobot on 2015-05-30.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Cocoa
import XCTest

class ChannelTests: XCTestCase {

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testParseSIDResponse() {
    let inputString = "79\n[[0,[\"c\",\"98803CAAD92268E8\",\"\",8]\n]\n,[1,[{\"gsid\":\"7tCoFHumSL-IT6BHpCaxLA\"}]]\n]\n"
    let expected = ("98803CAAD92268E8", "7tCoFHumSL-IT6BHpCaxLA")
    let actual = parseSIDResponse(inputString.dataUsingEncoding(NSUTF8StringEncoding)!)
    XCTAssertEqual(expected.0, actual.sid)
    XCTAssertEqual(expected.1, actual.gSessionID)
  }

  func testSimple() {
    let parser = PushDataParser()
    XCTAssertEqual(parser.getSubmissions("10\n01234567893\nabc".dataUsingEncoding(NSUTF8StringEncoding)!), ["0123456789", "abc"])
  }

  func testTruncatedMessage() {
    let parser = PushDataParser()
    XCTAssertEqual(parser.getSubmissions("12\n012345678".dataUsingEncoding(NSUTF8StringEncoding)!), [])
  }

  func testTruncatedLength() {
    let parser = PushDataParser()
    XCTAssertEqual(parser.getSubmissions("13".dataUsingEncoding(NSUTF8StringEncoding)!), [])
  }

  func testMalformedLength() {
    let parser = PushDataParser()
    XCTAssertEqual(parser.getSubmissions("11\n0123456789\n5e\n\"abc\"".dataUsingEncoding(NSUTF8StringEncoding)!), ["0123456789\n"])
  }

  func testIncremental() {
    let parser = PushDataParser()
    XCTAssertEqual(parser.getSubmissions("".dataUsingEncoding(NSUTF8StringEncoding)!), [])
    XCTAssertEqual(parser.getSubmissions("5".dataUsingEncoding(NSUTF8StringEncoding)!), [])
    XCTAssertEqual(parser.getSubmissions("\n".dataUsingEncoding(NSUTF8StringEncoding)!), [])
    XCTAssertEqual(parser.getSubmissions("abc".dataUsingEncoding(NSUTF8StringEncoding)!), [])
    XCTAssertEqual(parser.getSubmissions("de".dataUsingEncoding(NSUTF8StringEncoding)!), ["abcde"])
    XCTAssertEqual(parser.getSubmissions("".dataUsingEncoding(NSUTF8StringEncoding)!), [])
  }

  func testUnicode() {
    let parser = PushDataParser()
    XCTAssertEqual(parser.getSubmissions("3\na😀".dataUsingEncoding(NSUTF8StringEncoding)!), ["a😀"])
  }

//  func testSplitCharacters() {
//    let parser = PushDataParser()
//    XCTAssertEqual(parser.getSubmissions("1\n\u{e2}\u{82}".dataUsingEncoding(NSUTF8StringEncoding)!), [])
//    XCTAssertEqual(parser.getSubmissions("\u{ac}".dataUsingEncoding(NSUTF8StringEncoding)!), ["€"])
//  }

    func testChannelIDResponse() {
        let input = "152\n[[2,[{\"p\":\"{\\\"1\\\":{\\\"1\\\":{\\\"1\\\":{\\\"1\\\":1,\\\"2\\\":1}},\\\"4\\\":\\\"1433710435389\\\",\\\"5\\\":\\\"S1\\\"},\\\"3\\\":{\\\"1\\\":{\\\"1\\\":1},\\\"2\\\":\\\"lcsw_hangoutsBB487C95\\\"}}\"}]]\n]\n"
        let parser = PushDataParser()
        let results = parser.getSubmissions(input.dataUsingEncoding(NSUTF8StringEncoding)!)
        XCTAssertEqual(1, results.count)
    }
}
