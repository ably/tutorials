//
//  ARTTokenParams.h
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTClientOptions.h>

@class ARTTokenRequest;

NS_ASSUME_NONNULL_BEGIN

/**
 Type that provided parameters of a token request.
 */
@interface ARTTokenParams : NSObject<NSCopying>

/**
 Represents time to live (expiry) of this token as a NSTimeInterval.
 */
@property (nonatomic, strong, nullable) NSNumber *ttl;

/**
 Contains the capability JSON stringified.
 */
@property (nonatomic, copy) NSString *capability;

/**
 A clientId to associate with this token.
 */
@property (nullable, nonatomic, copy, readwrite) NSString *clientId;

/**
 Timestamp (in millis since the epoch) of this request. Timestamps, in conjunction with the nonce, are used to prevent n requests from being replayed.
 */
@property (nullable, nonatomic, copy, readwrite) NSDate *timestamp;

@property (nullable, nonatomic, readonly, strong) NSString *nonce;

- (instancetype)init;
- (instancetype)initWithClientId:(NSString *_Nullable)clientId;
- (instancetype)initWithClientId:(NSString *_Nullable)clientId nonce:(NSString *_Nullable)nonce;
- (instancetype)initWithOptions:(ARTClientOptions *)options;
- (instancetype)initWithTokenParams:(ARTTokenParams *)tokenParams;

- (NSMutableArray<NSURLQueryItem *> *)toArray;
- (NSArray<NSURLQueryItem *> *)toArrayWithUnion:(NSArray *)items;
- (NSDictionary<NSString *, NSString *> *)toDictionaryWithUnion:(NSArray<NSURLQueryItem *> *)items;

@end

NS_ASSUME_NONNULL_END
