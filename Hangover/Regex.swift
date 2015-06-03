//
//  Regex.swift
//  Hangover
//
//  Created by Peter Sobot on 2015-05-30.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation

class Regex {
  let internalExpression: NSRegularExpression
  let pattern: String

    init(_ pattern: String, options: NSRegularExpressionOptions = .CaseInsensitive) {
        self.pattern = pattern
        var error: NSError?
        self.internalExpression = NSRegularExpression(pattern: pattern, options: options, error: &error)!
    }

  func test(input: String) -> Bool {
    let matches = self.internalExpression.matchesInString(input, options:nil, range:NSMakeRange(0, count(input)))
    return matches.count > 0
  }

  func findall(input: String) -> [String] {
    let results: [NSTextCheckingResult] = self.internalExpression.matchesInString(
      input, options:nil, range:NSMakeRange(0, count(input))
    ) as! [NSTextCheckingResult]
    return map(results) { input.substringWithRange(input.convertRangeFromNSRange($0.range)) }
  }

    func matches(input: String) -> [String] {
        let results: [NSTextCheckingResult] = self.internalExpression.matchesInString(
            input, options:nil, range:NSMakeRange(0, count(input))
            ) as! [NSTextCheckingResult]
        return map(results) { input.substringWithRange(input.convertRangeFromNSRange($0.rangeAtIndex(1))) }
    }
}