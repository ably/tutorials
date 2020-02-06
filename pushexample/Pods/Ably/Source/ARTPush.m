//
//  ARTPush.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPush+Private.h"
#import "ARTDeviceDetails.h"
#import "ARTDevicePushDetails.h"
#import "ARTRest+Private.h"
#import "ARTLog.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTEventEmitter.h"
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#import "ARTPushActivationStateMachine+Private.h"
#endif
#import "ARTPushAdmin.h"
#import "ARTPushActivationEvent.h"
#import "ARTClientOptions+Private.h"
#import "ARTPushAdmin+Private.h"
#import "ARTLocalDevice+Private.h"
#import "ARTDeviceStorage.h"
#import "ARTRealtime+Private.h"

@implementation ARTPush {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTPushInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (ARTPushAdmin *)admin {
    return [[ARTPushAdmin alloc] initWithInternal:_internal.admin queuedDealloc:_dealloc];
}

#if TARGET_OS_IOS

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest; {
    return [ARTPushInternal didRegisterForRemoteNotificationsWithDeviceToken:deviceToken rest:rest];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime; {
    return [ARTPushInternal didRegisterForRemoteNotificationsWithDeviceToken:deviceToken realtime:realtime];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest; {
    return [ARTPushInternal didFailToRegisterForRemoteNotificationsWithError:error rest:rest];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime; {
    return [ARTPushInternal didFailToRegisterForRemoteNotificationsWithError:error realtime:realtime];
}

- (void)activate {
    [_internal activate];
}

- (void)deactivate {
    [_internal deactivate];
}

#endif

@end

NSString *const ARTDeviceIdKey = @"ARTDeviceId";
NSString *const ARTDeviceSecretKey = @"ARTDeviceSecret";
NSString *const ARTDeviceIdentityTokenKey = @"ARTDeviceIdentityToken";
NSString *const ARTDeviceTokenKey = @"ARTDeviceToken";

@implementation ARTPushInternal {
    ARTRestInternal *_rest;
    ARTLog *_logger;
    ARTPushActivationStateMachine *_activationMachine;
}

- (instancetype)init:(ARTRestInternal *)rest {
    if (self = [super init]) {
        _rest = rest;
        _logger = [rest logger];
        _admin = [[ARTPushAdminInternal alloc] initWithRest:rest];
        _activationMachine = nil;
    }
    return self;
}

- (dispatch_queue_t)queue {
    return _rest.queue;
}

#if TARGET_OS_IOS

- (ARTPushActivationStateMachine *)activationMachine {
    if (_activationMachine == nil) {
        // -[UIApplication delegate] is an UI API call, so needs to be called from main thread.
        __block id delegate = nil;
        if ([NSThread isMainThread]) {
            delegate = UIApplication.sharedApplication.delegate;
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                delegate = UIApplication.sharedApplication.delegate;
            });
        }
        
        _activationMachine = [[ARTPushActivationStateMachine alloc] init:self->_rest delegate:delegate];
    }
    return _activationMachine;
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceTokenData restInternal:(ARTRestInternal *)rest {
    [rest.logger debug:@"ARTPush: device token data received: %@", [deviceTokenData base64EncodedStringWithOptions:0]];

    NSUInteger dataLength = deviceTokenData.length;
    const unsigned char *dataBuffer = deviceTokenData.bytes;
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", dataBuffer[i]];
    }

    NSString *deviceToken = [hexString copy];

    [rest.logger info:@"ARTPush: device token: %@", deviceToken];
    NSString *currentDeviceToken = [rest.storage objectForKey:ARTDeviceTokenKey];
    if ([currentDeviceToken isEqualToString:deviceToken]) {
        // Already stored.
        return;
    }

    [rest.device_nosync setAndPersistDeviceToken:deviceToken];
    [rest.logger debug:@"ARTPush: device token stored"];
    [rest.push.activationMachine sendEvent:[ARTPushActivationEventGotPushDeviceDetails new]];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime {
    [realtime internalAsync:^(ARTRealtimeInternal *realtime) {
        [ARTPushInternal didRegisterForRemoteNotificationsWithDeviceToken:deviceToken restInternal:realtime.rest];
    }];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken rest:(ARTRest *)rest {
    [rest internalAsync:^(ARTRestInternal *rest) {
        [ARTPushInternal didRegisterForRemoteNotificationsWithDeviceToken:deviceToken restInternal:rest];
    }];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error restInternal:(ARTRestInternal *)rest {
    [rest.logger error:@"ARTPush: device token not received (%@)", [error localizedDescription]];
    [rest.push.activationMachine sendEvent:[ARTPushActivationEventGettingDeviceRegistrationFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime {
    [realtime internalAsync:^(ARTRealtimeInternal *realtime) {
        [ARTPushInternal didFailToRegisterForRemoteNotificationsWithError:error restInternal:realtime.rest];
    }];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest {
    [rest internalAsync:^(ARTRestInternal *rest) {
        [ARTPushInternal didFailToRegisterForRemoteNotificationsWithError:error restInternal:rest];
    }];
}

- (void)activate {
    [self.activationMachine sendEvent:[ARTPushActivationEventCalledActivate new]];
}

- (void)deactivate {
    [self.activationMachine sendEvent:[ARTPushActivationEventCalledDeactivate new]];
}

#endif

@end
