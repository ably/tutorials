//
//  ARTPushChannelSubscription.m
//  Ably
//
//  Created by Ricardo Pereira on 15/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushChannelSubscription.h"

@implementation ARTPushChannelSubscription

- (instancetype)initWithDeviceId:(NSString *)deviceId channel:(NSString *)channelName {
    if (self = [super init]) {
        _deviceId = deviceId;
        _channel = channelName;
    }
    return self;
}

- (instancetype)initWithClientId:(NSString *)clientId channel:(NSString *)channelName {
    if (self = [super init]) {
        _clientId = clientId;
        _channel = channelName;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTPushChannelSubscription *subscription = [[[self class] allocWithZone:zone] init];

    subscription->_deviceId = self.deviceId;
    subscription->_clientId = self.clientId;
    subscription->_channel = self.channel;

    return subscription;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t deviceId: %@; clientId: %@; \n\t channel: %@;", [super description], self.deviceId, self.clientId, self.channel];
}

- (BOOL)isEqualToChannelSubscription:(ARTPushChannelSubscription *)subscription {
    if (!subscription) {
        return NO;
    }

    BOOL haveEqualDeviceId = (!self.clientId && !subscription.clientId) || [self.clientId isEqualToString:subscription.clientId];
    BOOL haveEqualCliendId = (!self.clientId && !subscription.clientId) || [self.clientId isEqualToString:subscription.clientId];
    BOOL haveEqualChannel = (!self.channel && !subscription.channel) || [self.channel isEqualToString:subscription.channel];

    return haveEqualDeviceId && haveEqualCliendId && haveEqualChannel;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[ARTPushChannelSubscription class]]) {
        return NO;
    }

    return [self isEqualToChannelSubscription:(ARTPushChannelSubscription *)object];
}

- (NSUInteger)hash {
    return [self.deviceId hash] ^ [self.clientId hash] ^ [self.channel hash];
}

@end
