//
//  AppDelegate.swift
//  srushtika-tut-fixes
//
//  Created by Srushtika Neelakantam on 06/01/2020.
//  Copyright © 2020 Srushtika Neelakantam. All rights reserved.
//

import UIKit
import Ably
import UserNotifications

let authURL = ""
let API_KEY = ""
let myClientId = "abc"
let ablyClientOptions = ARTClientOptions()


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ARTPushRegistererDelegate {
    func didDeactivateAblyPush(_ error: ARTErrorInfo?) {
        print("** push deactivated")
    }
    

    var window: UIWindow?
    var realtime: ARTRealtime!
    var channel: ARTRealtimeChannel!
    var subscribed = false
    
    //on launch, init ably and call activate
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        print("** app launched")

       UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]) { (granted, err) in
           DispatchQueue.main.async() {
               UIApplication.shared.registerForRemoteNotifications()
               print("** request to show notifications successful")
           }
       }
        
       self.realtime = self.getAblyRealtime()
       self.realtime.push.activate()
        
        return true
    }
    
    //register with APNs - returns deviceToken
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        DispatchQueue.main.async() {
            print("** didRegisterForRemoteNotificationsWithDeviceToken")
            ARTPush.didRegisterForRemoteNotifications(withDeviceToken: deviceToken, realtime: self.getAblyRealtime())
        }
    }

    //register with APNs with error - returns error
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DispatchQueue.main.async() {
            print("** didFailToRegisterForRemoteNotificationsWithError")
            ARTPush.didFailToRegisterForRemoteNotificationsWithError(error, realtime: self.getAblyRealtime())
        }
    }
    
    // function to init ably with client options - key and clientId
    private func getAblyRealtime() -> ARTRealtime {
        ablyClientOptions.clientId = myClientId
        ablyClientOptions.key = API_KEY
        realtime = ARTRealtime(options: ablyClientOptions)
        return realtime
    }
    
    // delegate method to handle push activation with Ably | also includes subscribing the device to push on channel
    func didActivateAblyPush(_ error: ARTErrorInfo?) {
        if let error = error {
            // Handle error
            print("** push activation failed, err=\(String(describing: error))")
            return
        }
        print("** push activated successfully")

        self.channel = self.realtime.channels.get("push")
        self.channel.push.subscribeDevice { (err) in
            DispatchQueue.main.async {
                print("** device ID \(self.realtime.device.id)")
            }
            print("** channel.push.subscribeDevice: err=\(String(describing: err))")
            self.subscribed = true
        }
    }
    
    // optional function to detect when a remote notification is received by the device
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("** received notification: \(userInfo)")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

