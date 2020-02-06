//
//  ARTLocalDevice.m
//  Ably
//
//  Created by Ricardo Pereira on 28/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTLocalDevice+Private.h"
#import "ARTDevicePushDetails.h"
#import "ARTPush.h"
#import "ARTEncoder.h"
#import "ARTDeviceStorage.h"
#import "ARTDeviceIdentityTokenDetails.h"
#import "ARTCrypto+Private.h"
#import <ULID/ULID.h>

NSString *const ARTDevicePlatform = @"ios";

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
NSString *const ARTDeviceFormFactor = @"phone";
#elif TARGET_OS_TV
NSString *const ARTDeviceFormFactor = @"tv";
#elif TARGET_OS_WATCH
NSString *const ARTDeviceFormFactor = @"watch";
#elif TARGET_OS_SIMULATOR
NSString *const ARTDeviceFormFactor = @"simulator";
#elif TARGET_OS_MAC
NSString *const ARTDeviceFormFactor = @"desktop";
#else
NSString *const ARTDeviceFormFactor = @"embedded";
#endif

NSString *const ARTDevicePushTransportType = @"apns";

@implementation ARTLocalDevice

- (instancetype)initWithClientId:(NSString *)clientId storage:(id<ARTDeviceStorage>)storage {
    if (self = [super init]) {
        self.clientId = clientId;
        self.storage = storage;
    }
    return self;
}

+ (ARTLocalDevice *)load:(NSString *)clientId storage:(id<ARTDeviceStorage>)storage {
    ARTLocalDevice *device = [[ARTLocalDevice alloc] initWithClientId:clientId storage:storage];
    device.platform = ARTDevicePlatform;
    #if TARGET_OS_IOS
    switch (UI_USER_INTERFACE_IDIOM()) {
        case UIUserInterfaceIdiomPad:
            device.formFactor = @"tablet";
        case UIUserInterfaceIdiomCarPlay:
            device.formFactor = @"car";
        default:
            device.formFactor = ARTDeviceFormFactor;
    }
    #else
    device.formFactor = ARTDeviceFormFactor;
    #endif
    device.push.recipient[@"transportType"] = ARTDevicePushTransportType;

    NSString *deviceId = [storage objectForKey:ARTDeviceIdKey];
    if (!deviceId) {
        deviceId = [self generateId];
        [storage setObject:deviceId forKey:ARTDeviceIdKey];
    }
    device.id = deviceId;

    NSString *deviceSecret = [storage secretForDevice:deviceId];
    if (!deviceSecret) {
        deviceSecret = [self generateSecret];
        [storage setSecret:deviceSecret forDevice:deviceId];
    }
    device.secret = deviceSecret;

    id identityTokenDetailsInfo = [storage objectForKey:ARTDeviceIdentityTokenKey];
    ARTDeviceIdentityTokenDetails *identityTokenDetails = [ARTDeviceIdentityTokenDetails unarchive:identityTokenDetailsInfo];
    device->_identityTokenDetails = identityTokenDetails;

    [device setDeviceToken:[storage objectForKey:ARTDeviceTokenKey]];

    return device;
}

+ (NSString *)generateId {
    return [[ULID new] ulidString];
}

+ (NSString *)generateSecret {
    NSData *randomData = [ARTCrypto generateSecureRandomData:32];
    NSData *hash = [ARTCrypto generateHashSHA256:randomData];
    return [hash base64EncodedStringWithOptions:0];
}

- (NSString *)deviceToken {
    return self.push.recipient[@"deviceToken"];
}

- (void)setDeviceToken:(NSString *_Nonnull)token {
    self.push.recipient[@"deviceToken"] = token;
}

- (void)setAndPersistDeviceToken:(NSString *)deviceToken {
    [self.storage setObject:deviceToken forKey:ARTDeviceTokenKey];
    [self setDeviceToken:deviceToken];
}

- (void)setAndPersistIdentityTokenDetails:(ARTDeviceIdentityTokenDetails *)tokenDetails {
    [self.storage setObject:[tokenDetails archive] forKey:ARTDeviceIdentityTokenKey];
    _identityTokenDetails = tokenDetails;
}

- (BOOL)isRegistered {
    return _identityTokenDetails != nil;
}

@end
