//
//  ARTRest.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTLog.h>
#import <Ably/ARTRestChannels.h>
#import <Ably/ARTLocalDevice.h>

@protocol ARTHTTPExecutor;

@class ARTRestChannels;
@class ARTClientOptions;
@class ARTAuth;
@class ARTPush;
@class ARTCancellable;
@class ARTStatsQuery;
@class ARTHTTPPaginatedResponse;

NS_ASSUME_NONNULL_BEGIN

@interface ARTRest : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 Instance the Ably library with the given options.
 :param options: see ARTClientOptions for options
 */
- (instancetype)initWithOptions:(ARTClientOptions *)options;

/**
 Instance the Ably library using a key only. This is simply a convenience constructor for the simplest case of instancing the library with a key for basic authentication and no other options.
 :param key; String key (obtained from application dashboard)
 */
- (instancetype)initWithKey:(NSString *)key;
- (instancetype)initWithToken:(NSString *)tokenId;

+ (instancetype)createWithOptions:(ARTClientOptions *)options NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithKey:(NSString *)key NS_SWIFT_UNAVAILABLE("Use instance initializer instead");
+ (instancetype)createWithToken:(NSString *)tokenId NS_SWIFT_UNAVAILABLE("Use instance initializer instead");

- (void)time:(void (^)(NSDate *_Nullable, NSError *_Nullable))callback;

- (BOOL)request:(NSString *)method path:(NSString *)path params:(nullable NSDictionary<NSString *, NSString *> *)params body:(nullable id)body headers:(nullable NSDictionary<NSString *, NSString *> *)headers callback:(void (^)(ARTHTTPPaginatedResponse *_Nullable, ARTErrorInfo *_Nullable))callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (BOOL)stats:(void (^)(ARTPaginatedResult<ARTStats *> *_Nullable, ARTErrorInfo *_Nullable))callback;
- (BOOL)stats:(nullable ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult<ARTStats *> *_Nullable, ARTErrorInfo *_Nullable))callback error:(NSError *_Nullable *_Nullable)errorPtr;

@property (nonatomic, strong, readonly) ARTRestChannels *channels;
@property (nonatomic, strong, readonly) ARTAuth *auth;
@property (nonatomic, strong, readonly) ARTPush *push;
#if TARGET_OS_IOS
@property (nonnull, nonatomic, readonly, getter=device) ARTLocalDevice *device;
@property (nonnull, nonatomic, readonly, getter=device_nosync) ARTLocalDevice *device_nosync;
#endif

@end

NS_ASSUME_NONNULL_END
