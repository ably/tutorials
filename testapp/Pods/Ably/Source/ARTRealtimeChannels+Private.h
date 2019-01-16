
//
//  ARTRealtimeChannels+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 07/03/2016.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Ably/ARTRealtimeChannels.h>

@class ARTRealtimeChannel;

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeChannels ()

@property (readonly, getter=getNosyncIterable) id<NSFastEnumeration> nosyncIterable;
@property (nonatomic, readonly, getter=getCollection) NSMutableDictionary<NSString *, ARTRealtimeChannel *> *collection;
- (ARTRealtimeChannel *)_getChannel:(NSString *)name options:(ARTChannelOptions * _Nullable)options addPrefix:(BOOL)addPrefix;

@end

NS_ASSUME_NONNULL_END
