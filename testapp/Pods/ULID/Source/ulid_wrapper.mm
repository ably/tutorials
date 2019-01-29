//
//  ulid_wrapper.mm
//  ULID
//
//  Created by Ricardo Pereira on 14/02/2017.
//  Copyright © 2017 Whitesmith. All rights reserved.
//

#include "ulid_wrapper.h"

#ifdef __cplusplus
#include <stdio.h>
#include "ulid.hpp"
#endif

typedef ulid::ULID ULIDData; //struct or __uint128_t

@implementation ULID {
    ULIDData _ulid;
}

+ (instancetype)ULID {
    return [[ULID alloc] init];
}

- (instancetype)initWithData:(ULIDData)data {
    if (self == [super self]) {
        _ulid = data;
    }
    return self;
}

- (instancetype)initWithTimestamp:(NSTimeInterval)timestamp generator:(NSUInteger (^)())generator {
    if (self == [super self]) {
        _ulid = ulid::Create(timestamp, [&generator]() { return generator(); });
    }
    return self;
}

- (instancetype)init {
    if (self == [super self]) {
        _ulid = ulid::CreateNowRand();
    }
    return self;
}

- (NSString *)ulidString {
    std::string value = ulid::Marshal(_ulid);
    return [NSString stringWithCString:value.c_str() encoding:[NSString defaultCStringEncoding]];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[ULID allocWithZone:zone] initWithData:_ulid];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[ULID class]]) return NO;
    ULID* other = (ULID*)object;
    return ulid::CompareULIDs(self->_ulid, other->_ulid) == 0;
}

@end
