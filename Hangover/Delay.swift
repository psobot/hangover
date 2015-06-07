//
//  Delay.swift
//  Hangover
//
//  Created by Peter Sobot on 6/7/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation

// from @matt http://stackoverflow.com/a/24318861/679081
func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}