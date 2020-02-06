//
//  ARTLocalDevice+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 07/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Ably/ARTRest.h>

@protocol ARTDeviceStorage;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ARTDeviceIdKey;
extern NSString *const ARTDeviceSecretKey;
extern NSString *const ARTDeviceIdentityTokenKey;
extern NSString *const ARTDeviceTokenKey;

@interface ARTLocalDevice ()

@property (strong, nonatomic) id<ARTDeviceStorage> storage;

+ (ARTLocalDevice *)load:(NSString *)clientId storage:(id<ARTDeviceStorage>)storage;
- (nullable NSString *)deviceToken;
- (void)setAndPersistDeviceToken:(nullable NSString *)deviceToken;
- (void)setAndPersistIdentityTokenDetails:(nullable ARTDeviceIdentityTokenDetails *)tokenDetails;
- (BOOL)isRegistered;

+ (NSString *)generateId;
+ (NSString *)generateSecret;

@end

NS_ASSUME_NONNULL_END
