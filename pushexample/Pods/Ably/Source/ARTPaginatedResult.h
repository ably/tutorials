//
//  ARTPaginatedResult.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTStatus.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTPaginatedResult<ItemType> : NSObject

@property (nonatomic, strong, readonly) NSArray<ItemType> *items;
@property (nonatomic, readonly) BOOL hasNext;
@property (nonatomic, readonly) BOOL isLast;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

- (void)first:(void (^)(ARTPaginatedResult<ItemType> *_Nullable result, ARTErrorInfo *_Nullable error))callback;
- (void)next:(void (^)(ARTPaginatedResult<ItemType> *_Nullable result, ARTErrorInfo *_Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
