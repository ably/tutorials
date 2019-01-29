//
//  ARTAuth.h
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTLog.h>

@class ARTRest;
@class ARTLog;
@class ARTClientOptions;
@class ARTAuthOptions;
@class ARTTokenParams;
@class ARTTokenDetails;
@class ARTTokenRequest;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ARTAuth

@interface ARTAuth : NSObject

@property (nullable, readonly) NSString *clientId;

- (instancetype)init NS_UNAVAILABLE;

/**
 # (RSA8) Auth#requestToken
 
 Implicitly creates a `TokenRequest` if required, and requests a token from Ably if required.
 
 `TokenParams` and `AuthOptions` are optional.
 When provided, the values supersede matching client library configured params and options.
 
 - Parameter tokenParams: Token params (optional).
 - Parameter authOptions: Authentication options (optional).
 - Parameter callback: Completion callback (ARTTokenDetails, NSError).
 */
- (void)requestToken:(nullable ARTTokenParams *)tokenParams withOptions:(nullable ARTAuthOptions *)authOptions
            callback:(void (^)(ARTTokenDetails *_Nullable, NSError *_Nullable))callback;
- (void)requestToken:(void (^)(ARTTokenDetails *_Nullable, NSError *_Nullable))callback;

- (void)authorize:(nullable ARTTokenParams *)tokenParams options:(nullable ARTAuthOptions *)authOptions
         callback:(void (^)(ARTTokenDetails *_Nullable, NSError *_Nullable))callback;
- (void)authorize:(void (^)(ARTTokenDetails *_Nullable, NSError *_Nullable))callback;

- (void)createTokenRequest:(nullable ARTTokenParams *)tokenParams options:(nullable ARTAuthOptions *)options
                  callback:(void (^)(ARTTokenRequest *_Nullable tokenRequest, NSError *_Nullable error))callback;
- (void)createTokenRequest:(void (^)(ARTTokenRequest *_Nullable tokenRequest, NSError *_Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
