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

@objc protocol ChannelDelegate {
    optional func onMessage(message: NSString)
}

class Channel {
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
            self.startRequest()

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
        } else {
            NSLog("Listen failed due to no retries left.");
        }
        // logger.error('Ran out of retries for long-polling request')
    }

    func startRequest() {
        //  Open a long-polling request and receive push data.
        //
        //  This method uses keep-alive to make re-opening the request faster, but
        //  the remote server will set the "Connection: close" header once an hour.
        //
        //  Raises hangups.NetworkError or UnknownSIDError.
        NSLog("Opening new long-polling request")
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
        manager.request(request).response(onResponse)
      

//        except asyncio.TimeoutError:
//            raise exceptions.NetworkError('Request timed out')
//        except aiohttp.ClientError as e:
//            raise exceptions.NetworkError('Request connection error: {}'
//                                          .format(e))
//        except aiohttp.ServerDisconnectedError as e:
//            raise exceptions.NetworkError('Server disconnected error: {}'
//                                          .format(e))
//        if res.status == 400 and res.reason == 'Unknown SID':
//            raise UnknownSIDError('SID became invalid')
//        elif res.status != 200:
//            raise exceptions.NetworkError(
//                'Request return unexpected status: {}: {}'
//                .format(res.status, res.reason)
//            )
//        while True:
//            try:
//                chunk = yield from asyncio.wait_for(
//                    res.content.read(MAX_READ_BYTES), PUSH_TIMEOUT
//                )
//            except asyncio.TimeoutError:
//                raise exceptions.NetworkError('Request timed out')
//            except aiohttp.ClientError as e:
//                raise exceptions.NetworkError('Request connection error: {}'
//                                              .format(e))
//            except aiohttp.ServerDisconnectedError as e:
//                raise exceptions.NetworkError('Server disconnected error: {}'
//                                              .format(e))
//            except asyncio.CancelledError:
//                # Prevent ResourceWarning when channel is disconnected.
//                res.close()
//                raise
//            if chunk:
//                yield from self._on_push_data(chunk)
//            else:
//                # Close the response to allow the connection to be reused for
//                # the next request.
//                res.close()
//                break
    }

    func fetchChannelSID() {
        //  Creates a new channel for receiving push data.

        NSLog("Requesting new gsessionid and SID...")
        // There's a separate API to get the gsessionid alone that Hangouts for
        // Chrome uses, but if we don't send a gsessionid with this request, it
        // will return a gsessionid as well as the SID.

//      res = yield from http_utils.fetch(
//          'post', CHANNEL_URL_PREFIX.format('channel/bind'),
//          cookies=self._cookies, data='count=0', connector=self._connector,
//          params={
//              'VER': 8,
//              'RID': 81187,
//              'ctype': 'hangouts',  # client type
//          }
//      )
        var params = ["VER": 8, "RID": 81187, "ctype": "hangouts"]
        let headers = getAuthorizationHeaders(getCookieValue("SAPISID")!)
        let url = "\(CHANNEL_URL_PREFIX)/channel/bind?VER=8&RID=81187&ctype=hangouts"
        //  TODO: Include cookies
        //  TODO: Include timeout

        var URLRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        URLRequest.HTTPMethod = "POST"
        for (k, v) in headers {
            URLRequest.addValue(v, forHTTPHeaderField: k)
        }
        let data = "count=0".dataUsingEncoding(NSUTF8StringEncoding)!
        isSubscribed = false
        manager.upload(URLRequest, data: data).response(onChannelSIDResponse)
    }

    private func onResponse(
      request: NSURLRequest,
      response: NSHTTPURLResponse?,
      responseObject: AnyObject?,
      error: NSError?) -> Void {
        if let error = error {
            NSLog("Request failed: \(error)")
        } else {
            if response?.statusCode >= 400 {
                NSLog("Request failed with: \(NSString(data: responseObject as! NSData, encoding: 4))")
                self.need_new_sid = true
                listen()
            } else if response?.statusCode == 200 {
                onPushData(responseObject as! NSData)
            } else {
                NSLog("Received unknown response code \(response?.statusCode)")
                NSLog(NSString(data: responseObject as! NSData, encoding: 4)! as String)
            }
        }
    }

    private func onPushData(data: NSData) {
        // Delay subscribing until first byte is received prevent "channel not
        // ready" errors that appear to be caused by a race condition on the
        // server.
        if !isSubscribed {
            // subscribe()
            return
        }

        // This method is only called when the long-polling request was
        // successful, so use it to trigger connection events if necessary.
        if isConnected {
            if onConnectCalled {
                isConnected = true
                // yield from self.on_reconnect.fire()
            } else {
                onConnectCalled = true
                isConnected = true
                //yield from self.on_connect.fire()
            }
        }

        for submission in pushParser.getSubmissions(data) {
            // yield from self.on_message.fire(submission)
        }
    }

    private func onChannelSIDResponse(
        request: NSURLRequest,
        response: NSHTTPURLResponse?,
        responseObject: AnyObject?,
        error: NSError?) -> Void {
            if let error = error {
                NSLog("Request failed: \(error)")
            } else {
                let responseValues = parseSIDResponse(responseObject as! NSData)
                println("Got SID response back: \(NSString(data: responseObject as! NSData, encoding: 4))")
                sidParam = responseValues.sid
                gSessionIDParam = responseValues.gSessionID
                NSLog("New SID: \(sidParam)")
                NSLog("New gsessionid: \(gSessionIDParam)")
                need_new_sid = false
                listen()
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

    let now = NSDate()
    let time_msec = Int(now.timeIntervalSince1970 * 1000)

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

//"""Support for reading messages from the long-polling channel.
//
//Hangouts receives events using a system that appears very close to an App
//Engine Channel.
//"""
//
//import aiohttp
//import asyncio
//import hashlib
//import logging
//import re
//import time
//
//from hangups import javascript, http_utils, event, exceptions
//
//logger = logging.getLogger(__name__)
//LEN_REGEX = re.compile(r'([0-9]+)\n', re.MULTILINE)


//class UnknownSIDError(exceptions.HangupsError):
//
//    """hangups channel session expired."""
//
//    pass
//
//
//
//def _parse_sid_response(res):
//    """Parse response format for request for new channel SID.
//
//    Example format (after parsing JS):
//    [   [0,["c","SID_HERE","",8]],
//        [1,[{"gsid":"GSESSIONID_HERE"}]]]
//
//    Returns (SID, gsessionid) tuple.
//    """
//    res = javascript.loads(list(PushDataParser().get_submissions(res))[0])
//    sid = res[0][1][1]
//    gsessionid = res[1][1][0]['gsid']
//    return (sid, gsessionid)
//
//
//class Channel(object):
//
//    """A channel connection that can listen for messages."""
//
//    ##########################################################################
//    # Public methods
//    ##########################################################################
//
//    def __init__(self, cookies, connector):
//        """Create a new channel."""
//
//        # Event fired when channel connects with arguments ():
//        self.on_connect = event.Event('Channel.on_connect')
//        # Event fired when channel reconnects with arguments ():
//        self.on_reconnect = event.Event('Channel.on_reconnect')
//        # Event fired when channel disconnects with arguments ():
//        self.on_disconnect = event.Event('Channel.on_disconnect')
//        # Event fired when a channel submission is received with arguments
//        # (submission):
//        self.on_message = event.Event('Channel.on_message')
//
//
//    ##########################################################################
//    # Private methods
//    ##########################################################################
//
//    @asyncio.coroutine
//    def _fetch_channel_sid(self):
//        """Creates a new channel for receiving push data.
//
//        Raises hangups.NetworkError if the channel can not be created.
//        """
//        logger.info('Requesting new gsessionid and SID...')
//        # There's a separate API to get the gsessionid alone that Hangouts for
//        # Chrome uses, but if we don't send a gsessionid with this request, it
//        # will return a gsessionid as well as the SID.
//        res = yield from http_utils.fetch(
//            'post', CHANNEL_URL_PREFIX.format('channel/bind'),
//            cookies=self._cookies, data='count=0', connector=self._connector,
//            headers=get_authorization_headers(self._cookies['SAPISID']),
//            params={
//                'VER': 8,
//                'RID': 81187,
//                'ctype': 'hangouts',  # client type
//            }
//        )
//        self._sid_param, self._gsessionid_param = _parse_sid_response(res.body)
//        self._is_subscribed = False
//        logger.info('New SID: {}'.format(self._sid_param))
//        logger.info('New gsessionid: {}'.format(self._gsessionid_param))
//
//    @asyncio.coroutine
//    def _subscribe(self):
//        """Subscribes the channel to receive relevant events.
//
//        Only needs to be called when a new channel (SID/gsessionid) is opened.
//        """
//        # XXX: Temporary workaround for #58
//        yield from asyncio.sleep(1)
//
//        logger.info('Subscribing channel...')
//        timestamp = str(int(time.time() * 1000))
//        # Hangouts for Chrome splits this over 2 requests, but it's possible to
//        # do everything in one.
//        yield from http_utils.fetch(
//            'post', CHANNEL_URL_PREFIX.format('channel/bind'),
//            cookies=self._cookies, connector=self._connector,
//            headers=get_authorization_headers(self._cookies['SAPISID']),
//            params={
//                'VER': 8,
//                'RID': 81188,
//                'ctype': 'hangouts',  # client type
//                'gsessionid': self._gsessionid_param,
//                'SID': self._sid_param,
//            },
//            data={
//                'count': 3,
//                'ofs': 0,
//                'req0_p': ('{"1":{"1":{"1":{"1":3,"2":2}},"2":{"1":{"1":3,"2":'
//                           '2},"2":"","3":"JS","4":"lcsclient"},"3":' +
//                           timestamp + ',"4":0,"5":"c1"},"2":{}}'),
//                'req1_p': ('{"1":{"1":{"1":{"1":3,"2":2}},"2":{"1":{"1":3,"2":'
//                           '2},"2":"","3":"JS","4":"lcsclient"},"3":' +
//                           timestamp + ',"4":' + timestamp +
//                           ',"5":"c3"},"3":{"1":{"1":"babel"}}}'),
//                'req2_p': ('{"1":{"1":{"1":{"1":3,"2":2}},"2":{"1":{"1":3,"2":'
//                           '2},"2":"","3":"JS","4":"lcsclient"},"3":' +
//                           timestamp + ',"4":' + timestamp +
//                           ',"5":"c4"},"3":{"1":{"1":"hangout_invite"}}}'),
//            },
//        )
//        logger.info('Channel is now subscribed')
//        self._is_subscribed = True
//
//    @asyncio.coroutine
//    def _on_push_data(self, data_bytes):
//        """Parse push data and trigger event methods."""
//        logger.debug('Received push data:\n{}'.format(data_bytes))
//
//        # Delay subscribing until first byte is received prevent "channel not
//        # ready" errors that appear to be caused by a race condition on the
//        # server.
//        if not self._is_subscribed:
//            yield from self._subscribe()
//
//        # This method is only called when the long-polling request was
//        # successful, so use it to trigger connection events if necessary.
//        if not self._is_connected:
//            if self._on_connect_called:
//                self._is_connected = True
//                yield from self.on_reconnect.fire()
//            else:
//                self._on_connect_called = True
//                self._is_connected = True
//                yield from self.on_connect.fire()
//
//        for submission in self._push_parser.get_submissions(data_bytes):
//            yield from self.on_message.fire(submission)
