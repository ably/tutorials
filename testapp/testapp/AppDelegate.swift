//
//  AppDelegate.swift
//  testapp
//
//  Created by Christopher Batin on 16/01/2019.
//  Copyright © 2019 Christopher Batin. All rights reserved.
//

import UIKit
import Ably
import UserNotifications

// 1
let authURL = "YOUR_NGROK_HTTPS/auth"
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ARTPushRegistererDelegate {
    var window: UIWindow?
    var realtime: ARTRealtime!
    var channel: ARTRealtimeChannel!
    var subscribed = false

    //2
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        DispatchQueue.main.async() {
            print("** didRegisterForRemoteNotificationsWithDeviceToken")
            ARTPush.didRegisterForRemoteNotifications(withDeviceToken: deviceToken, realtime: self.getAblyRealtime())
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DispatchQueue.main.async() {
            print("** didFailToRegisterForRemoteNotificationsWithError")
            ARTPush.didFailToRegisterForRemoteNotificationsWithError(error, realtime: self.getAblyRealtime())
        }
    }

    //3
    private func getAblyRealtime() -> ARTRealtime {
        let options = ARTClientOptions()
        options.authCallback = { params, callback in
            self.getTokenRequest() { json, error in
                do {
                    callback(try ARTTokenRequest.fromJson(json!), nil)
                } catch let error as NSError {
                    callback(nil, error)
                }
            }
        }
        realtime = ARTRealtime(options: options)
        realtime.connection.on { state in
            if let state = state {
                switch state.current {
                case .connected:
                    print("connected")
                case .failed:
                    print("failed")
                default:
                    break
                }
            }
        }
        return realtime
    }


    // 4
    func didActivateAblyPush(_ error: ARTErrorInfo?) {
        if let error = error {
            // Handle error
            print("** push activation failed, err=\(String(describing: error))")
            return
        }
        print("** push activated")

        self.channel = self.realtime.channels.get("push")
        self.channel.attach() { (err) in
            print("** channel attached, err=\(String(describing: err))")

            self.channel.push.subscribeDevice { (err) in
                DispatchQueue.main.async {
                    print("** device ID \(self.realtime.device.id)")
                }
                print("** channel.push.subscribeDevice: err=\(String(describing: err))")
                self.subscribed = true
            }
        }
    }

    // 5
    func didDeactivateAblyPush(_ error: ARTErrorInfo?) {
        if let error = error {
            // Handle error
            print("** push de-activation failed", error)
            return
        }
        print("** push de-activated, re-activating")
        self.realtime.push.activate()
    }

    // 6
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("** received notification: \(userInfo)")
    }

    // 7
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("** hello")

        UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]) { (granted, err) in
            DispatchQueue.main.async() {
                UIApplication.shared.registerForRemoteNotifications()
                print("** after registerForRemoteNotifications")
            }
        }

        self.realtime = self.getAblyRealtime()

        // Deactivating may be necessary as the deployed app might have state inconsistent with the Ably app
        // print("** De-activating Ably push")
        // self.realtime.push.deactivate()

        self.realtime.connection.on { (stateChange) in
            print("** connection state change: \(String(describing: stateChange))")
        }

        self.realtime.connection.on(ARTRealtimeConnectionEvent.connected) { (stateChange) in
            print("** connected, resetting Ably push")
            self.realtime.push.deactivate()
        }

        return true
    }

    // 8
    func getTokenRequest(completion: @escaping (NSDictionary?, Error?) -> ())  {
        let requestURL = URL(string: authURL)!
        let urlRequest = URLRequest(url: requestURL as URL)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) {
            (data, response, error) -> Void in
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            if (statusCode == 200) {
                do{
                    let json = try JSONSerialization
                        .jsonObject(with: data!, options:.allowFragments) as! NSDictionary
                    completion(json, nil)
                } catch {
                    print("There was an error while obtaining JSON")
                }
            }
        }
        task.resume()
    }
}
