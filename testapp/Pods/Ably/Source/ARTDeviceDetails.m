//
//  ARTDeviceDetails.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTDeviceDetails.h"
#import "ARTDevicePushDetails.h"

@implementation ARTDeviceDetails

- (instancetype)init {
    if (self = [super init]) {
        _push = [[ARTDevicePushDetails alloc] init];
        _metadata = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithId:(ARTDeviceId *)deviceId {
    if (self = [self init]) {
        _id = deviceId;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTDeviceDetails *device = [[[self class] allocWithZone:zone] init];

    device.id = self.id;
    device.clientId = self.clientId;
    device.platform = self.platform;
    device.formFactor = self.formFactor;
    device.metadata = [self.metadata copy];
    device.push = [self.push copy];

    return device;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t id: %@; \n\t clientId: %@; \n\t platform: %@; \n\t formFactor: %@;", [super description], self.id, self.clientId, self.formFactor, self.platform];
}

- (BOOL)isEqualToDeviceDetail:(ARTDeviceDetails *)device {
    if (!device) {
        return NO;
    }

    BOOL haveEqualDeviceId = (!self.id && !device.id) || [self.id isEqualToString:device.id];
    BOOL haveEqualCliendId = (!self.clientId && !device.clientId) || [self.clientId isEqualToString:device.clientId];
    BOOL haveEqualPlatform = (!self.platform && !device.platform) || [self.platform isEqualToString:device.platform];
    BOOL haveEqualFormFactor = (!self.formFactor && !device.formFactor) || [self.formFactor isEqualToString:device.formFactor];

    return haveEqualDeviceId && haveEqualCliendId && haveEqualPlatform && haveEqualFormFactor;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[ARTDeviceDetails class]]) {
        return NO;
    }

    return [self isEqualToDeviceDetail:(ARTDeviceDetails *)object];
}

- (NSUInteger)hash {
    return [self.id hash] ^ [self.clientId hash] ^ [self.formFactor hash] ^ [self.platform hash];
}

@end
