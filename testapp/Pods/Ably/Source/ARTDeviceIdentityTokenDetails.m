//
//  ARTDeviceIdentityToken.m
//  Ably
//
//  Created by Ricardo Pereira on 21/03/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

#import "ARTDeviceIdentityTokenDetails.h"

NSString *const ARTCoderTokenKey = @"token";
NSString *const ARTCoderIssuedKey = @"issued";
NSString *const ARTCoderExpiresKey = @"expires";
NSString *const ARTCoderCapabilityKey = @"capability";
NSString *const ARTCoderDeviceIdKey = @"deviceId";

@implementation ARTDeviceIdentityTokenDetails

- (instancetype)initWithToken:(NSString *)token issued:(NSDate *)issued expires:(NSDate *)expires capability:(NSString *)capability deviceId:(NSString *)deviceId {
    if (self = [super init]) {
        _token  = token;
        _issued = issued;
        _expires = expires;
        _capability = capability;
        _deviceId = deviceId;
    }
    return self;
}

// MARK: NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - \n\t token: %@; \n\t issued: %@; \n\t expires: %@; \n\t deviceId: %@;", [super description], self.token, self.issued, self.expires, self.deviceId];
}

- (id)copyWithZone:(NSZone *)zone {
    // Implement NSCopying by retaining the original instead of creating a new copy when the class and its contents are immutable.
    return self;
}

#pragma mark - NSCoding

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (!self) {
        return nil;
    }

    _token = [aDecoder decodeObjectOfClass:[NSString class] forKey:ARTCoderTokenKey];
    _issued = [aDecoder decodeObjectOfClass:[NSDate class] forKey:ARTCoderIssuedKey];
    _expires = [aDecoder decodeObjectOfClass:[NSDate class] forKey:ARTCoderExpiresKey];
    _capability = [aDecoder decodeObjectOfClass:[NSString class] forKey:ARTCoderCapabilityKey];
    _deviceId = [aDecoder decodeObjectOfClass:[NSString class] forKey:ARTCoderDeviceIdKey];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.token forKey:ARTCoderTokenKey];
    [aCoder encodeObject:self.issued forKey:ARTCoderIssuedKey];
    [aCoder encodeObject:self.expires forKey:ARTCoderExpiresKey];
    [aCoder encodeObject:self.capability forKey:ARTCoderCapabilityKey];
    [aCoder encodeObject:self.deviceId forKey:ARTCoderDeviceIdKey];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return true;
}

#pragma mark - Archive/Unarchive

- (NSData *)archive {
    if (@available(macOS 10.13, iOS 11, tvOS 11, *)) {
        NSError *error;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self requiringSecureCoding:false error:&error];
        if (error) {
            NSLog(@"ARTDeviceIdentityTokenDetails Archive failed: %@", error);
        }
        return data;
    }
    else {
        return [NSKeyedArchiver archivedDataWithRootObject:self];
    }
}

+ (ARTDeviceIdentityTokenDetails *)unarchive:(NSData *)data {
    if (!data) {
        return nil;
    }
    if (@available(macOS 10.13, iOS 11, tvOS 11, *)) {
        NSError *error;
        ARTDeviceIdentityTokenDetails *result = [NSKeyedUnarchiver unarchivedObjectOfClass:[self class] fromData:data error:&error];
        if (error) {
            NSLog(@"ARTDeviceIdentityTokenDetails Unarchive failed: %@", error);
        }
        return result;
    }
    else {
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
}

@end
