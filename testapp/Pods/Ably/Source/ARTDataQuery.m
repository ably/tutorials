//
//  ARTDataQuery.m
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTDataQuery+Private.h"
#import "ARTRealtimeChannel+Private.h"

@implementation ARTDataQuery

- (instancetype)init {
    if (self = [super init]) {
        _limit = 100;
        _direction = ARTQueryDirectionBackwards;
    }

    return self;
}

static NSString *queryDirectionToString(ARTQueryDirection direction) {
    switch (direction) {
        case ARTQueryDirectionForwards:
            return @"forwards";
        case ARTQueryDirectionBackwards:
        default:
            return @"backwards";
    }
}

- (NSMutableArray *)asQueryItems:(NSError *_Nullable*)error {
    NSMutableArray *items = [NSMutableArray array];

    if (self.start) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"start" value:[NSString stringWithFormat:@"%llu", dateToMilliseconds(self.start)]]];
    }
    if (self.end) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"end" value:[NSString stringWithFormat:@"%llu", dateToMilliseconds(self.end)]]];
    }

    [items addObject:[NSURLQueryItem queryItemWithName:@"limit" value:[NSString stringWithFormat:@"%hu", self.limit]]];
    [items addObject:[NSURLQueryItem queryItemWithName:@"direction" value:queryDirectionToString(self.direction)]];

    return items;
}

@end

@implementation ARTRealtimeHistoryQuery

- (NSMutableArray *)asQueryItems:(NSError **)errorPtr {
    NSMutableArray *items = [super asQueryItems:errorPtr];
    if (*errorPtr) {
        return nil;
    }
    if (self.untilAttach) {
        NSAssert(self.realtimeChannel, @"ARTRealtimeHistoryQuery used from outside ARTRealtimeChannel.history");
        if (self.realtimeChannel.state_nosync != ARTRealtimeChannelAttached) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain code:ARTRealtimeHistoryErrorNotAttached userInfo:@{NSLocalizedDescriptionKey:@"ARTRealtimeHistoryQuery: untilAttach used in channel that isn't attached"}];
            return nil;
        }
        [items addObject:[NSURLQueryItem queryItemWithName:@"fromSerial" value:self.realtimeChannel.attachSerial]];
    }
    return items;
}

@end
