//
//  ConversationViewController.swift
//  Hangover
//
//  Created by Peter Sobot on 6/9/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Cocoa
import Alamofire

class ConversationViewController: NSViewController, ConversationDelegate, NSTableViewDataSource {

    @IBOutlet weak var conversationTableView: NSTableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        conversationTableView.setDataSource(self)
    }

    override func viewWillAppear() {
        self.conversation?.getEvents(conversation?.events.first?.id, max_events: 50)
    }

    override var representedObject: AnyObject? {
        didSet {
            self.conversation?.delegate = self
        }
    }

    var conversation: Conversation? {
        get {
            return representedObject as? Conversation
        }
    }

    // conversation delegate
    func conversation(conversation: Conversation, didChangeTypingStatusTo: TypingStatus) {

    }

    func conversation(conversation: Conversation, didReceiveEvent: ConversationEvent) {

    }

    func conversation(conversation: Conversation, didReceiveWatermarkNotification: WatermarkNotification) {

    }

    func conversationDidUpdateEvents(conversation: Conversation) {
        conversationTableView.reloadData()
    }

    // NSTableViewDataSource delegate
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return conversation?.messages.count ?? 0
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if let message = conversation?.messages[row] {
            return message.text
        }
        return nil
    }
}
