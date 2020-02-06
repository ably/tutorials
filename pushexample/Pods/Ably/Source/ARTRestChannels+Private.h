//
//  ARTRestChannels+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 21/07/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Ably/ARTRestChannels.h>
#import "ARTQueuedDealloc.h"
#import "ARTRestChannel+Private.h"

@class ARTRestChannel;
@class ARTRestInternal;

NS_ASSUME_NONNULL_BEGIN

@interface ARTRestChannelsInternal : NSObject<ARTRestChannelsProtocol>

- (ARTRestChannelInternal *)get:(NSString *)name;
- (ARTRestChannelInternal *)get:(NSString *)name options:(ARTChannelOptions *)options;
- (id<NSFastEnumeration>)copyIntoIteratorWithMapper:(ARTRestChannel *(^)(ARTRestChannelInternal *))mapper;

- (instancetype)initWithRest:(ARTRestInternal *)rest;
- (ARTRestChannelInternal *)_getChannel:(NSString *)name options:(ARTChannelOptions * _Nullable)options addPrefix:(BOOL)addPrefix;

@end

@interface ARTRestChannels ()

@property (nonatomic, readonly) ARTRestChannelsInternal *internal;

- (instancetype)initWithInternal:(ARTRestChannelsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
