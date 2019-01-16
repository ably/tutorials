//
//  ARTConnectionDetails.h
//  ably
//
//  Created by Ricardo Pereira on 26/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTProtocolMessage;

@interface ARTConnectionDetails : NSObject

NS_ASSUME_NONNULL_BEGIN

@property (readonly, getter=getClientId, nullable) NSString *clientId;
@property (readonly, getter=getConnectionKey, nullable) NSString *connectionKey;
// In those, -1 means 'undefined'.
@property (readonly, nonatomic) NSInteger maxMessageSize;
@property (readonly, nonatomic) NSInteger maxFrameSize;

/**
 Represents the maximum allowable number of requests per second from a client or Ably. In the case of a realtime connection, this restriction applies to the number of ProtocolMessage objects sent, whereas in the case of REST, it is the total number of REST requests per second.
 */
@property (readonly, nonatomic) NSInteger maxInboundRate;

/**
 Represents the duration that Ably will persist the connection state when a Realtime client is abruptly disconnected.
 */
@property (readonly, nonatomic) NSTimeInterval connectionStateTtl;

/**
 Represents a unique identifier for the front-end server that the client has connected to. This server ID is only used for the purposes of debugging.
 */
@property (readonly, strong, nonatomic, nullable) NSString *serverId;

/**
 Represents the maximum length of time in seconds that the server will allow no activity to occur in the server -> client direction. After such a period of inactivity, the server will send a HEARTBEAT or transport-level ping to the client. If the value is 0, the server will allow arbitrarily-long levels of inactivity.
 */
@property (readonly, nonatomic) NSTimeInterval maxIdleInterval;

- (instancetype)initWithClientId:(NSString *_Nullable)clientId
                   connectionKey:(NSString *_Nullable)connectionKey
                  maxMessageSize:(NSInteger)maxMessageSize
                    maxFrameSize:(NSInteger)maxFrameSize
                  maxInboundRate:(NSInteger)maxInboundRate
              connectionStateTtl:(NSTimeInterval)connectionStateTtl
                        serverId:(NSString *)serverId
                 maxIdleInterval:(NSTimeInterval)maxIdleInterval;

NS_ASSUME_NONNULL_END

@end
