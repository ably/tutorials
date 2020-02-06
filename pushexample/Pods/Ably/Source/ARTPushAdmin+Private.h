//
//  ARTPushAdmin+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 07/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Ably/ARTPushAdmin.h>
#import <Ably/ARTPushDeviceRegistrations+Private.h>
#import <Ably/ARTPushChannelSubscriptions+Private.h>
#import "ARTQueuedDealloc.h"

@class ARTRestInternal;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushAdminInternal : NSObject <ARTPushAdminProtocol>

@property (nonatomic, readonly) ARTPushDeviceRegistrationsInternal *deviceRegistrations;
@property (nonatomic, readonly) ARTPushChannelSubscriptionsInternal *channelSubscriptions;

- (instancetype)initWithRest:(ARTRestInternal *)rest;

@end

@interface ARTPushAdmin ()

@property (nonatomic, readonly) ARTPushAdminInternal *internal;

- (instancetype)initWithInternal:(ARTPushAdminInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@end

NS_ASSUME_NONNULL_END
