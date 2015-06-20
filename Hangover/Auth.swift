//
//  Auth.swift
//  Hangover
//
//  Created by Peter Sobot on 5/31/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation
import Alamofire


let OAUTH2_SCOPE = "https://www.google.com/accounts/OAuthLogin"
let OAUTH2_CLIENT_ID = "936475272427.apps.googleusercontent.com"
let OAUTH2_CLIENT_SECRET = "KWsJlkaMn1jGLxQpWxMnOox-"
let OAUTH2_LOGIN_URL = "https://accounts.google.com/o/oauth2/auth?client_id=\(OAUTH2_CLIENT_ID)&scope=\(OAUTH2_SCOPE)&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code"
let OAUTH2_TOKEN_REQUEST_URL = "https://accounts.google.com/o/oauth2/token"

func auth_with_code(auth_code: String, cb: (access_token: String, refresh_token: String) -> Void) {
    // Authenticate using OAuth authentication code.
    // Raises GoogleAuthError authentication fails.
    // Return access token string.

    // Make a token request.
    let token_request_data = [
        "client_id": OAUTH2_CLIENT_ID,
        "client_secret": OAUTH2_CLIENT_SECRET,
        "code": auth_code,
        "grant_type": "authorization_code",
        "redirect_uri": "urn:ietf:wg:oauth:2.0:oob",
    ]
    Alamofire.request(.POST, URLString: OAUTH2_TOKEN_REQUEST_URL, parameters: token_request_data).responseJSON {
        (request, response, JSON, error) in
        cb(access_token: JSON!["access_token"] as! String, refresh_token: JSON!["refresh_token"] as! String)
    }
}

func auth_with_refresh_token(
    manager: Alamofire.Manager,
    refresh_token: String,
    cb: (access_token: String, refresh_token: String) -> Void
) {
    let token_request_data = [
        "client_id": OAUTH2_CLIENT_ID,
        "client_secret": OAUTH2_CLIENT_SECRET,
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
    ]
    manager.request(.POST, OAUTH2_TOKEN_REQUEST_URL, parameters: token_request_data).responseJSON {
        (request, response, JSON, error) in
        cb(access_token: JSON!["access_token"] as! String, refresh_token: refresh_token)
    }
}

//func get_auth_cookies() -> Dictionary<String, String> {
//    Login into Google and return cookies as a dict.
//    get_code_f() is called if authorization code is required to log in, and
//    should return the code as a string.
//    A refresh token is saved/loaded from refresh_token_filename if possible, so
//    subsequent logins may not require re-authenticating.
//    Raises GoogleAuthError on failure.
//
//    try:
//      logger.info('Authenticating with refresh token')
//      access_token = _auth_with_refresh_token(refresh_token_filename)
//    except GoogleAuthError as e:
//      logger.info('Failed to authenticate using refresh token: %s', e)
//      logger.info('Authenticating with authorization code')
//      access_token = _auth_with_code(get_code_f, refresh_token_filename)
//    logger.info('Authentication successful')
//    return _get_session_cookies(access_token)
//}

func withAuthenticatedManager(cb: (manager: Alamofire.Manager) -> Void) {
    withAuthenticatedManager(configureManager(), cb: cb)
}

func withAuthenticatedManager(manager: Alamofire.Manager, cb: (manager: Alamofire.Manager) -> Void) {
    // This method should *not* take an access_token, and pop up a window with web view
    // to authenticate the user with Google, if possible.
    if let codes = loadCodes() {
        auth_with_refresh_token(manager, refresh_token: codes.refresh_token) { (access_token: String, refresh_token: String) in
            print("Auth'd with refresh token. New access token: \(access_token)")

            let url = "https://accounts.google.com/accounts/OAuthLogin?source=hangups&issueuberauth=1"
            let request = NSMutableURLRequest(URL: NSURL(string: url)!)
            request.setValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
            manager.request(request).response { (request, response, responseObject, error) in
                var uberauth = NSString(data: responseObject as! NSData, encoding: NSUTF8StringEncoding)! as String
                uberauth.replaceRange(Range<String.Index>(
                    start: advance(uberauth.endIndex, -1),
                    end: uberauth.endIndex
                    ), with: "")

                var request = NSMutableURLRequest(URL: NSURL(string: "https://accounts.google.com/MergeSession")!)
                request.setValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
                manager.request(request).response { (request, response, responseObject, error) in
                    let url = "https://accounts.google.com/MergeSession?service=mail&continue=http://www.google.com&uberauth=\(uberauth)"
                    var request = NSMutableURLRequest(URL: NSURL(string: url)!)
                    request.setValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
                    manager.request(request).response { (request, response, responseObject, error) in
                        cb(manager: manager)
                    }
                }
            }
        }
    } else {
        promptForGoogleLogin(manager) {
            print("Got callback, codes now \(loadCodes())")
            withAuthenticatedManager(manager, cb: cb)
        }
    }
}

var loginWindowController: NSWindowController?
func promptForGoogleLogin(manager: Alamofire.Manager, cb: () -> Void) {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)

    loginWindowController = storyboard.instantiateControllerWithIdentifier("LoginWindowController") as? NSWindowController

    let loginViewController = loginWindowController?.contentViewController as? LoginViewController
    loginViewController?.manager = manager
    loginViewController?.cb = { (auth_code: String) in
        auth_with_code(auth_code) { (access_token, refresh_token) -> Void in
            saveCodes(access_token, refresh_token: refresh_token)
            cb()
        }
    }

    loginWindowController!.showWindow(nil)
}
