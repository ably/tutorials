//
//  ARTPushAdmin.h
//  Ably
//
//  Created by Ricardo Pereira on 20/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>
#import <Ably/ARTPushDeviceRegistrations.h>
#import <Ably/ARTPushChannelSubscriptions.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTPushAdminProtocol

- (instancetype)init NS_UNAVAILABLE;

/// Publish a push notification.
- (void)publish:(ARTPushRecipient *)recipient data:(ARTJsonObject *)data callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback;

@end

@interface ARTPushAdmin : NSObject <ARTPushAdminProtocol>

@property (nonatomic, readonly) ARTPushDeviceRegistrations *deviceRegistrations;
@property (nonatomic, readonly) ARTPushChannelSubscriptions *channelSubscriptions;

@end

NS_ASSUME_NONNULL_END
