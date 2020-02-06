//
//  ARTFallback+Private.h
//  Ably
//
//  Created by Ricardo Pereira on 13/10/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#include <Ably/ARTFallback.h>

NS_ASSUME_NONNULL_BEGIN

extern void (^ARTFallback_shuffleArray)(NSMutableArray *);

@interface ARTFallback ()

@property (readwrite, strong, nonatomic) NSMutableArray<NSString *> *hosts;

+ (BOOL)restShouldFallback:(NSURL *)host withOptions:(ARTClientOptions *)options;
+ (BOOL)realtimeShouldFallback:(NSURL *)host withOptions:(ARTClientOptions *)options;

@end

NS_ASSUME_NONNULL_END
