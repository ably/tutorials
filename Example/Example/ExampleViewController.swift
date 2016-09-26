//
//  ExampleViewController.swift
//  Example
//
//  Created by Joanna Kubiak on 22.09.2016.
//  Copyright © 2016 example. All rights reserved.
//

import UIKit
import AblyRealtime

class ExampleViewController: UIViewController, UITableViewDataSource {

    private let API_KEY = "INSERT-YOUR-API-KEY-HERE" /* Add your API key here */

    @IBOutlet private  weak var tableView: UITableView!
    @IBOutlet private  weak var historyTextLabel: UILabel!

    private var client: ARTRealtime!
    private var channel: ARTRealtimeChannel!
    private var historyMessages: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        /*Show alert if API_KEY is not set properly*/
        guard API_KEY.rangeOfString("INSERT") == nil else {
            return showAlert("Error", message: "You have not set the API key, please configure the API_KEY in ExampleViewController.swift to run this demo.")
        }

        /* Instance the Ably library */
        client = ARTRealtime(key: API_KEY)
        client.connection.on { state in
            if let state = state {
                switch state.current {
                case .Connected:
                    self.showAlert("Connected", message: "Successfully connected to API.")
                case .Failed:
                    self.showAlert("Failed", message: "There was a problem connecting to API")
                default:
                    break
                }
            }
        }
    }

    /* Publish messages when the button is pressed */
    @IBAction func publishAction(sender: AnyObject) {
        /* Get channel for storing sounds */
        channel = client.channels.get("persisted:sounds")
        /* Publish 3 messages to the channel */
        channel.publish("play", data: "bark")
        channel.publish("play", data: "meow")
        channel.publish("play", data: "cluck")

        showAlert("", message: "Messages have been sent.")
    }

    /* Retrieve messages from history */
    @IBAction func retriveHistoryAction(sender: AnyObject) {
        channel = client.channels.get("persisted:sounds")
        historyMessages = []

        channel.history() { (messages, error) in
            guard error == nil else {
                return self.showAlert("Error", message: "There was a an error retriving messages history.")
            }

            let historyMessages = messages?.items as? [ARTMessage] ?? [ARTMessage]()
            historyMessages.forEach { message in
                self.historyMessages.append("\(message.data)")
            }
            /* Reload new messages in tableView */
            self.tableView.reloadData()
        }
    }

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))

        self.presentViewController(alertController, animated: true, completion: nil)
    }


    // MARK:  UITableViewDataSource Methods

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyMessages.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let row = indexPath.row
        cell.textLabel?.text = historyMessages[row]
        
        return cell
    }
    
}
