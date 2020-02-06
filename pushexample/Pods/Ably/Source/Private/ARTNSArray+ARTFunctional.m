//
//  NSArray+ARTFunctional.m
//  ably-ios
//
//  Created by Jason Choy on 11/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTNSArray+ARTFunctional.h"

@implementation NSArray (ARTFunctional)

- (NSArray *)artMap:(id (^)(id))f {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
    for (id e in self) {
        [array addObject:(f(e))];
    }
    return array;
}

- (NSArray *)artFilter:(BOOL (^)(id))f {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
    for (id e in self) {
    	if (f(e)) {
        	[array addObject:e];
        }
    }
    return array;
}

@end
