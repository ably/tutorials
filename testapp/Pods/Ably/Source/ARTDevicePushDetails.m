//
//  ARTDevicePushDetails.m
//  Ably
//
//  Created by Ricardo Pereira on 08/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTDevicePushDetails.h"
#import "ARTPush.h"

@implementation ARTDevicePushDetails

- (instancetype)init {
    if (self = [super init]) {
        _recipient = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    ARTDevicePushDetails *push = [[[self class] allocWithZone:zone] init];

    push.recipient = [self.recipient copy];
    push.state = self.state;
    push.errorReason = [self.errorReason copy];

    return push;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t recipient: %@; \n\t state: %@; \n\t errorReason: %@;", [super description], self.recipient, self.state, self.errorReason];
}

@end
