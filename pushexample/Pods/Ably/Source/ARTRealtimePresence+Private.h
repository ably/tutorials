//
//  ARTRealtimePresence+Private.h
//  ably
//
//  Created by Toni Cárdenas on 7/4/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTRealtimePresence.h>
#import <Ably/ARTRealtimeChannel+Private.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimePresenceInternal : NSObject <ARTRealtimePresenceProtocol>

- (instancetype)initWithChannel:(ARTRealtimeChannelInternal *)channel;
- (void)_unsubscribe;
- (BOOL)syncComplete_nosync;

@property (nonatomic, strong) dispatch_queue_t queue;

@end

@interface ARTRealtimePresence ()

@property (nonatomic, readonly) ARTRealtimePresenceInternal *internal;

- (instancetype)initWithInternal:(ARTRealtimePresenceInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
