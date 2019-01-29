//
//  ARTHttp.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTLog.h>

@class ARTErrorInfo;
@class ARTClientOptions;

@protocol ARTEncoder;

NS_ASSUME_NONNULL_BEGIN

@protocol ARTHTTPExecutor

- (ARTLog *)logger;
- (void)executeRequest:(NSURLRequest *)request completion:(nullable void (^)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable))callback;

@end

@protocol ARTHTTPAuthenticatedExecutor <ARTHTTPExecutor>

- (ARTClientOptions *)options;

- (id<ARTEncoder>)defaultEncoder;

- (void)executeRequest:(NSMutableURLRequest *)request withAuthOption:(ARTAuthentication)authOption completion:(void (^)(NSHTTPURLResponse *_Nullable, NSData * _Nullable, NSError * _Nullable))callback;

@end

@interface ARTHttp : NSObject<ARTHTTPExecutor>

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)init:(dispatch_queue_t)queue logger:(ARTLog *)logger;

@end

NS_ASSUME_NONNULL_END
