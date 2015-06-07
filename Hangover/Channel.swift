//
//  Channel.swift
//  Hangover
//
//  Created by Peter Sobot on 5/26/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Foundation
import Alamofire
import JavaScriptCore

protocol ChannelDelegate {
    func channelDidConnect(channel: Channel)
    func channelDidDisconnect(channel: Channel)
    func channelDidReconnect(channel: Channel)
    func channel(channel: Channel, didReceiveMessage: NSString)
}

class Channel : NSObject, NSURLSessionDataDelegate {
    static let ORIGIN_URL = "https://talkgadget.google.com"
    let CHANNEL_URL_PREFIX = "https://0.client-channel.google.com/client-channel"

    // Long-polling requests send heartbeats every 15 seconds, so if we miss two in
    // a row, consider the connection dead.
    let PUSH_TIMEOUT = 30
    let MAX_READ_BYTES = 1024 * 1024

    let CONNECT_TIMEOUT = 30

    static let LEN_REGEX = "([0-9]+)\n"

    var isConnected = false
    var isSubscribed = false
    var onConnectCalled = false
    var pushParser = PushDataParser()

    var sidParam: String? = nil
    var gSessionIDParam: String? = nil

    static let MAX_RETRIES = 5       // maximum number of times to retry after a failure
    var retries = MAX_RETRIES // number of remaining retries
    var need_new_sid = true   // whether a new SID is needed

    let manager: Alamofire.Manager
    var delegate: ChannelDelegate?

    init(manager: Alamofire.Manager) {
        self.manager = manager
    }

    func getCookieValue(key: String) -> String? {
        if let c = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies {
            if let match = (c.filter {
                ($0 as! NSHTTPCookie).name == key &&
                ($0 as! NSHTTPCookie).domain == ".google.com"
            }).first as? NSHTTPCookie {
                return match.value()
            }
        }
        return nil
    }

    func listen() {
        // Listen for messages on the channel.

        if self.retries >= 0 {
            // After the first failed retry, back off exponentially longer after
            // each attempt.
            if self.retries + 1 < Channel.MAX_RETRIES {
                let backoff_seconds = UInt64(2 << (Channel.MAX_RETRIES - self.retries))
                NSLog("Backing off for \(backoff_seconds) seconds")
                usleep(useconds_t(backoff_seconds * USEC_PER_SEC))
            }

            // Request a new SID if we don't have one yet, or the previous one
            // became invalid.
            if self.need_new_sid {
                // TODO: error handling
                self.fetchChannelSID()
                return
            }

            // Clear any previous push data, since if there was an error it
            // could contain garbage.
            self.pushParser = PushDataParser()
            self.makeLongPollingRequest()
        } else {
            NSLog("Listen failed due to no retries left.");
        }
        // logger.error('Ran out of retries for long-polling request')
    }

    func makeLongPollingRequest() {
        //  Open a long-polling request and receive push data.
        //
        //  This method uses keep-alive to make re-opening the request faster, but
        //  the remote server will set the "Connection: close" header once an hour.

        println("Opening long polling request.")
        //  Make the request!
        let queryString = "VER=8&RID=rpc&t=1&CI=0&ctype=hangouts&TYPE=xmlhttp&gsessionid=\(gSessionIDParam!.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)&SID=\(sidParam!.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)"
        let url = "\(CHANNEL_URL_PREFIX)/channel/bind?\(queryString)"

        //  TODO: Include timeout

        var request = NSMutableURLRequest(URL: NSURL(string: url)!)

        let sapisid = getCookieValue("SAPISID")!
        println("SAPISID param: \(sapisid)")
        for (k, v) in getAuthorizationHeaders(sapisid) {
            println("Setting header \(k) to \(v)")
            request.setValue(v, forHTTPHeaderField: k)
        }
        println("Making request to URL: \(url)")

//        let cfg = NSURLSessionConfiguration.defaultSessionConfiguration()
//        cfg.HTTPCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
//        let sessionCopy = NSURLSession(configuration: cfg, delegate: self, delegateQueue: nil)
//        sessionCopy.dataTaskWithRequest(request).resume()

        request.timeoutInterval = 30
        manager.request(request).stream { (data: NSData) in self.onPushData(data) }.response { (
            request: NSURLRequest,
            response: NSHTTPURLResponse?,
            responseObject: AnyObject?,
            error: NSError?) in

            println("long poll completed with status code: \(response?.statusCode)")
            if response?.statusCode >= 400 {
                NSLog("Request failed with: \(NSString(data: responseObject as! NSData, encoding: 4))")
                self.need_new_sid = true
                self.listen()
            } else if response?.statusCode == 200 {
                //self.onPushData(responseObject as! NSData)
                self.makeLongPollingRequest()
            } else {
                NSLog("Received unknown response code \(response?.statusCode)")
                NSLog(NSString(data: responseObject as! NSData, encoding: 4)! as String)
            }

        }
    }


    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        println("GOT DATA \(NSString(data: data, encoding: NSUTF8StringEncoding))")
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        NSLog("Request failed: \(error)")
        //            if let error = () {
        //                NSLog("Long-polling request failed: \(error)")
        //                retries -= 1
        //                if isConnected {
        //                    isConnected = false
        //                }

        //self.on_disconnect.fire()

        //                if isinstance(e, UnknownSIDError) {
        //                    need_new_sid = true
        //                }
        //            } else {
        // The connection closed successfully, so reset the number of
        // retries.
        //                retries = Channel.MAX_RETRIES
        //            }

        // If the request ended with an error, the client must account for
        // messages being dropped during this time.
    }

    func fetchChannelSID() {
        //  Creates a new channel for receiving push data.

        NSLog("Requesting new gsessionid and SID...")
        // There's a separate API to get the gsessionid alone that Hangouts for
        // Chrome uses, but if we don't send a gsessionid with this request, it
        // will return a gsessionid as well as the SID.

        var params = ["VER": 8, "RID": 81187, "ctype": "hangouts"]
        let headers = getAuthorizationHeaders(getCookieValue("SAPISID")!)
        let url = "\(CHANNEL_URL_PREFIX)/channel/bind?VER=8&RID=81187&ctype=hangouts"

        var URLRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        URLRequest.HTTPMethod = "POST"
        for (k, v) in headers {
            URLRequest.addValue(v, forHTTPHeaderField: k)
        }

        let data = "count=0".dataUsingEncoding(NSUTF8StringEncoding)!
        isSubscribed = false
        manager.upload(URLRequest, data: data).response { (
            request: NSURLRequest,
            response: NSHTTPURLResponse?,
            responseObject: AnyObject?,
            error: NSError?) in
            if let error = error {
                NSLog("Request failed: \(error)")
            } else {
                let responseValues = parseSIDResponse(responseObject as! NSData)
                println("Got SID response back: \(NSString(data: responseObject as! NSData, encoding: NSUTF8StringEncoding))")
                self.sidParam = responseValues.sid
                self.gSessionIDParam = responseValues.gSessionID
                NSLog("New SID: \(self.sidParam)")
                NSLog("New gsessionid: \(self.gSessionIDParam)")
                self.need_new_sid = false
                self.listen()
            }
        }

    }

    private func onPushData(data: NSData) {
        // Delay subscribing until first byte is received prevent "channel not
        // ready" errors that appear to be caused by a race condition on the
        // server.
        if !isSubscribed {
            subscribe {
                self.onPushData(data)
            }
            return
        }

        // This method is only called when the long-polling request was
        // successful, so use it to trigger connection events if necessary.
        if isConnected {
            if onConnectCalled {
                isConnected = true
                delegate?.channelDidReconnect(self)
            } else {
                onConnectCalled = true
                isConnected = true
                delegate?.channelDidConnect(self)
            }
        }

        for submission in pushParser.getSubmissions(data) {
            delegate?.channel(self, didReceiveMessage: submission)
        }
    }

    private var isSubscribing = false
    private func subscribe(cb: (() -> Void)?) {
        // Subscribes the channel to receive relevant events.
        // Only needs to be called when a new channel (SID/gsessionid) is opened.

        if isSubscribing { return }
        println("Subscribing channel...")
        isSubscribing = true

        // Temporary workaround for #58
        delay(1) {
            let timestamp = Int(NSDate().timeIntervalSince1970 * 1000)

            // Hangouts for Chrome splits this over 2 requests, but it's possible to
            // do everything in one.
            let data: Dictionary<String, AnyObject> = [
                "count": "3",
                "ofs": "0",
                "req0_p": "{\"1\":{\"1\":{\"1\":{\"1\":3,\"2\":2}},\"2\":{\"1\":{\"1\":3,\"2\":2},\"2\":\"\",\"3\":\"JS\",\"4\":\"lcsclient\"},\"3\":\(timestamp),\"4\":0,\"5\":\"c1\"},\"2\":{}}",
                "req1_p": "{\"1\":{\"1\":{\"1\":{\"1\":3,\"2\":2}},\"2\":{\"1\":{\"1\":3,\"2\":2},\"2\":\"\",\"3\":\"JS\",\"4\":\"lcsclient\"},\"3\":\(timestamp),\"4\":\(timestamp),\"5\":\"c3\"},\"3\":{\"1\":{\"1\":\"babel\"}}}",
                "req2_p": "{\"1\":{\"1\":{\"1\":{\"1\":3,\"2\":2}},\"2\":{\"1\":{\"1\":3,\"2\":2},\"2\":\"\",\"3\":\"JS\",\"4\":\"lcsclient\"},\"3\":\(timestamp),\"4\":\(timestamp),\"5\":\"c4\"},\"3\":{\"1\":{\"1\":\"hangout_invite\"}}}",
            ]
            let postBody = data.urlEncodedQueryStringWithEncoding(NSUTF8StringEncoding)
            let queryString = (["VER": 8, "RID": 81188, "ctype": "hangouts", "gsessionid": self.gSessionIDParam!, "SID": self.sidParam!] as Dictionary<String, AnyObject>).urlEncodedQueryStringWithEncoding(NSUTF8StringEncoding)

            let url = "\(self.CHANNEL_URL_PREFIX)/channel/bind?\(queryString)"
            var request = NSMutableURLRequest(URL: NSURL(string: url)!)
            request.HTTPMethod = "POST"
            request.HTTPBody = postBody.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            for (k, v) in getAuthorizationHeaders(self.getCookieValue("SAPISID")!) {
                request.setValue(v, forHTTPHeaderField: k)
            }

            println("Making request to URL: \(url)")
            self.manager.request(request).response { (
                request: NSURLRequest,
                response: NSHTTPURLResponse?,
                responseObject: AnyObject?,
                error: NSError?) in
                println("Channel is now subscribed.")
                self.isSubscribed = true
                cb?()
            }
        }
    }
}

func parseSIDResponse(res: NSData) -> (sid: String, gSessionID: String) {
    //  Parse response format for request for new channel SID.
    //
    //  Example format (after parsing JS):
    //  [   [0,["c","SID_HERE","",8]],
    //      [1,[{"gsid":"GSESSIONID_HERE"}]]]
    if let firstSubmission = PushDataParser().getSubmissions(res).first {
        let ctx = JSContext()
        let val: JSValue = ctx.evaluateScript(firstSubmission)
        let sid = ((val.toArray()[0] as! NSArray)[1] as! NSArray)[1] as! String
        let gSessionID = (((val.toArray()[1] as! NSArray)[1] as! NSArray)[0] as! NSDictionary)["gsid"]! as! String
        return (sid, gSessionID)
    }
    return ("", "")
}

func getAuthorizationHeaders(sapisid_cookie: String) -> Dictionary<String, String> {
    //  Return authorization headers for API request.
    //
    // It doesn't seem to matter what the url and time are as long as they are
    // consistent.

    let time_msec = Int(NSDate().timeIntervalSince1970 * 1000)

    let auth_string = "\(time_msec) \(sapisid_cookie) \(Channel.ORIGIN_URL)"
    let auth_hash = auth_string.SHA1()
    let sapisidhash = "SAPISIDHASH \(time_msec)_\(auth_hash)"
    return [
        "Authorization": sapisidhash,
        "X-Origin": Channel.ORIGIN_URL,
        "X-Goog-Authuser": "0",
    ]
}

func bestEffortDecode(data: NSData) -> String? {
    // Decode data_bytes into a string using UTF-8.
    //
    // If data_bytes cannot be decoded, pop the last byte until it can be or
    // return an empty string.
    for var i = 0; i < data.length; i++ {
        if let s = NSString(data: data.subdataWithRange(NSMakeRange(0, data.length - i)), encoding: NSUTF8StringEncoding) {
            return s as String
        }
    }
    return nil
}

class PushDataParser {
    // Parse data from the long-polling endpoint.

    var buf = NSMutableData()

    func getSubmissions(newBytes: NSData) -> [String] {
        //  Yield submissions generated from received data.
        //
        //  Responses from the push endpoint consist of a sequence of submissions.
        //  Each submission is prefixed with its length followed by a newline.
        //
        //  The buffer may not be decodable as UTF-8 if there's a split multi-byte
        //  character at the end. To handle this, do a "best effort" decode of the
        //  buffer to decode as much of it as possible.
        //
        //  The length is actually the length of the string as reported by
        //  JavaScript. JavaScript's string length function returns the number of
        //  code units in the string, represented in UTF-16. We can emulate this by
        //  encoding everything in UTF-16 and multipling the reported length by 2.
        //
        //  Note that when encoding a string in UTF-16, Python will prepend a
        //  byte-order character, so we need to remove the first two bytes.

        buf.appendData(newBytes)
        var submissions = [String]()

        while buf.length > 0 {
            if let decoded = bestEffortDecode(buf) {
                let bufUTF16 = decoded.dataUsingEncoding(NSUTF16BigEndianStringEncoding)!
                let decodedUtf16LengthInChars = bufUTF16.length / 2

                let lengths = Regex(Channel.LEN_REGEX).findall(decoded)
                if let length_str = lengths.first {
                    let length_str_without_newline = length_str.substringToIndex(advance(length_str.endIndex, -1))
                    if let length = length_str_without_newline.toInt() {
                        if decodedUtf16LengthInChars - count(length_str) < length {
                          break
                        }

                        let subData = bufUTF16.subdataWithRange(NSMakeRange(count(length_str) * 2, length * 2))
                        let submission = NSString(data: subData, encoding: NSUTF16BigEndianStringEncoding)! as String
                        submissions.append(submission)

                        let submissionAsUTF8 = submission.dataUsingEncoding(NSUTF8StringEncoding)!

                        let removeRange = NSMakeRange(0, count(length_str) + submissionAsUTF8.length)
                        buf.replaceBytesInRange(removeRange, withBytes: nil, length: 0)
                    } else {
                      break
                    }
                } else {
                    break
                }
            }
        }

        return submissions
    }
}

