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

        /* Create an authentication callback that will obtain a TokenRequest */
        options.authCallback = { params, callback in
            self.getTokenRequest() { json, error in

                do {
                    callback(try ARTTokenRequest.fromJson(json!), nil)
                } catch let error as NSError {
                    callback(nil, error)
                    }
            }
        }

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


    /*  issue asynchronous query to obtain token request */
    func getTokenRequest(completion: (NSDictionary?, ErrorType?) -> ())  {

        /* If you want to try running this application on your mobile device change "localhost" tou your server IP */
        let requestURL: NSURL = NSURL(string: "http://localhost:4567/auth")!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in

            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode

            if (statusCode == 200) {

                do{

                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments) as! NSDictionary

                    completion(json, nil)

                } catch {
                    self.showAlert("Error", message: "There was an error while obtaining JSON")
                }
            }
        }
        task.resume()
    }

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))

        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
