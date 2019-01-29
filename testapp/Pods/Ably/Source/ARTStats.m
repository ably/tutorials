//
//  ARTStats.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTStats.h"
#import "ARTDataQuery+Private.h"

@implementation ARTStatsQuery

- (instancetype)init {
    if (self = [super init]) {
        _unit = ARTStatsGranularityMinute;
    }

    return self;
}

static NSString *statsUnitToString(ARTStatsGranularity unit) {
    switch (unit) {
        case ARTStatsGranularityMonth:
            return @"month";
        case ARTStatsGranularityDay:
            return @"day";
        case ARTStatsGranularityHour:
            return @"hour";
        case ARTStatsGranularityMinute:
        default:
            return @"minute";
    }
}

- (NSMutableArray *)asQueryItems:(NSError **)error {
    NSMutableArray *items = [super asQueryItems:error];
    if (*error) {
        return nil;
    }
    [items addObject:[NSURLQueryItem queryItemWithName:@"unit" value:statsUnitToString(self.unit)]];
    return items;
}

@end

@implementation ARTStatsMessageCount

- (instancetype)initWithCount:(NSUInteger)count data:(NSUInteger)data {
    self = [super init];
    if (self) {
        _count = count;
        _data = data;
    }
    return self;
}

+ (instancetype)empty {
    return [[ARTStatsMessageCount alloc] initWithCount:0 data:0];
}

@end

@implementation ARTStatsMessageTypes

- (instancetype)initWithAll:(ARTStatsMessageCount *)all messages:(ARTStatsMessageCount *)messages presence:(ARTStatsMessageCount *)presence {
    self = [super init];
    if (self) {
        _all = all;
        _messages = messages;
        _presence = presence;
    }
    return self;
}

+ (instancetype)empty {
    return [[ARTStatsMessageTypes alloc] initWithAll:[ARTStatsMessageCount empty]  messages:[ARTStatsMessageCount empty] presence:[ARTStatsMessageCount empty]];
}

@end

@implementation ARTStatsMessageTraffic

- (instancetype)initWithAll:(ARTStatsMessageTypes *)all realtime:(ARTStatsMessageTypes *)realtime rest:(ARTStatsMessageTypes *)rest webhook:(ARTStatsMessageTypes *)webhook {
    self = [super init];
    if (self) {
        _all = all;
        _realtime = realtime;
        _rest = rest;
        _webhook = webhook;
    }
    return self;
}

+ (instancetype)empty {
    return [[ARTStatsMessageTraffic alloc] initWithAll:[ARTStatsMessageTypes empty] realtime:[ARTStatsMessageTypes empty] rest:[ARTStatsMessageTypes empty] webhook:[ARTStatsMessageTypes empty]];
}

@end

@implementation ARTStatsResourceCount

- (instancetype)initWithOpened:(NSUInteger)opened peak:(NSUInteger)peak mean:(NSUInteger)mean min:(NSUInteger)min refused:(NSUInteger)refused {
    self = [super init];
    if (self) {
        _opened = opened;
        _peak = peak;
        _mean = mean;
        _min = min;
        _refused = refused;
    }
    return self;
}

+ (instancetype)empty {
    return [[ARTStatsResourceCount alloc] initWithOpened:0 peak:0 mean:0 min:0 refused:0];
}

@end

@implementation ARTStatsConnectionTypes

- (instancetype)initWithAll:(ARTStatsResourceCount *)all plain:(ARTStatsResourceCount *)plain tls:(ARTStatsResourceCount *)tls {
    self = [super init];
    if (self) {
        _all = all;
        _plain = plain;
        _tls = tls;
    }
    return self;
}

+ (instancetype)empty {
    return [[ARTStatsConnectionTypes alloc] initWithAll:[ARTStatsResourceCount empty] plain:[ARTStatsResourceCount empty] tls:[ARTStatsResourceCount empty]];
}

@end

@implementation ARTStatsRequestCount

- (instancetype)initWithSucceeded:(NSUInteger)succeeded failed:(NSUInteger)failed refused:(NSUInteger)refused {
    self = [super init];
    if (self) {
        _succeeded = succeeded;
        _failed = failed;
        _refused = refused;
    }
    return self;
}

+ (instancetype)empty {
    return [[ARTStatsRequestCount alloc] initWithSucceeded:0 failed:0 refused:0];
}

@end

@implementation ARTStats

- (instancetype)initWithAll:(ARTStatsMessageTypes *)all inbound:(ARTStatsMessageTraffic *)inbound outbound:(ARTStatsMessageTraffic *)outbound persisted:(ARTStatsMessageTypes *)persisted connections:(ARTStatsConnectionTypes *)connections channels:(ARTStatsResourceCount *)channels apiRequests:(ARTStatsRequestCount *)apiRequests tokenRequests:(ARTStatsRequestCount *)tokenRequests intervalId:(NSString *)intervalId {
    self = [super init];
    if (self) {
        _all = all;
        _inbound = inbound;
        _outbound = outbound;
        _persisted = persisted;
        _connections = connections;
        _channels = channels;
        _apiRequests = apiRequests;
        _tokenRequests = tokenRequests;
        _intervalId = intervalId;
    }
    return self;
}

+ (NSArray *)intervalFormatString {
    static NSArray *formats;
    if (!formats) {
        formats = [NSArray arrayWithObjects:@"yyyy-MM-dd:HH:mm", @"yyyy-MM-dd:HH", @"yyyy-MM-dd", @"yyyy-MM", nil];
    }
    return formats;
}

+ (NSDate *)fromIntervalId:(NSString *)intervalId {
    for (NSString *format in [ARTStats intervalFormatString]) {
        if ([format length] == [intervalId length]) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = format;
            formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
            return [formatter dateFromString:intervalId];
        }
    }
    @throw [ARTException exceptionWithName:NSInvalidArgumentException reason:@"invalid intervalId" userInfo:nil];
}

+ (ARTStatsGranularity)granularityFromIntervalId:(NSString *)intervalId {
    NSArray *formats = [ARTStats intervalFormatString];
    for (int i = 0; i < [formats count]; i++) {
        if ([[formats objectAtIndex:i] length] == [intervalId length]) {
            return (ARTStatsGranularity)i;
        }
    }
    @throw [ARTException exceptionWithName:NSInvalidArgumentException reason:@"invalid intervalId" userInfo:nil];
}

+ (NSString *)toIntervalId:(NSDate *)time granularity:(ARTStatsGranularity)granularity {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = [[ARTStats intervalFormatString] objectAtIndex:granularity];
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    return [formatter stringFromDate:time];
}

- (ARTStatsGranularity)intervalGranularity {
    return [[self class] granularityFromIntervalId:self.intervalId];
}

- (NSDate *)intervalTime {
    return [[self class] fromIntervalId:self.intervalId];
}

@end
