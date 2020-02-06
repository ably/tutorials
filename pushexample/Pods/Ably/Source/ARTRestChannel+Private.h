
//
//  ARTRestChannel+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Ably/ARTRestChannel.h>
#import <Ably/ARTRestPresence+Private.h>
#import <Ably/ARTPushChannel+Private.h>
#import "ARTQueuedDealloc.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTRestInternal;

@interface ARTRestChannelInternal : ARTChannel <ARTRestChannelProtocol>

@property (readonly) ARTRestPresenceInternal *presence;
@property (readonly) ARTPushChannelInternal *push;

- (instancetype)initWithName:(NSString *)name withOptions:(ARTChannelOptions *)options andRest:(ARTRestInternal *)rest;

@property (nonatomic, weak) ARTRestInternal *rest; // weak because rest owns self
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@interface ARTRestChannelInternal (Private)

@property (readonly, getter=getBasePath) NSString *basePath;

@end

@interface ARTRestChannel ()

@property (nonatomic, readonly) ARTRestChannelInternal *internal;

- (instancetype)initWithInternal:(ARTRestChannelInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

NS_ASSUME_NONNULL_END

@end
