//
//  ExampleViewController.swift
//  example
//
//  Created by Joanna Kubiak on 20.09.2016.
//  Copyright © 2016 Ably. All rights reserved.
//

import UIKit
import AblyRealtime

class ExampleViewController: UIViewController {

    private let API_KEY = "INSERT-YOUR-API-KEY-HERE7" /* Add your API key here */

    private var client: ARTRealtime!

    override func viewDidLoad() {
        super.viewDidLoad()
        /* Instance the Ably library */
        client = ARTRealtime(key: API_KEY)
    }

    /* Publish messages when the button is pressed */
    @IBAction func publishAction(sender: AnyObject) {
        /* Get channel for storing sounds */
        let channel = client.channels.get("persisted:sounds")
        /* Publish 3 messages to the channel */
        channel.publish("play", data: "bark")
        channel.publish("play", data: "meow")
        channel.publish("play", data: "cluck")
    }

    /* Retrieve messages from history */
    @IBAction func retriveHistoryAction(sender: AnyObject) {
        let channel = client.channels.get("persisted:sounds")

        channel.history() { (messages, error) in
            guard error == nil else {
                print("Error occured while retriving messages: \(error)")
                return
            }

            let historyMessages = messages?.items as? [ARTMessage] ?? [ARTMessage]()
            historyMessages.forEach { message in
                print("\(message.id) \(message.data)")
            }
        }
    }
    
}
