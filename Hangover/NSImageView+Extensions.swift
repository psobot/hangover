//
//  NSImageView+Extensions.swift
//  Hangover
//
//  Created by Peter Sobot on 6/11/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Cocoa

extension NSImageView {
    public func loadImageFromURL(url: NSURL) {
        let request = NSURLRequest(URL: url)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) { (response, data, error) -> Void in
            if let data = data {
                self.image = NSImage(data: data)
            }
        }
    }
}