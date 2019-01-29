//
//  NSDictionary+ARTDictionaryUtil.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (ARTDictionaryUtil)

- (NSString *)artString:(id)key;
- (NSNumber *)artNumber:(id)key;
- (NSDate *)artDate:(id)key;
- (NSArray *)artArray:(id)key;
- (NSDictionary *)artDictionary:(id)key;
- (NSInteger)artInteger:(id)key;

- (id)artTyped:(Class)cls key:(id)key;

@end
