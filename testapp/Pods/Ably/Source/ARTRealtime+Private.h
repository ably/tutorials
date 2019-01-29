//
//  ARTRealtime+Private.h
//  ably-ios
//
//  Created by vic on 24/03/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Ably/ARTRealtime.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTTypes.h>
#import <Ably/ARTQueuedMessage.h>
#import <Ably/ARTPendingMessage.h>
#import <Ably/ARTProtocolMessage.h>
#import <Ably/ARTReachability.h>

#import <Ably/ARTRealtimeTransport.h>
#import <Ably/ARTAuth+Private.h>
#import <Ably/ARTRest+Private.h>

@class ARTRest;
@class ARTErrorInfo;
@class ARTProtocolMessage;
@class ARTConnection;

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtime () <ARTRealtimeTransportDelegate, ARTAuthDelegate>

@property (readonly, strong, nonatomic) ARTEventEmitter<ARTEvent *, ARTConnectionStateChange *> *internalEventEmitter;
@property (readonly, strong, nonatomic) ARTEventEmitter<ARTEvent *, NSNull *> *connectedEventEmitter;

// State properties
- (BOOL)shouldSendEvents;
- (BOOL)shouldQueueEvents;
- (ARTStatus *)defaultError;

// Message sending
- (void)sendQueuedMessages;
- (void)failQueuedMessages:(ARTStatus *)error;

@end

/// ARTRealtime private methods that are used for whitebox testing.
@interface ARTRealtime ()

@property (readwrite, strong, nonatomic) ARTRest *rest;
@property (readonly, nullable) id<ARTRealtimeTransport> transport;
@property (readonly, strong, nonatomic, nonnull) id<ARTReachability> reachability;
@property (readonly, getter=getLogger) ARTLog *logger;
@property (nonatomic) NSTimeInterval connectionStateTtl;
@property (nonatomic) NSTimeInterval maxIdleInterval;

/// Current protocol `msgSerial`. Starts at zero.
@property (readwrite, assign, nonatomic) int64_t msgSerial;

/// List of queued messages on a connection in the disconnected or connecting states.
@property (readwrite, strong, nonatomic) NSMutableArray<ARTQueuedMessage *> *queuedMessages;

/// List of pending messages waiting for ACK/NACK action to confirm the success receipt and acceptance.
@property (readwrite, strong, nonatomic) NSMutableArray<ARTPendingMessage *> *pendingMessages;

/// First `msgSerial` pending message.
@property (readwrite, assign, nonatomic) int64_t pendingMessageStartSerial;

/// Client is trying to resume the last connection
@property (readwrite, assign, nonatomic) BOOL resuming;

@property (readonly, getter=getClientOptions) ARTClientOptions *options;

/// Suspend the behavior defined in RTN15a, that is trying to immediately reconnect after a disconnection
@property (readwrite, assign, nonatomic) BOOL suspendImmediateReconnection;

@end

@interface ARTRealtime (Private)

- (BOOL)isActive;

// Transport Events
- (void)onHeartbeat;
- (void)onConnected:(ARTProtocolMessage *)message;
- (void)onDisconnected;
- (void)onClosed;
- (void)onSuspended;
- (void)onError:(ARTProtocolMessage *)message;
- (void)onAck:(ARTProtocolMessage *)message;
- (void)onNack:(ARTProtocolMessage *)message;
- (void)onChannelMessage:(ARTProtocolMessage *)message;

- (void)setTransportClass:(Class)transportClass;
- (void)setReachabilityClass:(Class _Nullable)reachabilityClass;

// Message sending
- (void)send:(ARTProtocolMessage *)msg sentCallback:(nullable void (^)(ARTErrorInfo *_Nullable))sentCallback ackCallback:(nullable void (^)(ARTStatus *))ackCallback;

- (void)onUncaughtException:(NSException *)e;
- (NSDictionary *)sentryExtra;
- (NSArray<NSDictionary *> *)sentryBreadcrumbs;

@end

NS_ASSUME_NONNULL_END

#define ART_TRY_OR_MOVE_TO_FAILED_START(realtime) \
	do {\
	ARTRealtime *__realtime = realtime;\
    BOOL __started = ARTstartHandlingUncaughtExceptions(__realtime.rest);\
    BOOL __caught = false;\
	@try {\
		do {\

#define ART_TRY_OR_MOVE_TO_FAILED_END \
		} while(0); \
	}\
	@catch(NSException *e) {\
		__caught = true;\
        if (!__started) {\
            @throw e;\
        }\
		[__realtime onUncaughtException:e];\
	}\
	@finally {\
		if (!__caught && __started) {\
            ARTstopHandlingUncaughtExceptions(__realtime.rest);\
		}\
	}\
	} while(0);
