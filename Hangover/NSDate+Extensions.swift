//
//  NSDate+Extensions.swift
//  Hangover
//
//  Created by Peter Sobot on 6/12/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Foundation

extension NSDate {
    func shortFormat() -> String {
        let dateFmt = NSDateFormatter()
        if self.isToday {
            dateFmt.dateFormat = "h:mm a"
        } else if self.isYesterday {
            return "Yesterday"
        } else {
            dateFmt.dateFormat = "MM/dd/YY"
        }
        return dateFmt.stringFromDate(self)
    }

    func isSameDayAs(other: NSDate) -> Bool {
        let calendar = NSCalendar.currentCalendar()
        let comparisonComponents: NSCalendarUnit = [
            NSCalendarUnit.Day,
            NSCalendarUnit.Month,
            NSCalendarUnit.Year,
            NSCalendarUnit.Era
        ]
        let otherComponents = calendar.components(comparisonComponents, fromDate: other)
        let selfComponents = calendar.components(comparisonComponents, fromDate: self)
        return otherComponents == selfComponents
    }

    var isToday: Bool {
        get {
            return self.isSameDayAs(NSDate())
        }
    }

    var isYesterday: Bool {
        get {
            //  TODO: This could be done better.
            return isSameDayAs(NSDate().dateByAddingTimeInterval(-1 * 60 * 60 * 24))
        }
    }
}