//
//  ARTPushChannel.h
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTPush.h>
#import <Ably/ARTHttp.h>
#import <Ably/ARTChannel.h>

@class ARTPushChannelSubscription;
@class ARTPaginatedResult;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushChannel : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)init:(ARTRest *)rest withChannel:(ARTChannel *)channel;

- (void)subscribeDevice;
- (void)subscribeDevice:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback;
- (void)subscribeClient;
- (void)subscribeClient:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback;

- (void)unsubscribeDevice;
- (void)unsubscribeDevice:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback;
- (void)unsubscribeClient;
- (void)unsubscribeClient:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback;

- (BOOL)listSubscriptions:(NSDictionary<NSString *, NSString *> *)params callback:(void(^)(ARTPaginatedResult<ARTPushChannelSubscription *> *_Nullable, ARTErrorInfo *_Nullable))callback error:(NSError *_Nullable *_Nullable)errorPtr;

@end

NS_ASSUME_NONNULL_END
