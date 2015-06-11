//
//  ConversationViewController.swift
//  Hangover
//
//  Created by Peter Sobot on 6/9/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Cocoa
import Alamofire

class ConversationViewController: NSViewController, ConversationDelegate, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var conversationTableView: NSTableView!
    @IBOutlet weak var messageTextField: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        conversationTableView.setDataSource(self)
        conversationTableView.setDelegate(self)
    }

    override func viewWillAppear() {
        self.conversation?.getEvents(conversation?.events.first?.id, max_events: 50)
        conversationTableView.scrollRowToVisible(self.numberOfRowsInTableView(conversationTableView) - 1)
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
        conversationTableView.reloadData()
        conversationTableView.scrollRowToVisible(self.numberOfRowsInTableView(conversationTableView) - 1)
    }

    func conversation(conversation: Conversation, didReceiveWatermarkNotification: WatermarkNotification) {

    }

    func conversationDidUpdateEvents(conversation: Conversation) {
        conversationTableView.reloadData()
        conversationTableView.scrollRowToVisible(self.numberOfRowsInTableView(conversationTableView) - 1)
    }

    // MARK: NSTableViewDataSource
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return conversation?.messages.count ?? 0
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if let message = conversation?.messages[row] {
            let user_name = conversation?.user_list.get_user(message.user_id).full_name
            return user_name! + " said: " + message.text
        }
        return nil
    }

    // MARK: NSTableViewDelegate

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let message = conversation?.messages[row] {
            if let user = conversation?.user_list.get_user(message.user_id) {
                let leftView = user.is_self ?? false
                let viewIdentifier = leftView ? "ChatMessageLeftView" : "ChatMessageRightView"

                var view = tableView.makeViewWithIdentifier(viewIdentifier, owner: self) as? ChatMessageEventView

                if view == nil {
                    view = leftView ? ChatMessageLeftView.instantiateFromNib("ChatMessageEventView", owner: self) : ChatMessageRightView.instantiateFromNib("ChatMessageEventView", owner: self)
                    view!.identifier = viewIdentifier
                }

                view!.configureWithMessage(message, user: user)
                return view
            }
        }
        return nil
    }

    // MARK: IBActions

    @IBAction func messageTextFieldDidAction(sender: AnyObject) {
        let text = messageTextField.stringValue
        if text.characters.count > 0 {
            conversation?.sendMessage([ChatMessageSegment(text: text)])
            messageTextField.stringValue = ""
        }
    }
}
