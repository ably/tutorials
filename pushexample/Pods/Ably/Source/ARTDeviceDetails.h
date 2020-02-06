//
//  ARTDeviceDetails.h
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTPush.h>

@class ARTDevicePushDetails;

NS_ASSUME_NONNULL_BEGIN

@interface ARTDeviceDetails : NSObject

/**
 Device identity generated using random data. It's an ULID string (Universally Unique Lexicographically Sortable Identifier).
 */
@property (nonatomic) ARTDeviceId *id;

/**
 Device secret generated using random data with sufficient entropy. It's a sha256 digest encoded with base64.
 */
@property (nullable, nonatomic) ARTDeviceSecret *secret;

@property (nullable, nonatomic) NSString *clientId;
@property (nonatomic) NSString *platform;
@property (nonatomic) NSString *formFactor;
@property (nonatomic) NSMutableDictionary<NSString *, NSString *> *metadata;
@property (nonatomic) ARTDevicePushDetails *push;

- (instancetype)init;
- (instancetype)initWithId:(ARTDeviceId *)deviceId;

@end

NS_ASSUME_NONNULL_END
