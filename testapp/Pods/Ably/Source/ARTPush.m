//
//  ARTPush.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPush.h"
#import "ARTDeviceDetails.h"
#import "ARTDevicePushDetails.h"
#import "ARTRest+Private.h"
#import "ARTLog.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTEventEmitter.h"
#if TARGET_OS_IOS
#import "ARTPushActivationStateMachine.h"
#endif
#import "ARTPushAdmin.h"
#import "ARTPushActivationEvent.h"
#import "ARTClientOptions+Private.h"
#import "ARTPushAdmin+Private.h"
#import "ARTLocalDevice+Private.h"
#import "ARTDeviceStorage.h"
#import "ARTRealtime+Private.h"

NSString *const ARTDeviceIdKey = @"ARTDeviceId";
NSString *const ARTDeviceSecretKey = @"ARTDeviceSecret";
NSString *const ARTDeviceIdentityTokenKey = @"ARTDeviceIdentityToken";
NSString *const ARTDeviceTokenKey = @"ARTDeviceToken";

@implementation ARTPush {
    ARTRest *_rest;
    __weak ARTLog *_logger;
}

- (instancetype)init:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
        _logger = [rest logger];
        _admin = [[ARTPushAdmin alloc] initWithRest:rest];
    }
    return self;
}

#if TARGET_OS_IOS

- (ARTPushActivationStateMachine *)activationMachine {
    static dispatch_once_t once;
    static id activationMachineInstance;
    dispatch_once(&once, ^{
        activationMachineInstance = [[ARTPushActivationStateMachine alloc] init:self->_rest];
    });
    return activationMachineInstance;
}


+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceTokenData rest:(ARTRest *)rest {
    // HEX string, i.e.: <12ce7dda 8032c423 8f8bd40f 3484e5bb f4698da5 8b7fdf8d 5c55e0a2 XXXXXXXX>
    // Normalizing token by removing symbols and spaces, i.e.: 12ce7dda8032c4238f8bd40f3484e5bbf4698da58b7fdf8d5c55e0a2XXXXXXXX
    NSString *deviceToken = [[[deviceTokenData description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSLog(@"ARTPush: device token received %@", deviceToken);
    NSString *currentDeviceToken = [rest.storage objectForKey:ARTDeviceTokenKey];
    if ([currentDeviceToken isEqualToString:deviceToken]) {
        // Already stored.
        return;
    }

    [[rest device] setAndPersistDeviceToken:deviceToken];
    NSLog(@"ARTPush: device token stored");
    [[rest.push activationMachine] sendEvent:[ARTPushActivationEventGotPushDeviceDetails new]];
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken realtime:(ARTRealtime *)realtime {
    [ARTPush didRegisterForRemoteNotificationsWithDeviceToken:deviceToken rest:realtime.rest];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error rest:(ARTRest *)rest {
    NSLog(@"ARTPush: device token not received (%@)", [error localizedDescription]);
    [[rest.push activationMachine] sendEvent:[ARTPushActivationEventGettingDeviceRegistrationFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error realtime:(ARTRealtime *)realtime {
    [ARTPush didFailToRegisterForRemoteNotificationsWithError:error rest:realtime.rest];
}

- (void)activate {
    [[self activationMachine] sendEvent:[ARTPushActivationEventCalledActivate new]];
}

- (void)deactivate {
    [[self activationMachine] sendEvent:[ARTPushActivationEventCalledDeactivate new]];
}

#endif

@end
