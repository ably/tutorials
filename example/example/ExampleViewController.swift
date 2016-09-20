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

    private let API_KEY = "INSERT-YOU-API-KEY-HERE" /* Add your API key here */

    private var client: ARTRealtime!

    override func viewDidLoad() {
        super.viewDidLoad()
        /* Instance the Ably library */
        client = ARTRealtime(key: API_KEY)
    }

    @IBAction func publishAction(sender: AnyObject) {
    }

    @IBAction func retriveHistoryAction(sender: AnyObject) {
    }

}
