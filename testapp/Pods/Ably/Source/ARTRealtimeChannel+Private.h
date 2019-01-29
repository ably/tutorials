
//
//  ARTRealtimeChannel+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Ably/ARTRestChannel.h>
#import <Ably/ARTRealtimeChannel.h>
#import <Ably/ARTPresenceMap.h>
#import <Ably/ARTEventEmitter.h>

@class ARTProtocolMessage;

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimeChannel () <ARTPresenceMapDelegate>

- (ARTRealtimeChannelState)state_nosync;
- (ARTErrorInfo *)errorReason_nosync;
- (NSString *_Nullable)clientId_nosync;

@property (readonly, weak, nonatomic) ARTRealtime *realtime;
@property (readonly, strong, nonatomic) ARTRestChannel *restChannel;
@property (readwrite, strong, nonatomic) NSMutableArray *queuedMessages;
@property (readwrite, strong, nonatomic, nullable) NSString *attachSerial;
@property (readonly, nullable, getter=getClientId) NSString *clientId;
@property (readonly, strong, nonatomic) ARTEventEmitter<ARTEvent *, ARTChannelStateChange *> *internalEventEmitter;
@property (readonly, strong, nonatomic) ARTEventEmitter<ARTEvent *, ARTChannelStateChange *> *statesEventEmitter;
@property (readonly, strong, nonatomic) ARTEventEmitter<id<ARTEventIdentification>, ARTMessage *> *messagesEventEmitter;
@property (readonly, strong, nonatomic) ARTEventEmitter<ARTEvent *, ARTPresenceMessage *> *presenceEventEmitter;
@property (readwrite, strong, nonatomic) ARTPresenceMap *presenceMap;
@property (readwrite, assign, nonatomic) ARTPresenceAction lastPresenceAction;

- (instancetype)initWithRealtime:(ARTRealtime *)realtime andName:(NSString *)name withOptions:(ARTChannelOptions *)options;
+ (instancetype)channelWithRealtime:(ARTRealtime *)realtime andName:(NSString *)name withOptions:(ARTChannelOptions *)options;

- (bool)isLastChannelSerial:(NSString *)channelSerial;

- (void)reattachWithReason:(nullable ARTErrorInfo *)reason callback:(nullable void (^)(ARTErrorInfo *))callback;

- (void)_attach:(void (^_Nullable)(ARTErrorInfo * _Nullable))callback;
- (void)_detach:(void (^_Nullable)(ARTErrorInfo * _Nullable))callback;

- (void)_unsubscribe;
- (void)off_nosync;

@end

@interface ARTRealtimeChannel (Private)

- (void)transition:(ARTRealtimeChannelState)state status:(ARTStatus *)status;

- (void)onChannelMessage:(ARTProtocolMessage *)message;
- (void)publishPresence:(ARTPresenceMessage *)pm callback:(nullable void (^)(ARTErrorInfo *_Nullable))cb;
- (void)publishProtocolMessage:(ARTProtocolMessage *)pm callback:(void (^)(ARTStatus *))cb;

- (void)setAttached:(ARTProtocolMessage *)message;
- (void)setDetached:(ARTProtocolMessage *)message;

- (void)onMessage:(ARTProtocolMessage *)message;
- (void)onPresence:(ARTProtocolMessage *)message;
- (void)onSync:(ARTProtocolMessage *)message;
- (void)onError:(ARTProtocolMessage *)error;

- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus *)status;
- (void)sendMessage:(ARTProtocolMessage *)pm callback:(void (^)(ARTStatus *))cb;

- (void)setSuspended:(ARTStatus *)status;
- (void)setFailed:(ARTStatus *)status;
- (void)throwOnDisconnectedOrFailed;

- (void)broadcastPresence:(ARTPresenceMessage *)pm;
- (void)detachChannel:(ARTStatus *)status;

- (void)requestContinueSync;

@end

NS_ASSUME_NONNULL_END
