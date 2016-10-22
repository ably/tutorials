//
//  ExampleViewController.swift
//  Example
//
//  Created by Joanna Kubiak on 22.10.2016.
//  Copyright © 2016 example. All rights reserved.
//

import UIKit
import Ably

var client: ARTRealtime!

class ExampleViewController: UIViewController {

    @IBOutlet weak var usernameText: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    /* Performs the login action */
    @IBAction func loginAction(sender: AnyObject) {
        connectToAbly()
    }

    private func connectToAbly() {
        /* Set up a Realtime client that authenticates with the local web server auth endpoint */
        let options = ARTClientOptions()
        /* Check if user provided with a login */
        if let clientId = usernameText.text where !clientId.isEmpty {
            options.authUrl = NSURL(string: "http://localhost:4567/auth?username=\(clientId)")
        } else {
            options.authUrl = NSURL(string: "http://localhost:4567/auth")
        }

        /* Instance the Ably library */
        client = ARTRealtime(options: options)
        client.connection.on { state in
            if let state = state {
                switch state.current {
                case .Connected:
                    self.updateSuccessState()
                case .Failed:
                    print( client.connection.errorReason)
                    self.showAlert("Failed", message: "There was a problem connecting to API", success: false)
                default:
                    break
                }
            }
        }
    }

    /* Create message for successful login depending on whether the user has entered username */
    private func updateSuccessState() {
        var alertMessage = ""
        if let clientId = client.auth.clientId {
            alertMessage = "You are now connected to Ably \n User: \(clientId) \n Capabilities: {\"*\":[\"publish\",\"subscribe\"]}"
        } else {
            alertMessage = "You are now connected to Ably \n User: anonymous \n Capabilities: {\"notifications\":[\"subscribe\"]}"
        }
        self.showAlert("Connected", message: alertMessage, success: true)
    }

    /*performs segue to the LogoutViewController */
    private func performSegue() {
            self.performSegueWithIdentifier("logoutSegue", sender: self)
    }

    private func showAlert(title: String, message: String, success: Bool) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        /* If authentication was successful clicking on OK will perform a segue */
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: {action in
            if success {
                    self.performSegue()
            } else {
                return
            }
        }))

        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
