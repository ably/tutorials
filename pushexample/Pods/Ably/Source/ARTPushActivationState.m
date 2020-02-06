//
//  ARTPushActivationState.m
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushActivationState.h"
#import "ARTPushActivationStateMachine+Private.h"
#import "ARTPushActivationEvent.h"
#import "ARTLocalDevice+Private.h"
#import "ARTDeviceStorage.h"
#import "ARTDevicePushDetails.h"
#import "ARTLog.h"
#import "ARTRest+Private.h"
#import "ARTHttp.h"

@implementation ARTPushActivationState

- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine {
    if (self = [super init]) {
        _machine = machine;
    }
    return self;
}

+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine {
    return [[self alloc] initWithMachine:machine];
}

- (void)logEventTransition:(ARTPushActivationEvent *)event file:(const char *)file line:(NSUInteger)line {
    [self.machine.rest.logger debug:@"ARTPush Activation: %@ state: handling %@ event", NSStringFromClass(self.class), NSStringFromClass(event.class)];
}

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    NSAssert(false, @"-[%s:%d %s] should always be overriden; class %@ doesn't.", __FILE__, __LINE__, __FUNCTION__, NSStringFromClass(self.class));
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    // Implement NSCopying by retaining the original instead of creating a new copy when the class and its contents are immutable.
    return self;
}

#pragma mark - NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    // Just to persist the class info, no properties
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return true;
}

#pragma mark - Archive/Unarchive

- (NSData *)archive {
    if (@available(macOS 10.13, iOS 11, tvOS 11, *)) {
        NSError *error;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self requiringSecureCoding:false error:&error];
        if (error) {
            NSLog(@"ARTPushActivationState Archive failed: %@", error);
        }
        return data;
    }
    else {
        return [NSKeyedArchiver archivedDataWithRootObject:self];
    }
}

+ (ARTPushActivationState *)unarchive:(NSData *)data {
    if (!data) {
        return nil;
    }
    if (@available(macOS 10.13, iOS 11, tvOS 11, *)) {
        NSError *error;
        ARTPushActivationState *result = [NSKeyedUnarchiver unarchivedObjectOfClass:[self class] fromData:data error:&error];
        if (error) {
            NSLog(@"ARTPushActivationState Unarchive failed: %@", error);
        }
        return result;
    }
    else {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
}

@end

#pragma mark - Persistent State

@implementation ARTPushActivationPersistentState
@end

#pragma mark - Activation States

@implementation ARTPushActivationStateNotActivated

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledDeactivate class]]) {
        [self.machine callDeactivatedCallback:nil];
        return self;
    }
    else if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]]) {
        #if TARGET_OS_IOS
        ARTLocalDevice *local = self.machine.rest.device_nosync;

        if (local.identityTokenDetails) {
            // Already registered.
            return [ARTPushActivationStateWaitingForNewPushDeviceDetails newWithMachine:self.machine];
        }

        if ([local deviceToken]) {
            [self.machine sendEvent:[ARTPushActivationEventGotPushDeviceDetails new]];
        }
        #endif

        return [ARTPushActivationStateWaitingForPushDeviceDetails newWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForDeviceRegistration

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]]) {
        return self;
    }
    else if ([event isKindOfClass:[ARTPushActivationEventGotDeviceRegistration class]]) {
        #if TARGET_OS_IOS
        ARTPushActivationEventGotDeviceRegistration *gotDeviceRegistrationEvent = (ARTPushActivationEventGotDeviceRegistration *)event;
        ARTLocalDevice *local = self.machine.rest.device_nosync;
        [local setAndPersistIdentityTokenDetails:gotDeviceRegistrationEvent.identityTokenDetails];
        #endif
        [self.machine callActivatedCallback:nil];
        return [ARTPushActivationStateWaitingForNewPushDeviceDetails newWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventGettingDeviceRegistrationFailed class]]) {
        [self.machine callActivatedCallback:[(ARTPushActivationEventGettingDeviceRegistrationFailed *)event error]];
        return [ARTPushActivationStateNotActivated newWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForPushDeviceDetails

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]]) {
        return [ARTPushActivationStateWaitingForPushDeviceDetails newWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventCalledDeactivate class]]) {
        [self.machine callDeactivatedCallback:nil];
        return [ARTPushActivationStateNotActivated newWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventGotPushDeviceDetails class]]) {
        [self.machine deviceRegistration:nil];
        return [ARTPushActivationStateWaitingForDeviceRegistration newWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForNewPushDeviceDetails

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]]) {
        [self.machine callActivatedCallback:nil];
        return self;
    }
    else if ([event isKindOfClass:[ARTPushActivationEventCalledDeactivate class]]) {
        [self.machine deviceUnregistration:nil];
        return [ARTPushActivationStateWaitingForDeregistration newWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventGotPushDeviceDetails class]]) {
        [self.machine deviceUpdateRegistration:nil];
        return [ARTPushActivationStateWaitingForRegistrationUpdate newWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForRegistrationUpdate

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]]) {
        [self.machine callActivatedCallback:nil];
        return self;
    }
    else if ([event isKindOfClass:[ARTPushActivationEventRegistrationUpdated class]]) {
        #if TARGET_OS_IOS
        ARTPushActivationEventRegistrationUpdated *registrationUpdatedEvent = (ARTPushActivationEventRegistrationUpdated *)event;
        if (registrationUpdatedEvent.identityTokenDetails) {
            ARTLocalDevice *local = self.machine.rest.device_nosync;
            [local setAndPersistIdentityTokenDetails:registrationUpdatedEvent.identityTokenDetails];
        }
        #endif
        [self.machine callActivatedCallback:nil];
        return [ARTPushActivationStateWaitingForNewPushDeviceDetails newWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventUpdatingRegistrationFailed class]]) {
        [self.machine callUpdateFailedCallback:[(ARTPushActivationEventUpdatingRegistrationFailed *)event error]];
        return [ARTPushActivationStateAfterRegistrationUpdateFailed newWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateAfterRegistrationUpdateFailed

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledActivate class]] ||
        [event isKindOfClass:[ARTPushActivationEventGotPushDeviceDetails class]]) {
        [self.machine deviceUpdateRegistration:nil];
        return [ARTPushActivationStateWaitingForRegistrationUpdate newWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventCalledDeactivate class]]) {
        [self.machine deviceUnregistration:nil];
        return [ARTPushActivationStateWaitingForDeregistration newWithMachine:self.machine];
    }
    return nil;
}

@end

@implementation ARTPushActivationStateWaitingForDeregistration

- (ARTPushActivationState *)transition:(ARTPushActivationEvent *)event {
    [self logEventTransition:event file:__FILE__ line:__LINE__];
    if ([event isKindOfClass:[ARTPushActivationEventCalledDeactivate class]]) {
        return [ARTPushActivationStateWaitingForDeregistration newWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventDeregistered class]]) {
        #if TARGET_OS_IOS
        ARTLocalDevice *local = self.machine.rest.device_nosync;
        [local setAndPersistIdentityTokenDetails:nil];
        #endif
        [self.machine callDeactivatedCallback:nil];
        return [ARTPushActivationStateNotActivated newWithMachine:self.machine];
    }
    else if ([event isKindOfClass:[ARTPushActivationEventDeregistrationFailed class]]) {
        [self.machine callDeactivatedCallback:[(ARTPushActivationEventDeregistrationFailed *)event error]];
        return [ARTPushActivationStateWaitingForDeregistration newWithMachine:self.machine];
    }
    return nil;
}

@end
