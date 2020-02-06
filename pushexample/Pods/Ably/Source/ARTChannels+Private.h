//
//  ARTChannels+Private.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Ably/ARTChannels.h>

@class ARTRestChannel;
@class ARTChannelOptions;

NS_ASSUME_NONNULL_BEGIN

extern NSString* (^_Nullable ARTChannels_getChannelNamePrefix)(void);

@protocol ARTChannelsDelegate <NSObject>

- (id)makeChannel:(NSString *)channel options:(nullable ARTChannelOptions *)options;

@end

@interface ARTChannels<ChannelType> ()

@property (nonatomic, readonly) NSMutableDictionary<NSString *, ChannelType> *channels;
@property (readonly, getter=getNosyncIterable) id<NSFastEnumeration> nosyncIterable;

+ (NSString *)addPrefix:(NSString *)name;

- (BOOL)_exists:(NSString *)name;
- (ChannelType)_get:(NSString *)name;
- (ChannelType)_getChannel:(NSString *)name options:(ARTChannelOptions * _Nullable)options addPrefix:(BOOL)addPrefix;
- (void)_release:(NSString *)name;

- (instancetype)initWithDelegate:(id<ARTChannelsDelegate>)delegate dispatchQueue:(dispatch_queue_t)queue;

@end

NS_ASSUME_NONNULL_END
