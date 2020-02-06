//
//  AppDelegate.swift
//  pushexample
//
//  Created by Srushtika Neelakantam on 06/02/2020.
//  Copyright © 2020 Srushtika Neelakantam. All rights reserved.
//

import UIKit
import Ably
import UserNotifications

let apiKey = "<YOUR-ABLY-API-KEY>"
let myClientId = "<YOUR-CLIENT-ID>"
let ablyClientOptions = ARTClientOptions()
let myPushChannel = "<YOUR-PUSH-CHANNEL>"


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ARTPushRegistererDelegate {
    

    var window: UIWindow?
    var realtime: ARTRealtime! = nil
    var channel: ARTRealtimeChannel!
    var myDeviceToken = ""
    var myDeviceId = ""
    
    // function to init ably with client options - key and clientId
    private func getAblyRealtime() -> ARTRealtime {
        if(realtime == nil){
            ablyClientOptions.clientId = myClientId
            ablyClientOptions.key = apiKey
            realtime = ARTRealtime(options: ablyClientOptions)
        }
        return realtime
    }
    
    //on launch, init ably and call activate
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UNUserNotificationCenter.current().delegate = self
        print("[LOCALLOG] App launched on the device")

       UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]) { (granted, err) in
           DispatchQueue.main.async() {
               UIApplication.shared.registerForRemoteNotifications()
               print("[LOCALLOG] Request to show notifications successful")
           }
       }
        
       self.realtime = self.getAblyRealtime()
       self.realtime.push.activate()
        
        return true
    }

    //Direct device registration with APNs to enable Push Notifications - returns deviceToken
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("[LOCALLOG] Registration for remote notifications successful")
        self.myDeviceToken = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        ARTPush.didRegisterForRemoteNotifications(withDeviceToken: deviceToken, realtime: self.getAblyRealtime())
    }
    
    //register with APNs with error - returns error
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[LOCALLOG] Error registering for remote notifications")
        ARTPush.didFailToRegisterForRemoteNotificationsWithError(error, realtime: self.getAblyRealtime())
    }
    
    
    // delegate method to handle push activation with Ably. Also includes subscribing the device to push on channel
    func didActivateAblyPush(_ error: ARTErrorInfo?) {
        if let error = error {
            // Handle error
            print("[LOCALLOG] Push activation failed, err=\(String(describing: error))")
            return
        }
        print("[LOCALLOG] Push activation successful")

        self.channel = self.realtime.channels.get(myPushChannel)
        self.channel.push.subscribeDevice { (err) in
            if(err != nil){
                print("[LOCALLOG] Device Subscription on push channel failed with err=\(String(describing: err))")
                return
            }
            self.myDeviceId = self.realtime.device.id
            print("[LOCALLOG] Client ID: " + myClientId)
            print("[LOCALLOG] Device Token: " + self.myDeviceToken)
            print("[LOCALLOG] Device ID: " + self.myDeviceId)
            print("[LOCALLOG] Push channel: " + myPushChannel)
        }
    }
    
    // method to check if push with Ably was deactivated
    func didDeactivateAblyPush(_ error: ARTErrorInfo?) {
        print("[LOCALLOG] push deactivated")
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Tell the app that we have finished processing the user's action (eg: tap on notification banner) / response
        // Handle received remoteNotification: 'response.notification.request.content.userInfo'
        // response.notification.request.content.userInfo
        print(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("[LOCALLOG] Your device just received a notification!")
        // Show the notification alert in foreground
        completionHandler([.alert, .sound])
    }
    
}
