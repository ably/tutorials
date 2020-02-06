//
//  ARTConnectionDetails.m
//  ably
//
//  Created by Ricardo Pereira on 26/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTConnectionDetails+Private.h"

@implementation ARTConnectionDetails

- (instancetype)initWithClientId:(NSString *_Nullable)clientId
                   connectionKey:(NSString *_Nullable)connectionKey
                  maxMessageSize:(NSInteger)maxMessageSize
                    maxFrameSize:(NSInteger)maxFrameSize
                  maxInboundRate:(NSInteger)maxInboundRate
              connectionStateTtl:(NSTimeInterval)connectionStateTtl
                        serverId:(NSString *)serverId
                 maxIdleInterval:(NSTimeInterval)maxIdleInterval {
    if (self = [super init]) {
        _clientId = clientId;
        _connectionKey = connectionKey;
        _maxMessageSize = maxMessageSize;
        _maxFrameSize = maxFrameSize;
        _maxInboundRate = maxInboundRate;
        _connectionStateTtl = connectionStateTtl;
        _serverId = serverId;
        _maxIdleInterval = maxIdleInterval;
    }
    return self;
}

- (void)setMaxIdleInterval:(NSTimeInterval)seconds {
    _maxIdleInterval = seconds;
}

@end
