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

- (void)didActivateAblyPush:(nullable ARTErrorInfo *)error;
- (void)didDeactivateAblyPush:(nullable ARTErrorInfo *)error;

@optional

- (void)didAblyPushRegistrationFail:(nullable ARTErrorInfo *)error;

- (void)ablyPushCustomRegister:(nullable ARTErrorInfo *)error deviceDetails:(nullable ARTDeviceDetails *)deviceDetails callback:(void (^ _Nonnull)(ARTDeviceIdentityTokenDetails * _Nullable, ARTErrorInfo * _Nullable))callback;
- (void)ablyPushCustomDeregister:(nullable ARTErrorInfo *)error deviceId:(nullable ARTDeviceId *)deviceId callback:(void (^ _Nullable)(ARTErrorInfo * _Nullable))callback;

@end

#endif


#pragma mark ARTPush type

NS_ASSUME_NONNULL_BEGIN

@interface ARTPush : NSObject

@property (nonatomic, strong, readonly) ARTPushAdmin *admin;

- (instancetype)init NS_UNAVAILABLE;

#if TARGET_OS_IOS

/// Push Registration token

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest;
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime;

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest;
+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime;

/// Register a device, including the information necessary to deliver push notifications to it.
- (void)activate;

/// Unregister a device.
- (void)deactivate;

#endif

@end

NS_ASSUME_NONNULL_END
