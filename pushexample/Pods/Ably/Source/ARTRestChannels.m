//
//  ARTRestChannels.m
//  ably
//
//  Created by Toni Cárdenas on 3/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTRestChannels+Private.h"
#import "ARTChannels+Private.h"
#import "ARTRestChannel+Private.h"
#import "ARTRest+Private.h"

@implementation ARTRestChannels {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTRestChannelsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (BOOL)exists:(NSString *)name {
    return [_internal exists:(NSString *)name];
}

- (ARTRestChannel *)get:(NSString *)name {
    return [[ARTRestChannel alloc] initWithInternal:[_internal get:(NSString *)name] queuedDealloc:_dealloc];
}

- (ARTRestChannel *)get:(NSString *)name options:(ARTChannelOptions *)options {
    return [[ARTRestChannel alloc] initWithInternal:[_internal get:(NSString *)name options:(ARTChannelOptions *)options] queuedDealloc:_dealloc];
}

- (void)release:(NSString *)name {
    [_internal release:(NSString *)name];
}

- (id<NSFastEnumeration>)iterate {
    return [_internal copyIntoIteratorWithMapper:^ARTRestChannel *(ARTRestChannelInternal *internalChannel) {
        return [[ARTRestChannel alloc] initWithInternal:internalChannel queuedDealloc:self->_dealloc];
    }];
}

@end

@interface ARTRestChannelsInternal ()

@property (weak, nonatomic) ARTRestInternal *rest; // weak because rest owns self

@end

@interface ARTRestChannelsInternal () <ARTChannelsDelegate>
@end

@implementation ARTRestChannelsInternal {
    ARTChannels *_channels;
}

- (instancetype)initWithRest:(ARTRestInternal *)rest {
ART_TRY_OR_REPORT_CRASH_START(rest) {
    if (self = [super init]) {
        _rest = rest;
        _channels = [[ARTChannels alloc] initWithDelegate:self dispatchQueue:_rest.queue];
    }
    return self;
} ART_TRY_OR_REPORT_CRASH_END
}

- (id)makeChannel:(NSString *)name options:(ARTChannelOptions *)options {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return [[ARTRestChannelInternal alloc] initWithName:name withOptions:options andRest:_rest];
} ART_TRY_OR_REPORT_CRASH_END
}

- (id<NSFastEnumeration>)copyIntoIteratorWithMapper:(ARTRestChannel *(^)(ARTRestChannelInternal *))mapper {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return [_channels copyIntoIteratorWithMapper:mapper];
} ART_TRY_OR_REPORT_CRASH_END
}

- (ARTRestChannelInternal *)get:(NSString *)name {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return [_channels get:name];
} ART_TRY_OR_REPORT_CRASH_END
}

- (ARTRestChannelInternal *)get:(NSString *)name options:(ARTChannelOptions *)options {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return [_channels get:name options:options];
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)exists:(NSString *)name {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return [_channels exists:name];
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)release:(NSString *)name {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    [_channels release:name];
} ART_TRY_OR_REPORT_CRASH_END
}

- (ARTRestChannelInternal *)_getChannel:(NSString *)name options:(ARTChannelOptions *)options addPrefix:(BOOL)addPrefix {
    return [_channels _getChannel:name options:options addPrefix:addPrefix];
}

@end
