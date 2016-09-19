//
//  ExampleViewController.swift
//  example
//
//  Created by Joanna Kubiak on 19.09.2016.
//  Copyright © 2016 Ably. All rights reserved.
//

import UIKit
import AblyRealtime

class ExampleViewController: UIViewController {

    private let API_KEY = "INSERT-YOU-API-KEY-HERE" /* Add your API key here */

    private var client: ARTRealtime!
    private var channel: ARTRealtimeChannel!

    override func viewDidLoad() {
        super.viewDidLoad()

        /* Instance the Ably library */
        client = ARTRealtime(key: API_KEY)
    }

    @IBAction func subscribeAction(sender: AnyObject) {
        /* Subscribe to messages on the sport channel */
        channel = client.channels.get("sport")
        channel.subscribe { message in
            print("Received \(message.data)")
        }
    }

    /* Publish a message when the button is pressed */
    @IBAction func publishAction(sender: AnyObject) {
        channel.publish("update", data: "Man United") { error in
            guard error == nil else {
                /* Print an error message when error occurres */
                print("Message not sent, error occurred: \(error!)")
                return
            }
            /* Print a success message when the message is sent */
            print("Message successfully sent")
        }
    }
}
