//
//  ARTQueuedMessage.m
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTQueuedMessage.h"

#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"

@implementation ARTQueuedMessage

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg sentCallback:(void (^)(ARTErrorInfo *))sentCallback ackCallback:(void (^)(ARTStatus *))ackCallback {
    self = [super init];
    if (self) {
        _msg = msg;
        _sentCallbacks = [NSMutableArray array];
        if (sentCallback) {
            [_sentCallbacks addObject:sentCallback];
        }
        _ackCallbacks = [NSMutableArray array];
        if (ackCallback) {
            [_ackCallbacks addObject:ackCallback];
        }
    }
    return self;
}

- (NSString *)description {
    return [self.msg description];
}

- (BOOL)mergeFrom:(ARTProtocolMessage *)msg sentCallback:(void (^)(ARTErrorInfo *))sentCallback ackCallback:(void (^)(ARTStatus *))ackCallback {
    if ([self.msg mergeFrom:msg]) {
        if (sentCallback) {
            [self.sentCallbacks addObject:sentCallback];
        }
        if (ackCallback) {
            [self.ackCallbacks addObject:ackCallback];
        }
        return YES;
    }
    return NO;
}

- (void (^)(ARTErrorInfo *))sentCallback {
    return ^(ARTErrorInfo *error) {
        for (void (^cb)(ARTErrorInfo *) in self.sentCallbacks) {
            cb(error);
        }
    };
}

- (void (^)(ARTStatus *))ackCallback {
    return ^(ARTStatus *status) {
        for (void (^cb)(ARTStatus *) in self.ackCallbacks) {
            cb(status);
        }
    };
}

@end
