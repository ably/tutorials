//
//  ExampleViewController.swift
//  Example
//
//  Created by Joanna Kubiak on 22.10.2016.
//  Copyright © 2016 example. All rights reserved.
//

import UIKit
import Ably

class ExampleViewController: UIViewController {

    private var client: ARTRealtime!

    override func viewDidLoad() {
        super.viewDidLoad()

        connectToAbly()
    }

    private func connectToAbly() {
        /* Set up a Realtime client that authenticates with the local web server auth endpoint */
        let options = ARTClientOptions()
        options.authUrl = NSURL(string: "http://localhost:4567/auth")

        /* Instance the Ably library */
        client = ARTRealtime(options: options)
        client.connection.on { state in
            if let state = state {
                switch state.current {
                case .Connected:
                    self.showAlert("Connected", message: "Successfully connected to API.")
                case .Failed:
                    print( self.client.connection.errorReason)
                    self.showAlert("Failed", message: "There was a problem connecting to API")
                default:
                    break
                }
            }
        }

    }

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))

        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
