//
//  ExampleViewController.swift
//  Example
//
//  Created by Joanna Kubiak on 22.09.2016.
//  Copyright © 2016 example. All rights reserved.
//

import UIKit
import AblyRealtime

class ExampleViewController: UIViewController {

    private let API_KEY = "INSERT-YOUR-API-KEY-HERE" /* Add your API key here */

    @IBOutlet weak var receivedMessageText: UILabel!

    private var client: ARTRealtime!
    private var channel: ARTRealtimeChannel!

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

    /* Subscribe to messages on the sport channel */
    @IBAction func subscribeAction(sender: AnyObject) {
        channel = client.channels.get("sport")
        self.receivedMessageText.text = ""

        channel.subscribe { message in
            self.receivedMessageText.text = "\(message.data)"
        }
    }


    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))

        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
}
