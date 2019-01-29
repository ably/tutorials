//
//  ARTPushActivationStateMachine.m
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushActivationStateMachine+Private.h"
#import "ARTPush.h"
#import "ARTPushActivationEvent.h"
#import "ARTPushActivationState.h"
#import "ARTRest+Private.h"
#import "ARTLog.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTTypes.h"
#import "ARTLocalDevice+Private.h"
#import "ARTDeviceStorage.h"
#import "ARTDevicePushDetails.h"
#import "ARTDeviceIdentityTokenDetails.h"
#import "ARTNSMutableRequest+ARTPush.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>

NSString *const ARTPushActivationCurrentStateKey = @"ARTPushActivationCurrentState";
NSString *const ARTPushActivationPendingEventsKey = @"ARTPushActivationPendingEvents";

@implementation ARTPushActivationStateMachine {
    ARTPushActivationEvent *_lastHandledEvent;
    ARTPushActivationState *_current;
    dispatch_queue_t _queue;
    dispatch_queue_t _userQueue;
}

- (instancetype)init:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
        _queue = _rest.queue;
        _userQueue = _rest.userQueue;
        // Unarchiving
        NSData *stateData = [rest.storage objectForKey:ARTPushActivationCurrentStateKey];
        _current = [NSKeyedUnarchiver unarchiveObjectWithData:stateData];
        if (!_current) {
            _current = [[ARTPushActivationStateNotActivated alloc] initWithMachine:self];
        } else {
            _current.machine = self;
        }
        NSData *pendingEventsData = [rest.storage objectForKey:ARTPushActivationPendingEventsKey];
        _pendingEvents = [NSKeyedUnarchiver unarchiveObjectWithData:pendingEventsData];
        if (!_pendingEvents) {
            _pendingEvents = [NSMutableArray array];
        }
    }
    return self;
}

- (ARTPushActivationEvent *)lastEvent {
    __block ARTPushActivationEvent *ret;
    dispatch_sync(_queue, ^{
        ret = [self lastEvent_nosync];
    });
    return ret;
}

- (ARTPushActivationEvent *)lastEvent_nosync {
    return _lastHandledEvent;
}

- (ARTPushActivationState *)current {
    __block ARTPushActivationState *ret;
    dispatch_sync(_queue, ^{
        ret = [self current_nosync];
    });
    return ret;
}

- (ARTPushActivationState *)current_nosync {
    return _current;
}

- (void)sendEvent:(ARTPushActivationEvent *)event {
dispatch_async(_queue, ^{
    [self handleEvent:event];
});
}

- (void)handleEvent:(nonnull ARTPushActivationEvent *)event {
    NSLog(@"handling event %@ from %@", NSStringFromClass(event.class), NSStringFromClass(_current.class));
    _lastHandledEvent = event;

    ARTPushActivationState *maybeNext = [_current transition:event];

    if (maybeNext == nil) {
        NSLog(@"enqueuing event: %@", NSStringFromClass(event.class));
        [_pendingEvents addObject:event];
        return;
    }
    NSLog(@"transition: %@ -> %@", NSStringFromClass(_current.class), NSStringFromClass(maybeNext.class));
    if (self.transitions) self.transitions(event, _current, maybeNext);
    _current = maybeNext;

    while (true) {
        ARTPushActivationEvent *pending = [_pendingEvents peek];
        if (pending == nil) {
            break;
        }
        NSLog(@"attempting to consume pending event: %@", NSStringFromClass(pending.class));
        maybeNext = [_current transition:pending];
        if (maybeNext == nil) {
            break;
        }
        [_pendingEvents dequeue];

        NSLog(@"transition: %@ -> %@", NSStringFromClass(_current.class), NSStringFromClass(maybeNext.class));
        if (self.transitions) self.transitions(event, _current, maybeNext);
        _current = maybeNext;
    }

    [self persist];
}

- (void)persist {
    // Archiving
    if ([_current isKindOfClass:[ARTPushActivationPersistentState class]]) {
        [self.rest.storage setObject:[NSKeyedArchiver archivedDataWithRootObject:_current] forKey:ARTPushActivationCurrentStateKey];
    }
    [self.rest.storage setObject:[NSKeyedArchiver archivedDataWithRootObject:_pendingEvents] forKey:ARTPushActivationPendingEventsKey];
}

- (void)deviceRegistration:(ARTErrorInfo *)error {
    #if TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device_nosync;

    __block id delegate;
    if (self.delegate) {
        delegate = self.delegate;
    }
    else {
        dispatch_sync(_userQueue, ^{
            // -[UIApplication delegate] is an UI API call
            delegate = UIApplication.sharedApplication.delegate;
        });
    }

    if (![delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        [NSException raise:@"ARTPushRegistererDelegate must be implemented on AppDelegate" format:@""];
    }

    // Custom register
    SEL customRegisterMethodSelector = @selector(ablyPushCustomRegister:deviceDetails:callback:);
    if ([delegate respondsToSelector:customRegisterMethodSelector]) {
        dispatch_async(_userQueue, ^{
            [delegate ablyPushCustomRegister:error deviceDetails:local callback:^(ARTDeviceIdentityTokenDetails *identityTokenDetails, ARTErrorInfo *error) {
                if (error) {
                    // Failed
                    [delegate didActivateAblyPush:error];
                    [self sendEvent:[ARTPushActivationEventGettingDeviceRegistrationFailed newWithError:error]];
                }
                else if (identityTokenDetails) {
                    // Success
                    [delegate didActivateAblyPush:nil];
                    [self sendEvent:[ARTPushActivationEventGotDeviceRegistration newWithIdentityTokenDetails:identityTokenDetails]];
                }
                else {
                    ARTErrorInfo *missingIdentityTokenError = [ARTErrorInfo createWithCode:0 message:@"Device Identity Token Details is expected"];
                    [delegate didActivateAblyPush:missingIdentityTokenError];
                    [self sendEvent:[ARTPushActivationEventGettingDeviceRegistrationFailed newWithError:missingIdentityTokenError]];
                }
            }];
        });
        return;
    }

    // Asynchronous HTTP request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[_rest defaultEncoder] encodeDeviceDetails:local error:nil];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [[_rest logger] debug:__FILE__ line:__LINE__ message:@"device registration with request %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [[self->_rest logger] error:@"%@: device registration failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventGettingDeviceRegistrationFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
            return;
        }
        NSError *decodeError = nil;
        ARTDeviceIdentityTokenDetails *identityTokenDetails = [[self->_rest defaultEncoder] decodeDeviceIdentityTokenDetails:data error:&decodeError];
        if (decodeError) {
            [[self->_rest logger] error:@"%@: decode identity token details failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventGettingDeviceRegistrationFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
            return;
        }
        [self sendEvent:[ARTPushActivationEventGotDeviceRegistration newWithIdentityTokenDetails:identityTokenDetails]];
    }];
    #endif
}

- (void)deviceUpdateRegistration:(ARTErrorInfo *)error {
    #if TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device_nosync;

    __block id delegate;
    if (self.delegate) {
        delegate = self.delegate;
    }
    else {
        dispatch_sync(_userQueue, ^{
            // -[UIApplication delegate] is an UI API call
            delegate = UIApplication.sharedApplication.delegate;
        });
    }

    if (![delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        [NSException raise:@"ARTPushRegistererDelegate must be implemented on AppDelegate" format:@""];
    }

    // Custom register
    SEL customRegisterMethodSelector = @selector(ablyPushCustomRegister:deviceDetails:callback:);
    if ([delegate respondsToSelector:customRegisterMethodSelector]) {
        dispatch_async(_userQueue, ^{
            [delegate ablyPushCustomRegister:error deviceDetails:local callback:^(ARTDeviceIdentityTokenDetails *identityTokenDetails, ARTErrorInfo *error) {
                if (error) {
                    // Failed
                    [delegate didActivateAblyPush:error];
                    [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:error]];
                }
                else if (identityTokenDetails) {
                    // Success
                    [delegate didActivateAblyPush:nil];
                    [self sendEvent:[ARTPushActivationEventRegistrationUpdated newWithIdentityTokenDetails:identityTokenDetails]];
                }
                else {
                    ARTErrorInfo *missingIdentityTokenError = [ARTErrorInfo createWithCode:0 message:@"Device Identity Token Details is expected"];
                    [delegate didActivateAblyPush:missingIdentityTokenError];
                    [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:missingIdentityTokenError]];
                }
            }];
        });
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:@"/push/deviceRegistrations"] URLByAppendingPathComponent:local.id]];
    NSData *tokenData = [local.identityTokenDetails.token dataUsingEncoding:NSUTF8StringEncoding];
    NSString *tokenBase64 = [tokenData base64EncodedStringWithOptions:0];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", tokenBase64] forHTTPHeaderField:@"Authorization"];
    request.HTTPMethod = @"PATCH";
    request.HTTPBody = [[_rest defaultEncoder] encode:@{
        @"push": @{
            @"recipient": local.push.recipient
        }
    } error:nil];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];
    [request setDeviceAuthentication:local];

    [[_rest logger] debug:__FILE__ line:__LINE__ message:@"update device with request %@", request];
    [_rest executeRequest:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [[self->_rest logger] error:@"%@: update device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
            return;
        }
        NSError *decodeError = nil;
        ARTDeviceIdentityTokenDetails *identityTokenDetails = [[self->_rest defaultEncoder] decodeDeviceIdentityTokenDetails:data error:&decodeError];
        if (decodeError) {
            [[self->_rest logger] error:@"%@: decode identity token details failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
            return;
        }
        [self sendEvent:[ARTPushActivationEventRegistrationUpdated newWithIdentityTokenDetails:identityTokenDetails]];
    }];
    #endif
}

- (void)deviceUnregistration:(ARTErrorInfo *)error {
    #if TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device_nosync;

    __block id delegate;
    if (self.delegate) {
        delegate = self.delegate;
    }
    else {
        dispatch_sync(_userQueue, ^{
            // -[UIApplication delegate] is an UI API call
            delegate = UIApplication.sharedApplication.delegate;
        });
    }

    // Custom register
    SEL customDeregisterMethodSelector = @selector(ablyPushCustomDeregister:deviceId:callback:);
    if ([delegate respondsToSelector:customDeregisterMethodSelector]) {
        dispatch_async(_userQueue, ^{
            [delegate ablyPushCustomDeregister:error deviceId:local.id callback:^(ARTErrorInfo *error) {
                if (error) {
                    // Failed
                    [delegate didDeactivateAblyPush:error];
                    [self sendEvent:[ARTPushActivationEventDeregistrationFailed newWithError:error]];
                }
                else {
                    // Success
                    [delegate didDeactivateAblyPush:nil];
                    [self sendEvent:[ARTPushActivationEventDeregistered new]];
                }
            }];
        });
        return;
    }

    // Asynchronous HTTP request
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"] resolvingAgainstBaseURL:NO];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"deviceId" value:local.id],
    ];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";
    [request setDeviceAuthentication:local];

    [[_rest logger] debug:__FILE__ line:__LINE__ message:@"device deregistration with request %@", request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [[self->_rest logger] error:@"%@: device deregistration failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventDeregistrationFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
            return;
        }
        [[self->_rest logger] debug:__FILE__ line:__LINE__ message:@"successfully deactivate device"];
        [self sendEvent:[ARTPushActivationEventDeregistered new]];
    }];
    #endif
}

- (void)callActivatedCallback:(ARTErrorInfo *)error {
    #if TARGET_OS_IOS
dispatch_async(_userQueue, ^{
    id delegate;
    if (self.delegate) {
        delegate = self.delegate;
    }
    else {
        delegate = UIApplication.sharedApplication.delegate;
    }

    if ([delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        SEL activateCallbackMethodSelector = @selector(didActivateAblyPush:);
        if ([delegate respondsToSelector:activateCallbackMethodSelector]) {
            [delegate didActivateAblyPush:error];
        }
    }
});
    #endif
}

- (void)callDeactivatedCallback:(ARTErrorInfo *)error {
    #if TARGET_OS_IOS
dispatch_async(_userQueue, ^{
    id delegate;
    if (self.delegate) {
        delegate = self.delegate;
    }
    else {
        delegate = UIApplication.sharedApplication.delegate;
    }

    if ([delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        SEL deactivateCallbackMethodSelector = @selector(didDeactivateAblyPush:);
        if ([delegate respondsToSelector:deactivateCallbackMethodSelector]) {
            [delegate didDeactivateAblyPush:error];
        }
    }
});
    #endif
}

- (void)callUpdateFailedCallback:(nullable ARTErrorInfo *)error {
    #if TARGET_OS_IOS
dispatch_async(_userQueue, ^{
    id delegate;
    if (self.delegate) {
        delegate = self.delegate;
    }
    else {
        delegate = UIApplication.sharedApplication.delegate;
    }

    if ([delegate conformsToProtocol:@protocol(ARTPushRegistererDelegate)]) {
        SEL updateFailedCallbackMethodSelector = @selector(didAblyPushRegistrationFail:);
        if ([delegate respondsToSelector:updateFailedCallbackMethodSelector]) {
            [delegate didAblyPushRegistrationFail:error];
        }
    }
});
    #endif
}

@end

#endif
