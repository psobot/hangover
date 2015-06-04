//
//  Client.swift
//  Hangover
//
//  Created by Peter Sobot on 5/26/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

//from hangups import (javascript, parsers, exceptions, http_utils, channel,
//                     event, schemas)

import Foundation
import Alamofire
import JavaScriptCore

let ORIGIN_URL = "https://talkgadget.google.com"
let IMAGE_UPLOAD_URL = "http://docs.google.com/upload/photos/resumable"
let PVT_TOKEN_URL = "https://talkgadget.google.com/talkgadget/_/extension-start"
let CHAT_INIT_URL = "https://talkgadget.google.com/u/0/talkgadget/_/chat"

let CHAT_INIT_REGEX = "(?:<script>AF_initDataCallback\\((.*?)\\);</script>)"

// Timeout to send for setactiveclient requests:
let ACTIVE_TIMEOUT_SECS = 120
// Minimum timeout between subsequent setactiveclient requests:
let SETACTIVECLIENT_LIMIT_SECS = 60

protocol ClientDelegate {
    func clientDidConnect(client: Client, initialData: InitialData)
    func clientDidDisconnect(client: Client)
    func clientDidReconnect(client: Client)
}

class Client : ChannelDelegate {
    let manager: Alamofire.Manager
    var delegate: ClientDelegate?

    var CHAT_INIT_PARAMS: Dictionary<String, AnyObject?> = [
        "prop": "aChromeExtension",
        "fid": "gtn-roster-iframe-id",
        "ec": "[\"ci:ec\",true,true,false]",
        "pvt": nil, // Populated later
    ]

    init(manager: Alamofire.Manager) {
        self.manager = manager
    }

    var initial_data: InitialData?
    var channel: Channel?

    func connect() {
        self.initialize_chat { (id: InitialData?) in
            self.initial_data = id
            println("Chat initialized. Opening channel...")

            self.channel = Channel(manager: self.manager)
            self.channel?.delegate = self
            self.channel?.listen()
        }
    }

    func initialize_chat(cb: (data: InitialData?) -> Void) {
        //Request push channel creation and initial chat data.
        //
        //Returns instance of InitialData.
        //
        //The response body is a HTML document containing a series of script tags
        //containing JavaScript objects. We need to parse the objects to get at
        //the data.

        // We first need to fetch the 'pvt' token, which is required for the
        // initialization request (otherwise it will return 400).

        let prop = (CHAT_INIT_PARAMS["prop"] as! String).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let fid = (CHAT_INIT_PARAMS["fid"] as! String).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let ec = (CHAT_INIT_PARAMS["ec"] as! String).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let url = "\(PVT_TOKEN_URL)?prop=\(prop)&fid=\(fid)&ec=\(ec)"
        println("Fetching pvt token: \(url)")
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        manager.request(request).response { (
            request: NSURLRequest,
            response: NSHTTPURLResponse?,
            responseObject: AnyObject?,
            error: NSError?) in

            // CHAT_INIT_PARAMS['pvt'] = javascript.loads(res.body.decode())[1]
            let body = NSString(data: responseObject as! NSData, encoding: NSUTF8StringEncoding)! as String

            let ctx = JSContext()
            let pvt: AnyObject = ctx.evaluateScript(body).toArray()[1] as! String
            self.CHAT_INIT_PARAMS["pvt"] = pvt

            // Now make the actual initialization request:
            let prop = (self.CHAT_INIT_PARAMS["prop"] as! String).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            let fid = (self.CHAT_INIT_PARAMS["fid"] as! String).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            let ec = (self.CHAT_INIT_PARAMS["ec"] as! String).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            let pvt_enc = (self.CHAT_INIT_PARAMS["pvt"] as! String).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!

            let url = "\(CHAT_INIT_URL)?prop=\(prop)&fid=\(fid)&ec=\(ec)&pvt=\(pvt_enc)"
            println("Initializing chat: \(url)")
            var request = NSMutableURLRequest(URL: NSURL(string: url)!)
            self.manager.request(request).response { (
                request: NSURLRequest,
                response: NSHTTPURLResponse?,
                responseObject: AnyObject?,
                error: NSError?) in

                let body = NSString(data: responseObject as! NSData, encoding: NSUTF8StringEncoding)! as String
                println(error?.description)
                println(response?.description)
                println("Received chat init response: '\(body)'")

                // Parse the response by using a regex to find all the JS objects, and
                // parsing them. Not everything will be parsable, but we don't care if
                // an object we don't need can't be parsed.

                var data_dict = Dictionary<String, AnyObject?>()
                for data in Regex(CHAT_INIT_REGEX,
                    options: NSRegularExpressionOptions.CaseInsensitive |
                    NSRegularExpressionOptions.DotMatchesLineSeparators
                ).matches(body) {

                    if data.rangeOfString("data:function") == nil {
                        let dict = JSContext().evaluateScript("a = " + data).toDictionary()!
                        data_dict[dict["key"] as! String] = dict["data"]
                    } else {
                        var cleanedData = data
                        cleanedData = cleanedData.stringByReplacingOccurrencesOfString(
                            "data:function(){return", withString: "data:")
                        cleanedData = cleanedData.stringByReplacingOccurrencesOfString(
                            "}}", withString: "}")
                        if let dict = JSContext().evaluateScript("a = " + cleanedData).toDictionary() {
                            data_dict[dict["key"] as! String] = dict["data"]
                        } else {
                            println("Could not parse!")
                        }
                    }
                }
                let api_key = ((data_dict["ds:7"] as! NSArray)[0] as! NSArray)[2] as! String
                let email = ((data_dict["ds:33"] as! NSArray)[0] as! NSArray)[2] as! String
                let header_date = ((data_dict["ds:2"] as! NSArray)[0] as! NSArray)[4] as! String
                let header_version = ((data_dict["ds:2"] as! NSArray)[0] as! NSArray)[6] as! String
                let header_id = ((data_dict["ds:4"] as! NSArray)[0] as! NSArray)[7] as! String

                let sync_timestamp = (((data_dict["ds:21"] as! NSArray)[0] as! NSArray)[1] as! NSArray)[4] as! NSNumber
                //  parse timestamp call needed here

                let self_entity = CLIENT_GET_SELF_INFO_RESPONSE.parse((data_dict["ds:20"] as! NSArray)[0] as? NSArray)!.self_entity

                let initial_conv_states_raw = ((data_dict["ds:19"] as! NSArray)[0] as! NSArray)[3] as! NSArray
                let initial_conv_states = map(initial_conv_states_raw as! [NSArray]) {
                    CLIENT_CONVERSATION_STATE.parse($0)!
                }
                let initial_conv_parts = initial_conv_states.flatMap { $0.conversation.participant_data }

                let entities = INITIAL_CLIENT_ENTITIES.parse((data_dict["ds:21"] as! NSArray)[0] as? NSArray)!
                let initial_entities = (entities.entities) + [
                    entities.group1.entity,
                    entities.group2.entity,
                    entities.group3.entity,
                    entities.group4.entity,
                    entities.group5.entity,
                ].flatMap { $0 }.map { $0.entity }

                cb(data: InitialData(
                    initial_conv_states,
                    self_entity,
                    initial_entities,
                    initial_conv_parts,
                    sync_timestamp
                ))
            }
        }
    }

    func channelDidConnect(channel: Channel) {
        delegate?.clientDidConnect(self, initialData: initial_data!)
    }

    func channelDidDisconnect(channel: Channel) {
        delegate?.clientDidDisconnect(self)
    }

    func channelDidReconnect(channel: Channel) {
        delegate?.clientDidReconnect(self)
    }

    func channel(channel: Channel, didReceiveMessage message: NSString) {
        println("\n\nA MESSAGE FROM ELGOOG:\n\t\(message)\n\n")
    }
}

typealias InitialData = (
    conversation_states: [CLIENT_CONVERSATION_STATE],
    self_entity: CLIENT_ENTITY,
    entities: [CLIENT_ENTITY],
    conversation_participants: [CLIENT_CONVERSATION.PARTICIPANT_DATA],
    sync_timestamp: NSNumber
)

//class Client(object):
//    """Instant messaging client for Hangouts.
//
//    Maintains a connections to the servers, emits events, and accepts commands.
//    """
//
//    def __init__(self, cookies):
//        """Create new client.
//
//        cookies is a dictionary of authentication cookies.
//        """
//
//        # Event fired when the client connects for the first time with
//        # arguments (initial_data).
//        self.on_connect = event.Event('Client.on_connect')
//        # Event fired when the client reconnects after being disconnected with
//        # arguments ().
//        self.on_reconnect = event.Event('Client.on_reconnect')
//        # Event fired when the client is disconnected with arguments ().
//        self.on_disconnect = event.Event('Client.on_disconnect')
//        # Event fired when a ClientStateUpdate arrives with arguments
//        # (state_update).
//        self.on_state_update = event.Event('Client.on_state_update')
//
//        self._cookies = cookies
//        proxy = os.environ.get('HTTP_PROXY')
//        if proxy:
//            self._connector = aiohttp.ProxyConnector(proxy)
//        else:
//            self._connector = aiohttp.TCPConnector()
//
//        # hangups.channel.Channel instantiated in connect()
//        self._channel = None
//        # API key sent with every request:
//        self._api_key = None
//        # Parameters sent in request headers:
//        self._header_date = None
//        self._header_version = None
//        self._header_id = None
//        # String identifying this client:
//        self._client_id = None
//        # Account email address:
//        self._email = None
//        # Time in seconds that the client as last set as active:
//        self._last_active_secs = 0.0
//        # ActiveClientState enum value or None:
//        self._active_client_state = None
//        # Future for Channel.listen
//        self._listen_future = None
//
//    ##########################################################################
//    # Public methods
//    ##########################################################################
//
//    @asyncio.coroutine
//    def connect(self):
//        """Establish a connection to the chat server.
//
//        Returns when an error has occurred, or Client.disconnect has been
//        called.
//        """
//        initial_data = yield from self._initialize_chat()
//        self._channel = channel.Channel(self._cookies, self._connector)
//        @asyncio.coroutine
//        def _on_connect():
//            """Wrapper to fire on_connect with initial_data."""
//            yield from self.on_connect.fire(initial_data)
//        self._channel.on_connect.add_observer(_on_connect)
//        self._channel.on_reconnect.add_observer(self.on_reconnect.fire)
//        self._channel.on_disconnect.add_observer(self.on_disconnect.fire)
//        self._channel.on_message.add_observer(self._on_push_data)
//
//        self._listen_future = asyncio.async(self._channel.listen())
//        try:
//            yield from self._listen_future
//        except asyncio.CancelledError:
//            pass
//        logger.info('disconnecting gracefully')
//
//    @asyncio.coroutine
//    def disconnect(self):
//        """Gracefully disconnect from the server.
//
//        When disconnection is complete, Client.connect will return.
//        """
//        self._listen_future.cancel()
//        self._connector.close()
//
//    @asyncio.coroutine
//    def set_active(self):
//        """Set this client as active.
//
//        While a client is active, no other clients will raise notifications.
//        Call this method whenever there is an indication the user is
//        interacting with this client. This method may be called very
//        frequently, and it will only make a request when necessary.
//        """
//        is_active = (self._active_client_state ==
//                     schemas.ActiveClientState.IS_ACTIVE_CLIENT)
//        timed_out = (time.time() - self._last_active_secs >
//                     SETACTIVECLIENT_LIMIT_SECS)
//        if not is_active or timed_out:
//            # Update these immediately so if the function is called again
//            # before the API request finishes, we don't start extra requests.
//            self._active_client_state = (
//                schemas.ActiveClientState.IS_ACTIVE_CLIENT
//            )
//            self._last_active_secs = time.time()
//            try:
//                yield from self.setactiveclient(True, ACTIVE_TIMEOUT_SECS)
//            except exceptions.NetworkError as e:
//                logger.warning('Failed to set active client: {}'.format(e))
//            else:
//                logger.info('Set active client for {} seconds'
//                            .format(ACTIVE_TIMEOUT_SECS))
//
//    ##########################################################################
//    # Private methods
//    ##########################################################################
//
//    def _get_cookie(self, name):
//        """Return a cookie for raise error if that cookie was not provided."""
//        try:
//            return self._cookies[name]
//        except KeyError:
//            raise KeyError("Cookie '{}' is required".format(name))
//
//    def _get_request_header(self):
//        """Return request header for chat API request."""
//        return [
//            [6, 3, self._header_version, self._header_date],
//            [self._client_id, self._header_id],
//            None,
//            "en"
//        ]
//
//    @asyncio.coroutine
//    def _on_push_data(self, submission):
//        """Parse ClientStateUpdate and call the appropriate events."""
//        for state_update in parsers.parse_submission(submission):
//            if isinstance(state_update, dict) and 'client_id' in state_update:
//                # Hack to receive client ID:
//                self._client_id = state_update['client_id']
//                logger.info('Received new client_id: {}'
//                            .format(self._client_id))
//            else:
//                self._active_client_state = (
//                    state_update.state_update_header.active_client_state
//                )
//                yield from self.on_state_update.fire(state_update)
//
//    @asyncio.coroutine
//    def _request(self, endpoint, body_json, use_json=True):
//        """Make chat API request.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        url = 'https://clients6.google.com/chat/v1/{}'.format(endpoint)
//        res = yield from self._base_request(
//            url, 'application/json+protobuf', json.dumps(body_json),
//            use_json=use_json
//        )
//        return res
//
//    @asyncio.coroutine
//    def _base_request(self, url, content_type, data, use_json=True):
//        """Make API request.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        headers = channel.get_authorization_headers(
//            self._get_cookie('SAPISID')
//        )
//        headers['content-type'] = content_type
//        required_cookies = ['SAPISID', 'HSID', 'SSID', 'APISID', 'SID']
//        cookies = {cookie: self._get_cookie(cookie)
//                   for cookie in required_cookies}
//        params = {
//            'key': self._api_key,
//            'alt': 'json' if use_json else 'protojson',
//        }
//        res = yield from http_utils.fetch(
//            'post', url, headers=headers, cookies=cookies, params=params,
//            data=data, connector=self._connector
//        )
//        logger.debug('Response to request for {} was {}:\n{}'
//                     .format(url, res.code, res.body))
//        return res
//
//    ###########################################################################
//    # Raw API request methods
//    ###########################################################################
//
//    @asyncio.coroutine
//    def syncallnewevents(self, timestamp):
//        """List all events occurring at or after timestamp.
//
//        This method requests protojson rather than json so we have one chat
//        message parser rather than two.
//
//        timestamp: datetime.datetime instance specifying the time after
//        which to return all events occurring in.
//
//        Raises hangups.NetworkError if the request fails.
//
//        Returns a ClientSyncAllNewEventsResponse.
//        """
//        res = yield from self._request('conversations/syncallnewevents', [
//            self._get_request_header(),
//            # last_sync_timestamp
//            parsers.to_timestamp(timestamp),
//            [], None, [], False, [],
//            1048576  # max_response_size_bytes
//        ], use_json=False)
//        try:
//            res = schemas.CLIENT_SYNC_ALL_NEW_EVENTS_RESPONSE.parse(
//                javascript.loads(res.body.decode())
//            )
//        except ValueError as e:
//            raise exceptions.NetworkError('Response failed to parse: {}'
//                                          .format(e))
//        # can return 200 but still contain an error
//        status = res.response_header.status
//        if status != 1:
//            raise exceptions.NetworkError('Response status is \'{}\''
//                                          .format(status))
//        return res
//
//    @asyncio.coroutine
//    def sendchatmessage(
//            self, conversation_id, segments, image_id=None,
//            otr_status=schemas.OffTheRecordStatus.ON_THE_RECORD
//    ):
//        """Send a chat message to a conversation.
//
//        conversation_id must be a valid conversation ID. segments must be a
//        list of message segments to send, in pblite format.
//
//        otr_status determines whether the message will be saved in the server's
//        chat history. Note that the OTR status of the conversation is
//        irrelevant, clients may send messages with whatever OTR status they
//        like.
//
//        image_id is an option ID of an image retrieved from
//        Client.upload_image. If provided, the image will be attached to the
//        message.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        client_generated_id = random.randint(0, 2**32)
//        body = [
//            self._get_request_header(),
//            None, None, None, [],
//            [
//                segments, []
//            ],
//            [[image_id, False]] if image_id else None,
//            [
//                [conversation_id],
//                client_generated_id,
//                otr_status.value,
//            ],
//            None, None, None, []
//        ]
//        res = yield from self._request('conversations/sendchatmessage', body)
//        # sendchatmessage can return 200 but still contain an error
//        res = json.loads(res.body.decode())
//        res_status = res['response_header']['status']
//        if res_status != 'OK':
//            raise exceptions.NetworkError('Unexpected status: {}'
//                                          .format(res_status))
//
//    @asyncio.coroutine
//    def upload_image(self, image_file, filename=None):
//        """Upload an image that can be later attached to a chat message.
//
//        image_file is a file-like object containing an image.
//
//        The name of the uploaded file may be changed by specifying the filename
//        argument.
//
//        Raises hangups.NetworkError if the request fails.
//
//        Returns ID of uploaded image.
//        """
//        image_filename = (filename if filename
//                          else os.path.basename(image_file.name))
//        image_data = image_file.read()
//
//        # Create image and request upload URL
//        res1 = yield from self._base_request(
//            IMAGE_UPLOAD_URL,
//            'application/x-www-form-urlencoded;charset=UTF-8',
//            json.dumps({
//                "protocolVersion": "0.8",
//                "createSessionRequest": {
//                    "fields": [{
//                        "external": {
//                            "name": "file",
//                            "filename": image_filename,
//                            "put": {},
//                            "size": len(image_data),
//                        }
//                    }]
//                }
//            }))
//        upload_url = (json.loads(res1.body.decode())['sessionStatus']
//                      ['externalFieldTransfers'][0]['putInfo']['url'])
//
//        # Upload image data and get image ID
//        res2 = yield from self._base_request(
//            upload_url, 'application/octet-stream', image_data
//        )
//        return (json.loads(res2.body.decode())['sessionStatus']
//                ['additionalInfo']
//                ['uploader_service.GoogleRupioAdditionalInfo']
//                ['completionInfo']['customerSpecificInfo']['photoid'])
//
//    @asyncio.coroutine
//    def setactiveclient(self, is_active, timeout_secs):
//        """Set the active client.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        res = yield from self._request('clients/setactiveclient', [
//            self._get_request_header(),
//            # is_active: whether the client is active or not
//            is_active,
//            # full_jid: user@domain/resource
//            "{}/{}".format(self._email, self._client_id),
//            # timeout_secs: timeout in seconds for this client to be active
//            timeout_secs
//        ])
//        res = json.loads(res.body.decode())
//        res_status = res['response_header']['status']
//        if res_status != 'OK':
//            raise exceptions.NetworkError('Unexpected status: {}'
//                                          .format(res_status))
//
//    ###########################################################################
//    # UNUSED raw API request methods (by hangups itself) for reference
//    ###########################################################################
//
//    @asyncio.coroutine
//    def removeuser(self, conversation_id):
//        """Leave group conversation.
//
//        conversation_id must be a valid conversation ID.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        client_generated_id = random.randint(0, 2**32)
//        res = yield from self._request('conversations/removeuser', [
//            self._get_request_header(),
//            None, None, None,
//            [
//                [conversation_id], client_generated_id, 2
//            ],
//        ])
//        res = json.loads(res.body.decode())
//        res_status = res['response_header']['status']
//        if res_status != 'OK':
//            raise exceptions.NetworkError('Unexpected status: {}'
//                                          .format(res_status))
//
//    @asyncio.coroutine
//    def deleteconversation(self, conversation_id):
//        """Delete one-to-one conversation.
//
//        conversation_id must be a valid conversation ID.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        res = yield from self._request('conversations/deleteconversation', [
//            self._get_request_header(),
//            [conversation_id],
//            # Not sure what timestamp should be there, last time I have tried
//            # it Hangouts client in GMail sent something like now() - 5 hours
//            parsers.to_timestamp(
//                datetime.datetime.now(tz=datetime.timezone.utc)
//            ),
//            None, [],
//        ])
//        res = json.loads(res.body.decode())
//        res_status = res['response_header']['status']
//        if res_status != 'OK':
//            raise exceptions.NetworkError('Unexpected status: {}'
//                                          .format(res_status))
//
//    @asyncio.coroutine
//    def settyping(self, conversation_id, typing=schemas.TypingStatus.TYPING):
//        """Send typing notification.
//
//        conversation_id must be a valid conversation ID.
//        typing must be a hangups.TypingStatus Enum.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        res = yield from self._request('conversations/settyping', [
//            self._get_request_header(),
//            [conversation_id],
//            typing.value
//        ])
//        res = json.loads(res.body.decode())
//        res_status = res['response_header']['status']
//        if res_status != 'OK':
//            raise exceptions.NetworkError('Unexpected status: {}'
//                                          .format(res_status))
//
//    @asyncio.coroutine
//    def updatewatermark(self, conv_id, read_timestamp):
//        """Update the watermark (read timestamp) for a conversation.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        res = yield from self._request('conversations/updatewatermark', [
//            self._get_request_header(),
//            # conversation_id
//            [conv_id],
//            # latest_read_timestamp
//            parsers.to_timestamp(read_timestamp),
//        ])
//        res = json.loads(res.body.decode())
//        res_status = res['response_header']['status']
//        if res_status != 'OK':
//            raise exceptions.NetworkError('Unexpected status: {}'
//                                          .format(res_status))
//
//    @asyncio.coroutine
//    def getselfinfo(self):
//        """Return information about your account.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        res = yield from self._request('contacts/getselfinfo', [
//            self._get_request_header(),
//            [], []
//        ])
//        return json.loads(res.body.decode())
//
//    @asyncio.coroutine
//    def setfocus(self, conversation_id):
//        """Set focus (occurs whenever you give focus to a client).
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        res = yield from self._request('conversations/setfocus', [
//            self._get_request_header(),
//            [conversation_id],
//            1,
//            20
//        ])
//        return json.loads(res.body.decode())
//
//    @asyncio.coroutine
//    def searchentities(self, search_string, max_results):
//        """Search for people.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        res = yield from self._request('contacts/searchentities', [
//            self._get_request_header(),
//            [],
//            search_string,
//            max_results
//        ])
//        return json.loads(res.body.decode())
//
//    @asyncio.coroutine
//    def setpresence(self, online, mood=None):
//        """Set the presence or mood of this client.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        res = yield from self._request('presence/setpresence', [
//            self._get_request_header(),
//            [
//                # timeout_secs timeout in seconds for this presence
//                720,
//                # client_presence_state:
//                # 40 => DESKTOP_ACTIVE
//                # 30 => DESKTOP_IDLE
//                # 1 => NONE
//                1 if online else 40,
//            ],
//            None,
//            None,
//            # True if going offline, False if coming online
//            [not online],
//            # UTF-8 smiley like 0x1f603
//            [mood],
//        ])
//        res = json.loads(res.body.decode())
//        res_status = res['response_header']['status']
//        if res_status != 'OK':
//            raise exceptions.NetworkError('Unexpected status: {}'
//                                          .format(res_status))
//
//    @asyncio.coroutine
//    def querypresence(self, chat_id):
//        """Check someone's presence status.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        res = yield from self._request('presence/querypresence', [
//            self._get_request_header(),
//            [
//                [chat_id]
//            ],
//            [1, 2, 5, 7, 8]
//        ])
//        return json.loads(res.body.decode())
//
//    @asyncio.coroutine
//    def getentitybyid(self, chat_id_list):
//        """Return information about a list of contacts.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        res = yield from self._request('contacts/getentitybyid', [
//            self._get_request_header(),
//            None,
//            [[str(chat_id)] for chat_id in chat_id_list],
//        ], use_json=False)
//        try:
//            res = schemas.CLIENT_GET_ENTITY_BY_ID_RESPONSE.parse(
//                javascript.loads(res.body.decode())
//            )
//        except ValueError as e:
//            raise exceptions.NetworkError('Response failed to parse: {}'
//                                          .format(e))
//        # can return 200 but still contain an error
//        status = res.response_header.status
//        if status != 1:
//            raise exceptions.NetworkError('Response status is \'{}\''
//                                          .format(status))
//        return res
//
//    @asyncio.coroutine
//    def getconversation(self, conversation_id, event_timestamp, max_events=50):
//        """Return conversation events.
//
//        This is mainly used for retrieving conversation scrollback. Events
//        occurring before event_timestamp are returned, in order from oldest to
//        newest.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        res = yield from self._request('conversations/getconversation', [
//            self._get_request_header(),
//            [[conversation_id], [], []],  # conversationSpec
//            False,  # includeConversationMetadata
//            True,  # includeEvents
//            None,  # ???
//            max_events,  # maxEventsPerConversation
//            # eventContinuationToken (specifying timestamp is sufficient)
//            [
//                None,  # eventId
//                None,  # storageContinuationToken
//                parsers.to_timestamp(event_timestamp),  # eventTimestamp
//            ]
//        ], use_json=False)
//        try:
//            res = schemas.CLIENT_GET_CONVERSATION_RESPONSE.parse(
//                javascript.loads(res.body.decode())
//            )
//        except ValueError as e:
//            raise exceptions.NetworkError('Response failed to parse: {}'
//                                          .format(e))
//        # can return 200 but still contain an error
//        status = res.response_header.status
//        if status != 1:
//            raise exceptions.NetworkError('Response status is \'{}\''
//                                          .format(status))
//        return res
//
//    @asyncio.coroutine
//    def syncrecentconversations(self):
//        """List the contents of recent conversations, including messages.
//
//        Similar to syncallnewevents, but appears to return a limited number of
//        conversations (20) rather than all conversations in a given date range.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        res = yield from self._request('conversations/syncrecentconversations',
//                                       [self._get_request_header()])
//        return json.loads(res.body.decode())
//
//    @asyncio.coroutine
//    def setchatname(self, conversation_id, name):
//        """Set the name of a conversation.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        client_generated_id = random.randint(0, 2 ** 32)
//        body = [
//            self._get_request_header(),
//            None,
//            name,
//            None,
//            [[conversation_id], client_generated_id, 1]
//        ]
//        res = yield from self._request('conversations/renameconversation',
//                                       body)
//        res = json.loads(res.body.decode())
//        res_status = res['response_header']['status']
//        if res_status != 'OK':
//            logger.warning('renameconversation returned status {}'
//                           .format(res_status))
//            raise exceptions.NetworkError()
//
//    @asyncio.coroutine
//    def sendeasteregg(self, conversation_id, easteregg):
//        """Send a easteregg to a conversation.
//
//        easteregg may not be empty.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        body = [
//            self._get_request_header(),
//            [conversation_id],
//            [easteregg, None, 1]
//        ]
//        res = yield from self._request('conversations/easteregg', body)
//        res = json.loads(res.body.decode())
//        res_status = res['response_header']['status']
//        if res_status != 'OK':
//            logger.warning('easteregg returned status {}'
//                           .format(res_status))
//            raise exceptions.NetworkError()
//
//    @asyncio.coroutine
//    def createconversation(self, chat_id_list, force_group=False):
//        """Create new conversation.
//
//        conversation_id must be a valid conversation ID.
//        chat_id_list is list of users which should be invited to conversation
//        (except from yourself).
//
//        New conversation ID is returned as res['conversation']['id']['id']
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        client_generated_id = random.randint(0, 2**32)
//        body = [
//            self._get_request_header(),
//            1 if len(chat_id_list) == 1 and not force_group else 2,
//            client_generated_id,
//            None,
//            [[str(chat_id), None, None, "unknown", None, []]
//             for chat_id in chat_id_list]
//        ]
//
//        res = yield from self._request('conversations/createconversation',
//                                       body)
//        # can return 200 but still contain an error
//        res = json.loads(res.body.decode())
//        res_status = res['response_header']['status']
//        if res_status != 'OK':
//            raise exceptions.NetworkError('Unexpected status: {}'
//                                          .format(res_status))
//        return res
//
//    @asyncio.coroutine
//    def adduser(self, conversation_id, chat_id_list):
//        """Add user to existing conversation.
//
//        conversation_id must be a valid conversation ID.
//        chat_id_list is list of users which should be invited to conversation.
//
//        Raises hangups.NetworkError if the request fails.
//        """
//        client_generated_id = random.randint(0, 2**32)
//        body = [
//            self._get_request_header(),
//            None,
//            [[str(chat_id), None, None, "unknown", None, []]
//             for chat_id in chat_id_list],
//            None,
//            [
//                [conversation_id], client_generated_id, 2, None, 4
//            ]
//        ]
//
//        res = yield from self._request('conversations/adduser', body)
//        # can return 200 but still contain an error
//        res = json.loads(res.body.decode())
//        res_status = res['response_header']['status']
//        if res_status != 'OK':
//            raise exceptions.NetworkError('Unexpected status: {}'
//                                          .format(res_status))
//        return res
