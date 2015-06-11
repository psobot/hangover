//
//  ConversationsViewController.swift
//  Hangover
//
//  Created by Peter Sobot on 5/24/15.
//  Copyright (c) 2015 Peter Sobot. All rights reserved.
//

import Cocoa
import Alamofire

class ConversationsViewController: NSViewController, ClientDelegate, NSTableViewDataSource {

    @IBOutlet weak var conversationTableView: NSTableView!
    override func viewDidLoad() {
        super.viewDidLoad()

        conversationTableView.setDataSource(self)

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

    // client delegate
    var conversationList: ConversationList? {
        didSet {
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
        }
    }

    func clientDidDisconnect(client: Client) {

    }

    func clientDidReconnect(client: Client) {

    }

    func clientDidUpdateState(client: Client, update: CLIENT_STATE_UPDATE) {
        
    }

    // NSTableViewDataSource delegate
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return conversationList?.conv_dict.count ?? 0
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if let list = conversationList?.get_all() {
            return list[row].name
        }
        return nil
    }

    @IBAction func onDoubleClick(sender: AnyObject) {
        if let list = conversationList?.get_all() {
            let conversation = list[self.conversationTableView.clickedRow]
            print("Conversation: \(conversation)")

            if let conversationViewController = (self.parentViewController as? NSSplitViewController)?.splitViewItems[1].viewController as? ConversationViewController {
                conversationViewController.representedObject = conversation
            }
        } else {
            print("No conversation")
        }
    }
}

