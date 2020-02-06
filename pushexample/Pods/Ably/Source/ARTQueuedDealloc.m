//
//  ARTExposed.m
//  Ably
//
//  Created by Toni Cárdenas on 05/08/2019.
//  Copyright © 2019 Ably. All rights reserved.
//

#import "ARTQueuedDealloc.h"

@implementation ARTQueuedDealloc {
    id _ref;
    dispatch_queue_t _queue;
}

- (instancetype)init:(id)ref queue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _ref = ref;
        _queue = queue;
    }
    return self;
}

- (void)dealloc {
    __block id ref = _ref;
    dispatch_async(_queue, ^{
        ref = nil;
    });
}

@end
