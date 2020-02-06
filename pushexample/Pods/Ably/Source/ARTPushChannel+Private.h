//
//  ARTPushChannel+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 07/08/2019.
//  Copyright © 2019 Ably. All rights reserved.
//

#ifndef ARTPushChannel_Private_h
#define ARTPushChannel_Private_h

#import <Ably/ARTPushChannel.h>
#import "ARTQueuedDealloc.h"

@class ARTRestInternal;

@interface ARTPushChannelInternal : NSObject <ARTPushChannelProtocol>

- (instancetype)init:(ARTRestInternal *)rest withChannel:(ARTChannel *)channel;

@end

@interface ARTPushChannel ()

@property (nonatomic, readonly) ARTPushChannelInternal *internal;

- (instancetype)initWithInternal:(ARTPushChannelInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

#endif /* ARTPushChannel_Private_h */
