//
//  NSArray+ARTFunctional.h
//  ably-ios
//
//  Created by Jason Choy on 11/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (ARTFunctional)

- (NSArray *)artMap:(id(^)(id))f;
- (NSArray *)artFilter:(BOOL(^)(id))f;

@end
