//
//  NSView.swift
//  Hangover
//
//  Created by Peter Sobot on 6/11/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Cocoa

extension NSView {
    public class func instantiateFromNib<T: NSView>(identifier identifier: String, owner: AnyObject?) -> T? {
        var objects: NSArray?
        let nibName = T.className().componentsSeparatedByString(".").last
        if NSBundle.mainBundle().loadNibNamed(nibName!, owner: owner, topLevelObjects: &objects) {
            if let objects = objects {
                return objects.filter { $0 is T }.map { $0 as! T }.filter { $0.identifier == identifier }.first
            }
        }
        assert(false, "Could not find view with identifier \(identifier) in \(nibName).xib.")
        return nil
    }
}