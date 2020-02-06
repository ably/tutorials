//
//  ARTTokenRequest.m
//  ably-ios
//
//  Created by Ricardo Pereira on 05/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTTokenRequest.h"
#import "ARTTokenParams.h"
#import "ARTAuth+Private.h"
#import "ARTDefault.h"

@implementation ARTTokenRequest

- (instancetype)initWithTokenParams:(ARTTokenParams *)tokenParams keyName:(NSString *)keyName nonce:(NSString *)nonce mac:(NSString *)mac {
    if (self = [super init]) {
        self.ttl = tokenParams.ttl;
        self.capability = tokenParams.capability;
        self.clientId = tokenParams.clientId;
        self.timestamp = tokenParams.timestamp;
        _keyName = [keyName copy];
        _nonce = [nonce copy];
        _mac = [mac copy];
    }
    return self;
}

- (NSDictionary *)asDictionary {
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"ARTTokenRequest: keyName=%@ clientId=%@ nonce=%@ mac=%@ ttl=%@ capability=%@ timestamp=%@",
            self.keyName, self.clientId, self.nonce, self.mac, self.ttl, self.capability, self.timestamp];
}

+ (ARTTokenRequest *_Nullable)fromJson:(id<ARTJsonCompatible>)json error:(NSError *_Nullable *_Nullable)error {
    NSError *e = nil;
    NSDictionary *dict = [json toJSON:&e];
    if (e) {
        if (error) {
            *error = e;
        }
        return nil;
    }

    ARTTokenParams *tokenParams = [[ARTTokenParams alloc] initWithClientId:dict[@"clientId"]];

    ARTTokenRequest *tokenRequest = [[ARTTokenRequest alloc] initWithTokenParams:tokenParams
                                                                         keyName:dict[@"keyName"]
                                                                           nonce:dict[@"nonce"]
                                                                             mac:dict[@"mac"]];
    tokenRequest.clientId = dict[@"clientId"];
    tokenRequest.ttl = dict[@"ttl"] ? [NSNumber numberWithDouble:millisecondsToTimeInterval([dict[@"ttl"] unsignedLongLongValue])] : nil;
    tokenRequest.capability = dict[@"capability"];
    tokenRequest.timestamp = [NSDate dateWithTimeIntervalSince1970:[dict[@"timestamp"] doubleValue] / 1000];

    return tokenRequest;
}

@end

@implementation ARTTokenRequest (ARTTokenDetailsCompatible)

- (void)toTokenDetails:(ARTAuth *)auth callback:(void (^)(ARTTokenDetails * _Nullable, NSError * _Nullable))callback {
    [auth internalAsync:^(ARTAuthInternal *auth) {
        [auth executeTokenRequest:self callback:callback];
    }];
}

@end
