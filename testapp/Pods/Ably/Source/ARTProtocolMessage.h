//
//  ARTProtocolMessage.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTMessage.h>
#import <Ably/ARTPresenceMessage.h>

@class ARTConnectionDetails;
@class ARTAuthDetails;
@class ARTErrorInfo;
@class ARTMessage;
@class ARTPresenceMessage;

typedef NS_ENUM(NSUInteger, ARTProtocolMessageAction) {
    ARTProtocolMessageHeartbeat = 0,
    ARTProtocolMessageAck = 1,
    ARTProtocolMessageNack = 2,
    ARTProtocolMessageConnect = 3,
    ARTProtocolMessageConnected = 4,
    ARTProtocolMessageDisconnect = 5,
    ARTProtocolMessageDisconnected = 6,
    ARTProtocolMessageClose = 7,
    ARTProtocolMessageClosed = 8,
    ARTProtocolMessageError = 9,
    ARTProtocolMessageAttach = 10,
    ARTProtocolMessageAttached = 11,
    ARTProtocolMessageDetach = 12,
    ARTProtocolMessageDetached = 13,
    ARTProtocolMessagePresence = 14,
    ARTProtocolMessageMessage = 15,
    ARTProtocolMessageSync = 16,
    ARTProtocolMessageAuth = 17,
};

NSString *_Nonnull ARTProtocolMessageActionToStr(ARTProtocolMessageAction action);

NS_ASSUME_NONNULL_BEGIN

/**
 A message sent and received over the Realtime protocol.
 A ProtocolMessage always relates to a single channel only, but can contain multiple individual Messages or PresenceMessages.
 ProtocolMessages are serially numbered on a connection.
 */
@interface ARTProtocolMessage : NSObject

@property (readwrite, assign, nonatomic) ARTProtocolMessageAction action;
@property (readwrite, assign, nonatomic) int count;
@property (nullable, readwrite, strong, nonatomic) ARTErrorInfo *error;
@property (nullable, readwrite, strong, nonatomic) NSString *id;
@property (nullable, readwrite, strong, nonatomic) NSString *channel;
@property (nullable, readwrite, strong, nonatomic) NSString *channelSerial;
@property (nullable, readwrite, strong, nonatomic) NSString *connectionId;
@property (nullable, readwrite, strong, nonatomic, getter=getConnectionKey) NSString *connectionKey;
@property (readwrite, assign, nonatomic) int64_t connectionSerial;
@property (nullable, readwrite, strong, nonatomic) NSNumber *msgSerial;
@property (nullable, readwrite, strong, nonatomic) NSDate *timestamp;
@property (nullable, readwrite, strong, nonatomic) NSArray<ARTMessage *> *messages;
@property (nullable, readwrite, strong, nonatomic) NSArray<ARTPresenceMessage *> *presence;
@property (readwrite, assign, nonatomic) int64_t flags;
@property (nullable, readwrite, nonatomic) ARTConnectionDetails *connectionDetails;
@property (nullable, nonatomic) ARTAuthDetails *auth;

@end

NS_ASSUME_NONNULL_END
