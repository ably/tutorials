//
//  ARTTokenRequest.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTTokenParams.h>
#import <Ably/ARTAuthOptions.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Type containing the token request details.
 */
@interface ARTTokenRequest : NSObject

/**
 Identifier for the key (public).
 */
@property (nonatomic, readonly, copy) NSString *keyName;

/**
 A clientId to associate with this token.
 */
@property (nullable, nonatomic, copy, readwrite) NSString *clientId;

/**
 Unique 16+ character nonce.
 */
@property (nonatomic, readonly, copy) NSString *nonce;

/**
 Valid HMAC is created using the key secret.
 */
@property (nonatomic, readonly, copy) NSString *mac;

/**
 Contains the capability JSON stringified.
 */
@property (nonatomic, copy) NSString *capability;

/**
 Represents time to live (expiry) of this token as a NSTimeInterval.
 */
@property (nonatomic, strong, nullable) NSNumber *ttl;

/**
 Timestamp (in millis since the epoch) of this request. Timestamps, in conjunction with the nonce, are used to prevent n requests from being replayed.
 */
@property (nonatomic, strong) NSDate *timestamp;


- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithTokenParams:(ARTTokenParams *)tokenParams keyName:(NSString *)keyName nonce:(NSString *)nonce mac:(NSString *)mac;

+ (ARTTokenRequest *_Nullable)fromJson:(id<ARTJsonCompatible>)json error:(NSError *_Nullable *_Nullable)error;

@end

@interface ARTTokenRequest (ARTTokenDetailsCompatible) <ARTTokenDetailsCompatible>
@end

NS_ASSUME_NONNULL_END
