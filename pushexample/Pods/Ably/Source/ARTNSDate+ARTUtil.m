//
//  NSDate+ARTUtil.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTNSDate+ARTUtil.h"

@implementation NSDate (ARTUtil)

+ (instancetype)artDateFromIntegerMs:(long long)ms {
    NSTimeInterval intervalSince1970 = ms / 1000.0;
    return [NSDate dateWithTimeIntervalSince1970:intervalSince1970];
}

+ (instancetype)artDateFromNumberMs:(NSNumber *)number {
    return [self artDateFromIntegerMs:[number longLongValue]];
}

- (NSNumber *)artToNumberMs {
    return [NSNumber numberWithInteger:[self artToIntegerMs]];
}

- (NSInteger)artToIntegerMs {
    return (NSInteger)round([self timeIntervalSince1970] * 1000.0);
}

- (NSString *)toSentryTimestamp {
    return [[[self class] customDateFormatter] stringFromDate:self];
}

+ (NSDateFormatter *)customDateFormatter {
    static dispatch_once_t onceToken;
    static NSDateFormatter *customDateFormatter;
    dispatch_once(&onceToken, ^{
        customDateFormatter = [[NSDateFormatter alloc] init];
        customDateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'.'SS";
        customDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    });
    return customDateFormatter;
}

@end
