//
//  ARTChannel.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTDataEncoder.h>
#import <Ably/ARTLog.h>

@class ARTRest;
@class ARTChannelOptions;
@class ARTMessage;
@class ARTBaseMessage;
@class ARTPaginatedResult<ItemType>;
@class ARTDataQuery;
@class ARTLocalDevice;

NS_ASSUME_NONNULL_BEGIN

@interface ARTChannel : NSObject

@property (nonatomic, strong, readonly) NSString *name;

- (instancetype)initWithName:(NSString *)name andOptions:(ARTChannelOptions *)options rest:(ARTRest *)rest;

- (void)publish:(nullable NSString *)name data:(nullable id)data;
- (void)publish:(nullable NSString *)name data:(nullable id)data callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback;

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId;
- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback;

- (void)publish:(nullable NSString *)name data:(nullable id)data extras:(nullable id<ARTJsonCompatible>)extras;
- (void)publish:(nullable NSString *)name data:(nullable id)data extras:(nullable id<ARTJsonCompatible>)extras callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback;

- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId extras:(nullable id<ARTJsonCompatible>)extras;
- (void)publish:(nullable NSString *)name data:(nullable id)data clientId:(NSString *)clientId extras:(nullable id<ARTJsonCompatible>)extras callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback;

- (void)publish:(NSArray<ARTMessage *> *)messages;
- (void)publish:(NSArray<ARTMessage *> *)messages callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback;

- (void)history:(void(^)(ARTPaginatedResult<ARTMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback;

- (ARTLocalDevice *)device;

- (BOOL)exceedMaxSize:(NSArray<ARTBaseMessage *> *)messages;

@end

NS_ASSUME_NONNULL_END
