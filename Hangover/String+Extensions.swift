//
//  String+Extensions.swift
//  Hangover
//
//  Created by Peter Sobot on 2015-05-30.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation

extension String {
    // :r: Must correctly select proper UTF-16 code-unit range. Wrong range will produce wrong result.
    public func convertRangeFromNSRange(r: NSRange) -> Range<String.Index> {
        let a  = (self as NSString).substringToIndex(r.location)
        let b  = (self as NSString).substringWithRange(r)

        let n1 = distance(a.startIndex, a.endIndex)
        let n2 = distance(b.startIndex, b.endIndex)

        let i1 = advance(startIndex, n1)
        let i2 = advance(i1, n2)

        return  Range<String.Index>(start: i1, end: i2)
    }
}