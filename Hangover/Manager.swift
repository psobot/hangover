//
//  Manager.swift
//  Hangover
//
//  Created by Peter Sobot on 5/31/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation
import Alamofire

func configureManager() -> Alamofire.Manager {
    let cfg = NSURLSessionConfiguration.defaultSessionConfiguration()
    cfg.HTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
    return Alamofire.Manager(configuration: cfg)
}