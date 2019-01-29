//
//  ARTChannels.m
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTChannels+Private.h"

#import "ARTRest+Private.h"
#import "ARTChannel+Private.h"
#import "ARTChannelOptions.h"
#import "ARTRestChannel.h"

NSString* (^_Nullable ARTChannels_getChannelNamePrefix)(void);

@interface ARTChannels() {
    __weak id<ARTChannelsDelegate> _delegate;
    dispatch_queue_t _queue;
}

@end

@implementation ARTChannels

- (instancetype)initWithDelegate:(id)delegate dispatchQueue:(dispatch_queue_t)queue {
    if (self = [super init]) {
        _queue = queue;
        _channels = [[NSMutableDictionary alloc] init];
        _delegate = delegate;
    }
    return self;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    __block NSUInteger ret;
dispatch_sync(_queue, ^{
    ret = [[self getNosyncIterable] countByEnumeratingWithState:state objects:buffer count:len];
});
    return ret;
}

- (id<NSFastEnumeration>)getNosyncIterable {
    return [[ARTChannelsNosyncIterable alloc] init:_channels];
}

- (BOOL)exists:(NSString *)name {
    __block BOOL ret;
dispatch_sync(_queue, ^{
    ret = [self _exists:name];
});
    return ret;
}

- (BOOL)_exists:(NSString *)name {
    return self->_channels[[ARTChannels addPrefix:name]] != nil;
}

- (id)get:(NSString *)name {
    return [self getChannel:[ARTChannels addPrefix:name] options:nil];
}

- (id)get:(NSString *)name options:(ARTChannelOptions *)options {
    return [self getChannel:[ARTChannels addPrefix:name] options:options];
}

- (void)release:(NSString *)name {
dispatch_sync(_queue, ^{
    [self _release:name];
});
}

- (void)_release:(NSString *)name {
    [self->_channels removeObjectForKey:[ARTChannels addPrefix:name]];
}

- (ARTRestChannel *)getChannel:(NSString *)name options:(ARTChannelOptions *)options {
    __block ARTRestChannel *channel;
dispatch_sync(_queue, ^{
    channel = [self _getChannel:name options:options addPrefix:true];
});
    return channel;
}

- (ARTRestChannel *)_getChannel:(NSString *)name options:(ARTChannelOptions *)options addPrefix:(BOOL)addPrefix {
    if (addPrefix) {
        name = [ARTChannels addPrefix:name];
    }
    ARTRestChannel *channel = [self _get:name];
    if (!channel) {
        channel = [_delegate makeChannel:name options:options];
        [self->_channels setObject:channel forKey:name];
    } else if (options) {
        [channel _setOptions:options];
    }
    return channel;
}

- (id)_get:(NSString *)name {
    return self->_channels[name];
}

+ (NSString *)addPrefix:(NSString *)name {
    if (ARTChannels_getChannelNamePrefix) {
        NSString *prefix = [NSString stringWithFormat:@"%@-", ARTChannels_getChannelNamePrefix()];
        if (![name hasPrefix:prefix]) {
            return [NSString stringWithFormat:@"%@-%@", ARTChannels_getChannelNamePrefix(), name];
        }
    }
    return name;
}

@end

@implementation ARTChannelsNosyncIterable {
    NSDictionary *_channels;
}

- (instancetype)init:(NSDictionary<NSString *, id> *)channels {
    if (self = [super init]) {
        _channels = channels;
    }
    return self;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len {
    NSUInteger count = [self->_channels countByEnumeratingWithState:state objects:buffer count:len];
    for (NSUInteger i = 0; i < count; i++) {
        buffer[i] = self->_channels[buffer[i]];
    }
    return count;
}

@end
