//
//  NSDate+ExtensionsTests.swift
//  Hangover
//
//  Created by Peter Sobot on 6/12/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import XCTest

class NSDateExtensions: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDateIsToday() {
        XCTAssertTrue(NSDate().isToday)
    }

    func testDateIsNotYesterday() {
        XCTAssertTrue(!NSDate().isYesterday)
    }

    func testDateIsSameDayAs() {
        let now = NSDate(timeIntervalSince1970: 1434144143)
        let endOfDay = NSDate(timeIntervalSince1970: 1434165743)
        XCTAssertTrue(now.isSameDayAs(endOfDay))
    }
}