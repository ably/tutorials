//
//  ARTLocalDeviceStorage.m
//  Ably
//
//  Created by Ricardo Pereira on 18/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTLocalDeviceStorage.h"
#import "ARTLog.h"
#import "ARTLocalDevice+Private.h"
#import <SAMKeychain/SAMKeychain.h>

@implementation ARTLocalDeviceStorage {
    __weak ARTLog *_logger;
}

- (instancetype)initWithLogger:(ARTLog *)logger {
    if (self = [super init]) {
        _logger = logger;
    }
    return self;
}

+ (instancetype)newWithLogger:(ARTLog *)logger {
    return [[self alloc] initWithLogger:logger];
}

- (nullable id)objectForKey:(NSString *)key {
    return [NSUserDefaults.standardUserDefaults objectForKey:key];
}

- (void)setObject:(nullable id)value forKey:(NSString *)key {
    [NSUserDefaults.standardUserDefaults setObject:value forKey:key];
}

- (NSString *)secretForDevice:(ARTDeviceId *)deviceId {
    #if TARGET_OS_IPHONE
    SAMKeychain.accessibilityType = kSecAttrAccessibleWhenUnlocked;
    #endif
    NSError *error = nil;
    NSString *value = [SAMKeychain passwordForService:ARTDeviceSecretKey account:(NSString *)deviceId error:&error];

    if ([error code] == errSecItemNotFound) {
        [_logger debug:__FILE__ line:__LINE__ message:@"Device Secret not found"];
    }
    else if (error) {
        [_logger error:@"Device Secret couldn't be read (%@)", [error localizedDescription]];
    }

    return value;
}

- (void)setSecret:(NSString *)value forDevice:(ARTDeviceId *)deviceId {
    #if TARGET_OS_IPHONE
    SAMKeychain.accessibilityType = kSecAttrAccessibleWhenUnlocked;
    #endif
    NSError *error = nil;

    if (value == nil) {
        [SAMKeychain deletePasswordForService:ARTDeviceSecretKey account:(NSString *)deviceId error:&error];
    }
    else {
        [SAMKeychain setPassword:value forService:ARTDeviceSecretKey account:(NSString *)deviceId error:&error];
    }

    if ([error code] == errSecItemNotFound) {
        [_logger debug:__FILE__ line:__LINE__ message:@"Device Secret not found"];
    }
    else if (error) {
        [_logger error:@"Device Secret couldn't be updated (%@)", [error localizedDescription]];
    }
}

@end
