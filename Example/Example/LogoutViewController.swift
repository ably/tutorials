//
//  LogoutViewController.swift
//  Example
//
//  Created by Joanna Kubiak on 22.10.2016.
//  Copyright © 2016 example. All rights reserved.
//

import UIKit
import Ably

class LogoutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "toLoginSegue" {
            /* Close current connection and log out */
            client.connection.close()
            client = nil
        }
    }

}
