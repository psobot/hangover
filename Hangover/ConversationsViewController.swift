//
//  ConversationsViewController.swift
//  Hangover
//
//  Created by Peter Sobot on 5/24/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Cocoa
import Alamofire

class ConversationsViewController: NSViewController, ClientDelegate, NSTableViewDataSource, NSTableViewDelegate, NSSplitViewDelegate, ConversationListDelegate {

    @IBOutlet weak var conversationTableView: NSTableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        //  TODO: Don't do this here
        if let splitView = (self.parentViewController as? NSSplitViewController)?.splitView {
            splitView.delegate = self
        }

        conversationTableView.setDataSource(self)
        conversationTableView.setDelegate(self)

        //  TODO: Move this out to AppDelegate
        withAuthenticatedManager { (manager: Alamofire.Manager) in
            self.representedObject = Client(manager: manager)
            self.client?.delegate = self
            self.client?.connect()
        }
    }

    override var representedObject: AnyObject? {
        didSet {
            
        }
    }

    var client: Client? {
        get {
            return representedObject as? Client
        }
    }

    // MARK: Client Delegate
    var conversationList: ConversationList? {
        didSet {
            conversationList?.delegate = self
            conversationTableView.reloadData()
        }
    }

    func clientDidConnect(client: Client, initialData: InitialData) {
        build_user_list(client, initial_data: initialData) { user_list in
            print("Got user list: \(user_list)")
            self.conversationList = ConversationList(
                client: client,
                conv_states: initialData.conversation_states,
                user_list: user_list,
                sync_timestamp: initialData.sync_timestamp
            )
            print("Conversation list: \(self.conversationList)")
            self.conversationTableView.reloadData()
            self.conversationTableView.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
        }
    }

    func clientDidDisconnect(client: Client) {

    }

    func clientDidReconnect(client: Client) {

    }

    func clientDidUpdateState(client: Client, update: CLIENT_STATE_UPDATE) {
        
    }

    // MARK: NSTableViewDataSource delegate
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return conversationList?.conv_dict.count ?? 0
    }

    func tableViewSelectionDidChange(notification: NSNotification) {
        if conversationTableView.selectedRow >= 0 {
            selectConversation(conversationList?.get_all()[conversationTableView.selectedRow])
        } else {
            selectConversation(nil)
        }
    }

    // MARK: NSTableViewDelegate

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let conversation = conversationList?.get_all()[row] {
            var view = tableView.makeViewWithIdentifier("ConversationListItemView", owner: self) as? ConversationListItemView

            if view == nil {
                view = ConversationListItemView.instantiateFromNib(identifier: "ConversationListItemView", owner: self)
                view!.identifier = "ConversationListItemView"
            }

            view!.configureWithConversation(conversation)
            return view
        }
        return nil
    }

    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 64
    }

    // MARK: NSSplitViewDelegate
    func splitView(
        splitView: NSSplitView,
        constrainSplitPosition proposedPosition: CGFloat,
        ofSubviewAt dividerIndex: Int
    ) -> CGFloat {
        switch (dividerIndex) {
        case 0: return 270
        default: return proposedPosition
        }
    }

    func splitView(splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        return splitView.subviews.indexOf(view) != 0
    }

    func splitView(splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
        let dividerThickness = CGFloat(0)

        let leftViewSize = NSMakeSize(
            270,
            splitView.frame.size.height
        )
        let rightViewSize = NSMakeSize(
            splitView.frame.size.width - leftViewSize.width - dividerThickness,
            splitView.frame.size.height
        )

        // Resizing and placing the left view
        splitView.subviews[0].setFrameOrigin(NSMakePoint(0, 0))
        splitView.subviews[0].setFrameSize(leftViewSize)

        // Resizing and placing the right view
        splitView.subviews[1].setFrameOrigin(NSMakePoint(leftViewSize.width + dividerThickness, 0))
        splitView.subviews[1].setFrameSize(rightViewSize)
    }
    
    // MARK: ConversationListDelegate
    func conversationList(list: ConversationList, didReceiveEvent event: ConversationEvent) {

    }

    func conversationList(list: ConversationList, didChangeTypingStatusTo status: TypingStatus) {

    }

    func conversationList(list: ConversationList, didReceiveWatermarkNotification status: WatermarkNotification) {

    }

    func conversationListDidUpdate(list: ConversationList) {
        conversationTableView.reloadData()
    }

    func conversationList(list: ConversationList, didUpdateConversation conversation: Conversation) {
        //  TODO: Just update the one row that needs updating
        conversationTableView.reloadData()
    }

    // MARK: IBActions

    func selectConversation(conversation: Conversation?) {
        if let conversationViewController = (self.parentViewController as? NSSplitViewController)?.splitViewItems[1].viewController as? ConversationViewController {
            conversationViewController.representedObject = conversation
        }
    }
}

