//
//  ARTAuth+Private.h
//  ably
//
//  Created by Ricardo Pereira on 03/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Ably/ARTAuth.h>
#import <Ably/ARTEventEmitter.h>
#import "ARTQueuedDealloc.h"

@class ARTRestInternal;

typedef NS_ENUM(NSUInteger, ARTAuthorizationState) {
    ARTAuthorizationSucceeded, //ItemType: nil
    ARTAuthorizationFailed, //ItemType: NSError
    ARTAuthorizationCancelled, //ItemType: nil
};

NS_ASSUME_NONNULL_BEGIN

@interface ARTAuthInternal : NSObject <ARTAuthProtocol>

@property (nullable, readonly) NSString *clientId;
@property (nullable, nonatomic, readonly, strong) ARTTokenDetails *tokenDetails;

@end

/// Messages related to the ARTAuth
@protocol ARTAuthDelegate <NSObject>
- (void)auth:(ARTAuthInternal *)auth didAuthorize:(ARTTokenDetails *)tokenDetails completion:(void (^)(ARTAuthorizationState, ARTErrorInfo *_Nullable))completion;
@end

@interface ARTAuthInternal ()

@property (readonly, nonatomic) dispatch_queue_t queue;

- (NSString *)clientId_nosync;

@property (nonatomic, readonly, strong) ARTClientOptions *options;
@property (nonatomic, readonly, assign) ARTAuthMethod method;

@property (nonatomic, strong) ARTLog *logger;

@property (nullable, nonatomic, readonly, strong) NSNumber *timeOffset;

@property (nullable, weak) id<ARTAuthDelegate> delegate; // weak because delegates outlive their counterpart
@property (readonly) BOOL authorizing;
@property (readonly) BOOL authorizing_nosync;

- (nullable NSObject<ARTCancellable> *)_authorize:(nullable ARTTokenParams *)tokenParams options:(nullable ARTAuthOptions *)authOptions
         callback:(void (^)(ARTTokenDetails *_Nullable, NSError *_Nullable))callback;
- (void)cancelAuthorization:(nullable ARTErrorInfo *)error;

- (nullable NSObject<ARTCancellable> *)_requestToken:(ARTTokenParams *_Nullable)tokenParams withOptions:(ARTAuthOptions *_Nullable)authOptions callback:(void (^)(ARTTokenDetails *_Nullable, NSError *_Nullable))callback;

@end

@interface ARTAuthInternal (Private)

- (instancetype)init:(ARTRestInternal *)rest withOptions:(ARTClientOptions *)options;

- (ARTAuthOptions *)mergeOptions:(ARTAuthOptions *)customOptions;
- (ARTTokenParams *)mergeParams:(ARTTokenParams *)customParams;

- (NSURL *)buildURL:(ARTAuthOptions *)options withParams:(ARTTokenParams *)params;
- (NSMutableURLRequest *)buildRequest:(nullable ARTAuthOptions *)options withParams:(nullable ARTTokenParams *)params;

// Execute the received ARTTokenRequest
- (nullable NSObject<ARTCancellable> *)executeTokenRequest:(ARTTokenRequest *)tokenRequest callback:(void (^)(ARTTokenDetails *_Nullable tokenDetails, NSError *_Nullable error))callback;

// CONNECTED ProtocolMessage may contain a clientId
- (void)setProtocolClientId:(NSString *)clientId;

// Discard the cached local clock offset
- (void)discardTimeOffset;

// Configured options does have a means to renew the token automatically.
- (BOOL)canRenewTokenAutomatically:(ARTAuthOptions *)options;

/// Does the client have a means to renew the token automatically.
- (BOOL)tokenIsRenewable;

/// Does the client have a valid token (i.e. not expired).
- (BOOL)tokenRemainsValid;

// Private TokenDetails setter for testing only
- (void)setTokenDetails:(nullable ARTTokenDetails *)tokenDetails;

// Private TimeOffset setter for testing only
- (void)setTimeOffset:(NSTimeInterval)offset;
- (void)clearTimeOffset;

- (NSString *_Nullable)clientId;

- (NSString *_Nullable)appId;

@end

@interface ARTAuth ()

@property (nonatomic, readonly) ARTAuthInternal *internal;

- (instancetype)initWithInternal:(ARTAuthInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;
- (void)internalAsync:(void (^)(ARTAuthInternal *))use;

@end

NS_ASSUME_NONNULL_END
