//
//  Secrets.swift
//  Hangover
//
//  Created by Peter Sobot on 6/19/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Foundation

// Importing Valet is currently broken in XCode 7b1
//import Valet
//let VALET_IDENTIFIER = "HangoverGoogleAuthTokens"

//func getValet() -> VALValet {
func getValet() -> NSUserDefaults {
    return NSUserDefaults.standardUserDefaults()
}

func loadCodes() -> (access_token: String, refresh_token: String)? {
    let valet = getValet()

    let at = valet.stringForKey("access_token")
    let rt = valet.stringForKey("refresh_token")
    if let at = at, let rt = rt {
        return (access_token: at, refresh_token: rt)
    }

    //  If we can't get the access token and refresh token,
    //  remove them both.
    valet.removeObjectForKey("access_token")
    valet.removeObjectForKey("refresh_token")
    return nil
}

func saveCodes(access_token: String, refresh_token: String) {
    let valet = getValet()
//    valet.setString(access_token, forKey: "access_token")
//    valet.setString(refresh_token, forKey: "refresh_token")
    valet.setObject(access_token, forKey: "access_token")
    valet.setObject(refresh_token, forKey: "refresh_token")
}

func clearCodes() {
    let valet = getValet()
    valet.removeObjectForKey("access_token")
    valet.removeObjectForKey("refresh_token")
}


