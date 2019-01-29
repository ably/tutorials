//
//  ARTPushActivationEvent.m
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushActivationEvent.h"
#import "ARTTypes.h"
#import "ARTDeviceIdentityTokenDetails.h"

NSString *const ARTCoderErrorKey = @"error";
NSString *const ARTCoderIdentityTokenDetailsKey = @"identityTokenDetails";

@implementation ARTPushActivationEvent

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
            NSLog(@"ARTPushActivationEvent Archive failed: %@", error);
        }
        return data;
    }
    else {
        return [NSKeyedArchiver archivedDataWithRootObject:self];
    }
}

+ (ARTPushActivationEvent *)unarchive:(NSData *)data {
    if (!data) {
        return nil;
    }
    if (@available(macOS 10.13, iOS 11, tvOS 11, *)) {
        NSError *error;
        ARTPushActivationEvent *result = [NSKeyedUnarchiver unarchivedObjectOfClass:[self class] fromData:data error:&error];
        if (error) {
            NSLog(@"ARTPushActivationEvent Unarchive failed: %@", error);
        }
        return result;
    }
    else {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
}

@end

#pragma mark - Event with Error info

@implementation ARTPushActivationErrorEvent

- (instancetype)initWithError:(ARTErrorInfo *)error {
    if (self = [super init]) {
        _error = error;
    }
    return self;
}

+ (instancetype)newWithError:(ARTErrorInfo *)error {
    return [[self alloc] initWithError:error];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _error = [aDecoder decodeObjectOfClass:[ARTErrorInfo class] forKey:ARTCoderErrorKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.error forKey:ARTCoderErrorKey];
}

@end

#pragma mark - Event with Device Identity Token details

@implementation ARTPushActivationDeviceIdentityEvent

- (instancetype)initWithIdentityTokenDetails:(ARTDeviceIdentityTokenDetails *)identityTokenDetails {
    if (self = [super init]) {
        _identityTokenDetails = identityTokenDetails;
    }
    return self;
}

+ (instancetype)newWithIdentityTokenDetails:(ARTDeviceIdentityTokenDetails *)identityTokenDetails {
    return [[self alloc] initWithIdentityTokenDetails:identityTokenDetails];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _identityTokenDetails = [aDecoder decodeObjectOfClass:[ARTDeviceIdentityTokenDetails class] forKey:ARTCoderIdentityTokenDetailsKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.identityTokenDetails forKey:ARTCoderIdentityTokenDetailsKey];
}

@end

#pragma mark - Activation Events

@implementation ARTPushActivationEventCalledActivate
@end

@implementation ARTPushActivationEventCalledDeactivate
@end

@implementation ARTPushActivationEventGotPushDeviceDetails
@end

@implementation ARTPushActivationEventGotDeviceRegistration
@end

@implementation ARTPushActivationEventGettingDeviceRegistrationFailed
@end

@implementation ARTPushActivationEventRegistrationUpdated
@end

@implementation ARTPushActivationEventUpdatingRegistrationFailed
@end

@implementation ARTPushActivationEventDeregistered
@end

@implementation ARTPushActivationEventDeregistrationFailed
@end
