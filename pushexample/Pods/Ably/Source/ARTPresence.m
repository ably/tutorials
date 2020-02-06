//
//  ARTPresence.m
//  ably
//
//  Created by Yavor Georgiev on 26.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTPresence.h"

@implementation ARTPresence

- (void)history:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> *, ARTErrorInfo *))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

@end
