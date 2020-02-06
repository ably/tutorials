
//
//  ARTRealtimeChannels+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 07/03/2016.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Ably/ARTRealtimeChannels.h>
#import <Ably/ARTRealtime+Private.h>
#import "ARTQueuedDealloc.h"

@class ARTRealtimeChannelInternal;

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeChannelsInternal : NSObject<ARTRealtimeChannelsProtocol>

- (ARTRealtimeChannelInternal *)get:(NSString *)name;
- (ARTRealtimeChannelInternal *)get:(NSString *)name options:(ARTChannelOptions *)options;
- (id<NSFastEnumeration>)copyIntoIteratorWithMapper:(ARTRealtimeChannel *(^)(ARTRealtimeChannelInternal *))mapper;

- (instancetype)initWithRealtime:(ARTRealtimeInternal *)realtime;

@property (readonly, getter=getNosyncIterable) id<NSFastEnumeration> nosyncIterable;
@property (nonatomic, readonly, getter=getCollection) NSMutableDictionary<NSString *, ARTRealtimeChannelInternal *> *collection;
- (ARTRealtimeChannelInternal *)_getChannel:(NSString *)name options:(ARTChannelOptions * _Nullable)options addPrefix:(BOOL)addPrefix;

@property (nonatomic, strong) dispatch_queue_t queue;

@end

@interface ARTRealtimeChannels ()

@property (nonatomic, readonly) ARTRealtimeChannelsInternal *internal;

- (instancetype)initWithInternal:(ARTRealtimeChannelsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
