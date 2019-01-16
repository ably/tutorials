//
//  ARTProtocolMessage+Private.h
//  ably-ios
//
//  Created by Toni Cárdenas on 26/01/2016.
//  Copyright (c) 2014 Ably. All rights reserved.
//

/// ARTProtocolMessageFlag bitmask
typedef NS_OPTIONS(NSUInteger, ARTProtocolMessageFlag) {
    ARTProtocolMessageFlagHasPresence = (1UL << 0),
    ARTProtocolMessageFlagHasBacklog = (1UL << 1),
    ARTProtocolMessageFlagResumed = (1UL << 2),
    ARTProtocolMessageFlagHasLocalPresence = (1UL << 3),
    ARTProtocolMessageFlagTransient = (1UL << 4),
    ARTProtocolMessageFlagPresence = (1UL << 16),
    ARTProtocolMessageFlagPublish = (1UL << 17),
    ARTProtocolMessageFlagSubscribe = (1UL << 18),
    ARTProtocolMessageFlagPresenceSubscribe = (1UL << 19)
};

NS_ASSUME_NONNULL_BEGIN

@interface ARTProtocolMessage ()

@property (readwrite, assign, nonatomic) BOOL hasConnectionSerial;
@property (readonly, assign, nonatomic) BOOL ackRequired;

@property (readonly, assign, nonatomic) BOOL hasPresence;
@property (readonly, assign, nonatomic) BOOL hasBacklog;
@property (readonly, assign, nonatomic) BOOL resumed;

- (BOOL)mergeFrom:(ARTProtocolMessage *)msg;

@end

NS_ASSUME_NONNULL_END
