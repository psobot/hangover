//
//  ConversationViewController.swift
//  Hangover
//
//  Created by Peter Sobot on 6/9/15.
//  Copyright © 2015 Peter Sobot. All rights reserved.
//

import Cocoa
import Alamofire

class ConversationViewController:
    NSViewController,
    ConversationDelegate,
    NSTableViewDataSource,
    NSTableViewDelegate,
    NSTextFieldDelegate {

    @IBOutlet weak var conversationTableView: NSTableView!
    @IBOutlet weak var messageTextField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        conversationTableView.setDataSource(self)
        conversationTableView.setDelegate(self)

        messageTextField.delegate = self

        self.view.postsFrameChangedNotifications = true
    }

    override func viewWillAppear() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("windowDidBecomeKey:"),
            name: NSWindowDidBecomeKeyNotification,
            object: self.window
        )

        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("frameDidChangeNotification:"),
            name: NSViewFrameDidChangeNotification,
            object: self.view
        );

        if self.window?.keyWindow ?? false {
            self.windowDidBecomeKey(nil)
        }

        if let window = self.window, name = conversation?.name {
            window.title = name
        }
    }

    override func viewWillDisappear() {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: NSWindowDidBecomeKeyNotification,
            object: self.view.window
        )
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name:NSViewBoundsDidChangeNotification,
            object:self.view
        );
    }

    override var representedObject: AnyObject? {
        didSet {
            if let oldConversation = oldValue as? Conversation {
                oldConversation.delegate = nil
            }

            self.conversation?.delegate = self
            self.conversation?.getEvents(conversation?.events.first?.id, max_events: 50)
            conversationTableView.reloadData()
            conversationTableView.scrollRowToVisible(self.numberOfRowsInTableView(conversationTableView) - 1)
        }
    }

    var conversation: Conversation? {
        get {
            return representedObject as? Conversation
        }
    }

    var window: NSWindow? {
        get {
            return self.view.window
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

    // MARK: NSTableViewDelegate
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let message = conversation?.messages[row] {
            if let user = conversation?.user_list.get_user(message.user_id) {
                var view = tableView.makeViewWithIdentifier(ChatMessageView.className(), owner: self) as? ChatMessageView

                if view == nil {
                    view = ChatMessageView(frame: NSZeroRect)
                    view!.identifier = ChatMessageView.className()
                }

                view!.configureWithMessage(message, user: user)
                return view
            }
        }
        return nil
    }

    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if let message = conversation?.messages[row] {
            return ChatMessageView.heightForWidth(message.text, width: self.view.frame.width)
        } else {
            return 0
        }
    }

    // MARK: Window notifications

    func windowDidBecomeKey(sender: AnyObject?) {
        //  Delay here to ensure that small context switches don't send focus messages.
        delay(1) {
            if let window = self.window where window.keyWindow {
                self.conversation?.setFocus()
            }
        }
    }

    func frameDidChangeNotification(sender: AnyObject?) {
        //  TODO: This is a horrible, horrible way to do this, and super CPU-intensive.
        //  B U T   I T   W O R K S   F O R   N O W
        conversationTableView.reloadData()
    }

    // MARK: NSTextFieldDelegate
    var lastTypingTimestamp: NSDate?
    override func controlTextDidChange(obj: NSNotification) {
        if messageTextField.stringValue == "" {
            return
        }

        let typingTimeout = 0.4
        let now = NSDate()

        if lastTypingTimestamp == nil || NSDate().timeIntervalSinceDate(lastTypingTimestamp!) > typingTimeout {
            self.conversation?.setTyping(TypingStatus.TYPING)
        }

        lastTypingTimestamp = now
        delay(typingTimeout) {
            if let ts = self.lastTypingTimestamp where NSDate().timeIntervalSinceDate(ts) > typingTimeout {
                self.conversation?.setTyping(TypingStatus.STOPPED)
            }
        }
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
