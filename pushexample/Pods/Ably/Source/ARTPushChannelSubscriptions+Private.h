//
//  ARTPushChannelSubscriptions+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 07/08/2019.
//  Copyright © 2019 Ably. All rights reserved.
//

#ifndef ARTPushChannelSubscriptions_Private_h
#define ARTPushChannelSubscriptions_Private_h

#import <Ably/ARTPushChannelSubscriptions.h>
#import "ARTQueuedDealloc.h"

@class ARTRestInternal;

@interface ARTPushChannelSubscriptionsInternal : NSObject <ARTPushChannelSubscriptionsProtocol>

- (instancetype)initWithRest:(ARTRestInternal *)rest;

@end

@interface ARTPushChannelSubscriptions ()

@property (nonatomic, readonly) ARTPushChannelSubscriptionsInternal *internal;

- (instancetype)initWithInternal:(ARTPushChannelSubscriptionsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

#endif /* ARTPushChannelSubscriptions_Private_h */
