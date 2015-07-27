//
//  LoginViewController.swift
//  Hangover
//
//  Created by Peter Sobot on 6/1/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation
import Cocoa
import WebKit
import Alamofire

class LoginViewController : NSViewController, WebResourceLoadDelegate, WebFrameLoadDelegate, WebPolicyDelegate {
    @IBOutlet weak var webView: WebView!
    var manager: Alamofire.Manager?
    var cb: ((auth_code: String) -> Void)?

    override func viewDidLoad() {
        let req = NSMutableURLRequest(URL: NSURL(string: OAUTH2_LOGIN_URL)!)
        webView.resourceLoadDelegate = self
        webView.frameLoadDelegate = self
        webView.policyDelegate = self
        webView.mainFrame.loadRequest(req)
    }

    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {

    }

    func webView(
        webView: WebView!,
        decidePolicyForNavigationAction actionInformation: [NSObject : AnyObject]!,
        request: NSURLRequest!,
        frame: WebFrame!,
        decisionListener listener: WebPolicyDecisionListener!)
    {
        if request.URL!.absoluteString.rangeOfString("https://accounts.google.com/o/oauth2/approval") != nil {
            print("should load: \(request.URL!)", appendNewline: false)
            listener.ignore()

            manager?.request(request).response { (request, response, responseObject, error) in
                let body = NSString(data: responseObject as! NSData, encoding: NSUTF8StringEncoding)!
                let auth_code = Regex("value=\"(.+?)\"").matches(body as String).first!
                self.cb?(auth_code: auth_code)
                self.dismissController(nil)
            }
        } else {
            listener.use()
        }
    }
}