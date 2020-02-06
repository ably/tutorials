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
#import "ARTAuth+Private.h"

#if TARGET_OS_IOS

NSString *const ARTPushActivationCurrentStateKey = @"ARTPushActivationCurrentState";
NSString *const ARTPushActivationPendingEventsKey = @"ARTPushActivationPendingEvents";

@implementation ARTPushActivationStateMachine {
    ARTPushActivationEvent *_lastHandledEvent;
    ARTPushActivationState *_current;
    dispatch_queue_t _queue;
    dispatch_queue_t _userQueue;
}

- (instancetype)init:(ARTRestInternal *)rest {
    return [self init:rest delegate:nil];
}

- (instancetype)init:(ARTRestInternal *)rest delegate:(id)delegate {
    if (self = [super init]) {
        _rest = rest;
        _delegate = delegate;
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

        // Due to bug #966, old versions of the library might have led us to an illegal
        // persisted state: we have a deviceToken, but the persisted push state is WaitingForPushDeviceDetails.
        // So we need to re-emit the GotPushDeviceDetails event that led us there.
        if ([_current isKindOfClass:[ARTPushActivationStateWaitingForPushDeviceDetails class]] && rest.device_nosync.deviceToken != nil) {
            [rest.logger debug:@"ARTPush: re-emitting stored device details for stuck state machine"];
            [self handleEvent:[ARTPushActivationEventGotPushDeviceDetails new]];
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
    [_rest.logger debug:@"%@: handling event %@ from %@", NSStringFromClass(self.class), NSStringFromClass(event.class), NSStringFromClass(_current.class)];
    _lastHandledEvent = event;

    ARTPushActivationState *maybeNext = [_current transition:event];

    if (maybeNext == nil) {
        [_rest.logger debug:@"%@: enqueuing event: %@", NSStringFromClass(self.class), NSStringFromClass(event.class)];
        [_pendingEvents addObject:event];
        return;
    }
    [_rest.logger debug:@"%@: transition: %@ -> %@", NSStringFromClass(self.class), NSStringFromClass(_current.class), NSStringFromClass(maybeNext.class)];
    if (self.transitions) self.transitions(event, _current, maybeNext);
    _current = maybeNext;

    while (true) {
        ARTPushActivationEvent *pending = [_pendingEvents peek];
        if (pending == nil) {
            break;
        }
        [_rest.logger debug:@"%@: attempting to consume pending event: %@", NSStringFromClass(self.class), NSStringFromClass(pending.class)];
        maybeNext = [_current transition:pending];
        if (maybeNext == nil) {
            break;
        }
        [_pendingEvents dequeue];

        [_rest.logger debug:@"%@: transition: %@ -> %@", NSStringFromClass(self.class), NSStringFromClass(_current.class), NSStringFromClass(maybeNext.class)];
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

    __block id delegate = self.delegate;

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
                    [self sendEvent:[ARTPushActivationEventGettingDeviceRegistrationFailed newWithError:error]];
                }
                else if (identityTokenDetails) {
                    // Success
                    [self sendEvent:[ARTPushActivationEventGotDeviceRegistration newWithIdentityTokenDetails:identityTokenDetails]];
                }
                else {
                    ARTErrorInfo *missingIdentityTokenError = [ARTErrorInfo createWithCode:0 message:@"Device Identity Token Details is expected"];
                    [self sendEvent:[ARTPushActivationEventGettingDeviceRegistrationFailed newWithError:missingIdentityTokenError]];
                }
            }];
        });
        return;
    }

    void (^doDeviceRegistration)(void) = ^{
        // Asynchronous HTTP request
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"]];
        request.HTTPMethod = @"POST";
        request.HTTPBody = [[self->_rest defaultEncoder] encodeDeviceDetails:local error:nil];
        [request setValue:[[self->_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

        [[self->_rest logger] debug:__FILE__ line:__LINE__ message:@"%@: device registration with request %@", NSStringFromClass(self.class), request];
        [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
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
    };

    if (_rest.auth.method == ARTAuthMethodToken) {
        [_rest.auth authorize:^(ARTTokenDetails *tokenDetails, NSError *error) {
            doDeviceRegistration();
        }];
    }
    else {
        doDeviceRegistration();
    }
    #endif
}

- (void)deviceUpdateRegistration:(ARTErrorInfo *)error {
    #if TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device_nosync;

    __block id delegate = self.delegate;

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
                    [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:error]];
                }
                else if (identityTokenDetails) {
                    // Success
                    [self sendEvent:[ARTPushActivationEventRegistrationUpdated newWithIdentityTokenDetails:identityTokenDetails]];
                }
                else {
                    ARTErrorInfo *missingIdentityTokenError = [ARTErrorInfo createWithCode:0 message:@"Device Identity Token Details is expected"];
                    [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:missingIdentityTokenError]];
                }
            }];
        });
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:@"/push/deviceRegistrations"] URLByAppendingPathComponent:local.id]];
    request.HTTPMethod = @"PATCH";
    request.HTTPBody = [[_rest defaultEncoder] encode:@{
        @"push": @{
            @"recipient": local.push.recipient
        }
    } error:nil];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];
    [request setDeviceAuthentication:local];

    [[_rest logger] debug:__FILE__ line:__LINE__ message:@"%@: update device with request %@", NSStringFromClass(self.class), request];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [[self->_rest logger] error:@"%@: update device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            [self sendEvent:[ARTPushActivationEventUpdatingRegistrationFailed newWithError:[ARTErrorInfo createFromNSError:error]]];
            return;
        }
        [self sendEvent:[ARTPushActivationEventRegistrationUpdated new]];
    }];
    #endif
}

- (void)deviceUnregistration:(ARTErrorInfo *)error {
    #if TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device_nosync;

    __block id delegate = self.delegate;

    // Custom register
    SEL customDeregisterMethodSelector = @selector(ablyPushCustomDeregister:deviceId:callback:);
    if ([delegate respondsToSelector:customDeregisterMethodSelector]) {
        dispatch_async(_userQueue, ^{
            [delegate ablyPushCustomDeregister:error deviceId:local.id callback:^(ARTErrorInfo *error) {
                if (error) {
                    // Failed
                    [self sendEvent:[ARTPushActivationEventDeregistrationFailed newWithError:error]];
                }
                else {
                    // Success
                    [self sendEvent:[ARTPushActivationEventDeregistered new]];
                }
            }];
        });
        return;
    }

    // Asynchronous HTTP request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:@"/push/deviceRegistrations"] URLByAppendingPathComponent:local.id]];
    request.HTTPMethod = @"DELETE";
    [request setDeviceAuthentication:local];

    [[_rest logger] debug:__FILE__ line:__LINE__ message:@"%@: device deregistration with request %@", NSStringFromClass(self.class), request];
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
        id delegate = self.delegate;
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
        id delegate = self.delegate;
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
        id delegate = self.delegate;
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
