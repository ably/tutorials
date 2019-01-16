//
//  ARTFallback.m
//  ably
//
//  Created by vic on 19/06/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTFallback+Private.h"

#import "ARTDefault.h"
#import "ARTStatus.h"
#import "ARTHttp.h"
#import "ARTClientOptions.h"

int (^ARTFallback_getRandomHostIndex)(int count) = ^int(int count) {
    return arc4random() % count;
};

@interface ARTFallback ()

@end

@implementation ARTFallback

- (instancetype)initWithFallbackHosts:(nullable NSArray<NSString *> *)fallbackHosts {
    self = [super init];
    if (self) {
        if (fallbackHosts != nil && fallbackHosts.count == 0) {
            return nil;
        }
        self.hosts = [NSMutableArray array];
        NSMutableArray * hostArray = [[NSMutableArray alloc] initWithArray: fallbackHosts ? fallbackHosts : [ARTDefault fallbackHosts]];
        size_t count = [hostArray count];
        for (int i=0; i <count; i++) {
            int randomIndex = ARTFallback_getRandomHostIndex((int)[hostArray count]);
            [self.hosts addObject:[hostArray objectAtIndex:randomIndex]];
            [hostArray removeObjectAtIndex:randomIndex];
        }
    }
    return self;
}

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    if (options.fallbackHostsUseDefault) {
        return [self initWithFallbackHosts:nil]; //default
    }
    return [self initWithFallbackHosts:options.fallbackHosts];
}

- (instancetype)init {
    return [self initWithFallbackHosts:nil];
}

- (NSString *)popFallbackHost {
    if ([self.hosts count] ==0) {
        return nil;
    }
    NSString *host = [self.hosts lastObject];
    [self.hosts removeLastObject];
    return host;
}

+ (BOOL)restShouldFallback:(NSURL *)url withOptions:(ARTClientOptions *)options {
    // Default REST
    if ([url.host isEqualToString:[ARTDefault restHost]]) {
        return YES;
    }
    // Custom host / environment
    else if (options.fallbackHostsUseDefault) {
        return YES;
    }
    return NO;
}

+ (BOOL)realtimeShouldFallback:(NSURL *)url withOptions:(ARTClientOptions *)options {
    // Default Realtime
    if ([url.host isEqualToString:[ARTDefault realtimeHost]]) {
        return YES;
    }
    // Custom host / environment
    else if (options.fallbackHostsUseDefault) {
        return YES;
    }
    return NO;
}

@end
