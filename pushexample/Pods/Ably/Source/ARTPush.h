//
//  ARTPush.h
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

@class ARTRest;
@class ARTRealtime;
@class ARTPushAdmin;
@class ARTDeviceDetails;
@class ARTDeviceIdentityTokenDetails;

#pragma mark ARTPushRegisterer interface

#if TARGET_OS_IOS

@protocol ARTPushRegistererDelegate

/*
 Ably will call the implementation of this method when the activation process is completed with success or with failure.
 */
- (void)didActivateAblyPush:(nullable ARTErrorInfo *)error;

/*
 Ably will call the implementation of this method when the deactivation process is completed with success or with failure.
 */
- (void)didDeactivateAblyPush:(nullable ARTErrorInfo *)error;

@optional

- (void)didAblyPushRegistrationFail:(nullable ARTErrorInfo *)error;

/*
 Optional method.
 If you want to activate devices from your server, then you should implement this method (including the `ablyPushCustomDeregister:deviceId:callback` method) where the network request completion should call the callback argument to continue with the registration process.
 */
- (void)ablyPushCustomRegister:(nullable ARTErrorInfo *)error deviceDetails:(nonnull ARTDeviceDetails *)deviceDetails callback:(void (^ _Nonnull)(ARTDeviceIdentityTokenDetails * _Nullable, ARTErrorInfo * _Nullable))callback;

/*
 Optional method.
 If you want to deactivate devices from your server, then you should implement this method (including the `ablyPushCustomRegister:deviceDetails:callback` method) where the network request completion should call the callback argument to continue with the registration process.
 */
- (void)ablyPushCustomDeregister:(nullable ARTErrorInfo *)error deviceId:(nonnull ARTDeviceId *)deviceId callback:(void (^ _Nullable)(ARTErrorInfo * _Nullable))callback;

@end

#endif


#pragma mark ARTPush type

NS_ASSUME_NONNULL_BEGIN

@protocol ARTPushProtocol

- (instancetype)init NS_UNAVAILABLE;

#if TARGET_OS_IOS

/// Push Registration token

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest;
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime;

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest;
+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime;

/*
 Activating a device for push notifications and registering it with Ably. The registration process can be performed entirely from the device or from your own server using the optional `ablyPushCustomRegister:deviceDetails:callback` method.
 */
- (void)activate;

/*
 Deactivating a device for push notifications and unregistering it with Ably. The unregistration process can be performed entirely from the device or from your own server using the optional `ablyPushCustomDeregister:deviceId:callback` method.
 */
- (void)deactivate;

#endif

@end

@interface ARTPush : NSObject <ARTPushProtocol>

@property (readonly) ARTPushAdmin *admin;

@end

NS_ASSUME_NONNULL_END
