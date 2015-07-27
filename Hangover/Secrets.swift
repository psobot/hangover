//
//  Secrets.swift
//  Hangover
//
//  Created by Peter Sobot on 6/19/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Foundation

import Valet
let VALET_IDENTIFIER = "HangoverGoogleAuthTokens"

func getValet() -> VALValet {
    return VALValet(identifier: VALET_IDENTIFIER, accessibility: VALAccessibility.AfterFirstUnlockThisDeviceOnly)!
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
    valet.setString(access_token, forKey: "access_token")
    valet.setString(refresh_token, forKey: "refresh_token")
}

func clearCodes() {
    let valet = getValet()
    valet.removeObjectForKey("access_token")
    valet.removeObjectForKey("refresh_token")
}


