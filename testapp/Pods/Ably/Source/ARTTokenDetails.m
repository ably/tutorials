//
//  ARTTokenDetails.m
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTTokenDetails.h"

@implementation ARTTokenDetails

- (instancetype)initWithToken:(NSString *)token expires:(NSDate *)expires issued:(NSDate *)issued capability:(NSString *)capability clientId:(NSString *)clientId {
    if (self = [super init]) {
        _token  = [token copy];
        _expires = expires;
        _issued = issued;
        _capability = [capability copy];
        _clientId = [clientId copy];
    }
    return self;
}

- (instancetype)initWithToken:(NSString *)token {
    if (self = [super init]) {
        _token = [token copy];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"ARTTokenDetails: token=%@ clientId=%@ issued=%@ expires=%@",
            self.token, self.clientId, self.issued, self.expires];
}

- (id)copyWithZone:(NSZone *)zone {
    ARTTokenDetails *tokenDetails = [[[self class] allocWithZone:zone] init];
    tokenDetails->_token = self.token;
    tokenDetails->_expires = self.expires;
    tokenDetails->_issued = self.issued;
    tokenDetails->_capability = self.capability;
    tokenDetails->_clientId = self.clientId;
    return tokenDetails;
}

+ (ARTTokenDetails *_Nullable)fromJson:(id<ARTJsonCompatible>)json error:(NSError *_Nullable *_Nullable)error {
    NSError *e = nil;
    NSDictionary *dict = [json toJSON:&e];
    if (e) {
        if (error) {
            *error = e;
        }
        return nil;
    }

    NSNumber *expiresInterval = [dict objectForKey:@"expires"];
    NSDate *expires = expiresInterval ? [NSDate dateWithTimeIntervalSince1970:(expiresInterval.doubleValue) / 1000] : nil;
    NSNumber *issuedInterval = [dict objectForKey:@"issued"];
    NSDate *issued = issuedInterval ? [NSDate dateWithTimeIntervalSince1970:(issuedInterval.doubleValue) / 1000] : nil;

    return [[ARTTokenDetails alloc] initWithToken:dict[@"token"]
                                          expires:expires
                                           issued:issued
                                       capability:dict[@"capability"]
                                         clientId:dict[@"clientId"]];
}

@end

@class ARTAuth;

@implementation ARTTokenDetails (ARTTokenDetailsCompatible)

- (void)toTokenDetails:(ARTAuth *)auth callback:(void (^)(ARTTokenDetails * _Nullable, NSError * _Nullable))callback {
    callback(self, nil);
}

@end
