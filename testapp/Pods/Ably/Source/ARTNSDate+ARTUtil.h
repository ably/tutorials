//
//  NSDate+ARTUtil.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (ARTUtil)

+ (instancetype)artDateFromNumberMs:(NSNumber *)number;
+ (instancetype)artDateFromIntegerMs:(long long)ms;

- (NSNumber *)artToNumberMs;
- (NSInteger)artToIntegerMs;

- (NSString *)toSentryTimestamp;

@end
