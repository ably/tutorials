//
//  ARTRestChannels.m
//  ably
//
//  Created by Toni Cárdenas on 3/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTRestChannels.h"
#import "ARTChannels+Private.h"
#import "ARTRestChannel+Private.h"
#import "ARTRest+Private.h"

@interface ARTRestChannels ()

@property (weak, nonatomic) ARTRest *rest;

@end

@interface ARTRestChannels () <ARTChannelsDelegate>
@end

@implementation ARTRestChannels {
    ARTChannels *_channels;
}

- (instancetype)initWithRest:(ARTRest *)rest {
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
    return [[ARTRestChannel alloc] initWithName:name withOptions:options andRest:_rest];
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id  _Nonnull *)buffer count:(NSUInteger)len {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return [_channels countByEnumeratingWithState:state objects:buffer count:len];
} ART_TRY_OR_REPORT_CRASH_END
}

- (ARTRestChannel *)get:(NSString *)name {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return [_channels get:name];
} ART_TRY_OR_REPORT_CRASH_END
}

- (ARTRestChannel *)get:(NSString *)name options:(ARTChannelOptions *)options {
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

- (ARTRestChannel *)_getChannel:(NSString *)name options:(ARTChannelOptions *)options addPrefix:(BOOL)addPrefix {
    return [_channels _getChannel:name options:options addPrefix:addPrefix];
}

@end
