
//
//  ARTRealtime.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTRealtime+Private.h"

#import "ARTRealtimeChannel+Private.h"
#import "ARTStatus.h"
#import "ARTDefault.h"
#import "ARTRest+Private.h"
#import "ARTAuth+Private.h"
#import "ARTTokenDetails.h"
#import "ARTMessage.h"
#import "ARTClientOptions.h"
#import "ARTChannelOptions.h"
#import "ARTPresenceMessage.h"
#import "ARTWebSocketTransport.h"
#import "ARTOSReachability.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTPresenceMap.h"
#import "ARTProtocolMessage.h"
#import "ARTProtocolMessage+Private.h"
#import "ARTEventEmitter+Private.h"
#import "ARTQueuedMessage.h"
#import "ARTPendingMessage.h"
#import "ARTConnection+Private.h"
#import "ARTConnectionDetails.h"
#import "ARTStats.h"
#import "ARTRealtimeTransport.h"
#import "ARTFallback.h"
#import "ARTAuthDetails.h"
#import "ARTGCD.h"
#import "ARTEncoder.h"
#import "ARTLog+Private.h"
#import "ARTSentry.h"
#import "ARTRealtimeChannels+Private.h"
#import "ARTPush+Private.h"

@interface ARTConnectionStateChange ()

- (void)setRetryIn:(NSTimeInterval)retryIn;

@end

#pragma mark - ARTRealtime implementation

@implementation ARTRealtime {
    BOOL _resuming;
    BOOL _renewingToken;
    BOOL _suspendImmediateReconnection;
    ARTEventEmitter<ARTEvent *, ARTErrorInfo *> *_pingEventEmitter;
    NSDate *_startedReconnection;
    NSDate *_lastActivity;
    Class _transportClass;
    Class _reachabilityClass;
    id<ARTRealtimeTransport> _transport;
    ARTFallback *_fallbacks;
    __weak ARTEventListener *_connectionRetryFromSuspendedListener;
    __weak ARTEventListener *_connectionRetryFromDisconnectedListener;
    __weak ARTEventListener *_connectingTimeoutListener;
    dispatch_block_t _authenitcatingTimeoutWork;
    dispatch_block_t _idleTimer;
    dispatch_queue_t _userQueue;
    dispatch_queue_t _queue;
}

@synthesize authorizationEmitter = _authorizationEmitter;

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        NSAssert(options, @"ARTRealtime: No options provided");
        
        _rest = [[ARTRest alloc] initWithOptions:options realtime:self];
        _userQueue = _rest.userQueue;
        _queue = _rest.queue;
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
        _internalEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_rest.queue];
        _connectedEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_rest.queue];
        _pingEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_rest.queue];
        _channels = [[ARTRealtimeChannels alloc] initWithRealtime:self];
        _transport = nil;
        _transportClass = [ARTWebSocketTransport class];
        _reachabilityClass = [ARTOSReachability class];
        _msgSerial = 0;
        _queuedMessages = [NSMutableArray array];
        _pendingMessages = [NSMutableArray array];
        _pendingMessageStartSerial = 0;
        _connection = [[ARTConnection alloc] initWithRealtime:self];
        _connectionStateTtl = [ARTDefault connectionStateTtl];
        _authorizationEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_rest.queue];
        self.auth.delegate = self;

        [self.connection setState:ARTRealtimeInitialized];

        [self.logger verbose:__FILE__ line:__LINE__ message:@"R:%p initialized with RS:%p", self, _rest];

        self.rest.prioritizedHost = nil;

        if (options.autoConnect) {
            [self _connect];
        }
} ART_TRY_OR_MOVE_TO_FAILED_END
    }
    return self;
}

- (void)auth:(ARTAuth *)auth didAuthorize:(ARTTokenDetails *)tokenDetails {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    switch (self.connection.state_nosync) {
        case ARTRealtimeConnected: {
                // Update (send AUTH message)
                [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p AUTH message using %@", _rest, tokenDetails];
                ARTProtocolMessage *msg = [[ARTProtocolMessage alloc] init];
                msg.action = ARTProtocolMessageAuth;
                msg.auth = [[ARTAuthDetails alloc] initWithToken:tokenDetails.token];
                [self send:msg sentCallback:nil ackCallback:nil];
            }
            break;
        case ARTRealtimeConnecting: {
                switch (_transport.state) {
                    case ARTRealtimeTransportStateOpening:
                    case ARTRealtimeTransportStateOpened: {
                            // Halt the current connection and reconnect with the most recent token
                            [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p halt current connection and reconnect with %@", _rest, tokenDetails];
                            [_transport abort:[ARTStatus state:ARTStateOk]];
                            _transport = [[_transportClass alloc] initWithRest:self.rest options:self.options resumeKey:_transport.resumeKey connectionSerial:_transport.connectionSerial];
                            _transport.delegate = self;
                            [_transport connectWithToken:tokenDetails.token];
                        }
                        break;
                    case ARTRealtimeTransportStateClosed:
                    case ARTRealtimeTransportStateClosing:
                        // Ignore
                        [_authorizationEmitter off];
                        break;
                }
            }
            break;
        case ARTRealtimeClosing: {
                // Should ignore because the connection is being closed
                [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p new connection from authorize has been ignored because the connection is being closed", _rest];
                break;
            }
        default:
            // Client state is NOT Connecting or Connected, so it should start a new connection
            [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p new connection from successfull authorize %@", _rest, tokenDetails];
            [self transition:ARTRealtimeConnecting];
            break;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithKey:key]];
}

- (instancetype)initWithToken:(NSString *)token {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithToken:token]];
}

+ (instancetype)createWithOptions:(ARTClientOptions *)options {
    return [[ARTRealtime alloc] initWithOptions:options];
}

+ (instancetype)createWithKey:(NSString *)key {
    return [[ARTRealtime alloc] initWithKey:key];
}

+ (instancetype)createWithToken:(NSString *)tokenId {
    return [[ARTRealtime alloc] initWithToken:tokenId];
}

- (id<ARTRealtimeTransport>)transport {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    return _transport;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTLog *)getLogger {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    return _rest.logger;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTClientOptions *)getClientOptions {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    return _rest.options;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSString *)getClientId {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    // Doesn't need synchronization since it's immutable.
    return _rest.options.clientId;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSString *)description {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    NSString *info;
    if (self.options.token) {
        info = [NSString stringWithFormat:@"token: %@", self.options.token];
    }
    else if (self.options.authUrl) {
        info = [NSString stringWithFormat:@"authUrl: %@", self.options.authUrl];
    }
    else if (self.options.authCallback) {
        info = [NSString stringWithFormat:@"authCallback: %@", self.options.authCallback];
    }
    else {
        info = [NSString stringWithFormat:@"key: %@", self.options.key];
    }
    return [NSString stringWithFormat:@"%@ - \n\t %@;", [super description], info];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTAuth *)auth {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    return self.rest.auth;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTPush *)push {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    return self.rest.push;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)dealloc {
    [self.logger verbose:__FILE__ line:__LINE__ message:@"R:%p dealloc", self];

    self.rest.prioritizedHost = nil;
}

- (void)connect {
dispatch_sync(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self _connect];
} ART_TRY_OR_MOVE_TO_FAILED_END
});
}

- (void)_connect {
    if(self.connection.state_nosync == ARTRealtimeClosing) {
        // New connection
        _transport = nil;
    }
    [self transition:ARTRealtimeConnecting];
}

- (void)close {
dispatch_sync(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self _close];
} ART_TRY_OR_MOVE_TO_FAILED_END
});
}

- (void)_close {
    [_reachability off];
    [self cancelTimers];

    switch (self.connection.state_nosync) {
    case ARTRealtimeInitialized:
    case ARTRealtimeClosing:
    case ARTRealtimeClosed:
    case ARTRealtimeFailed:
        return;
    case ARTRealtimeConnecting: {
        [_internalEventEmitter once:^(ARTConnectionStateChange *change) {
            [self _close];
        }];
        return;
    }
    case ARTRealtimeDisconnected:
    case ARTRealtimeSuspended:
        [self transition:ARTRealtimeClosed];
        break;
    case ARTRealtimeConnected:
        [self transition:ARTRealtimeClosing];
        break;
    }
}

- (void)time:(void(^)(NSDate *time, NSError *error))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self.rest time:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)ping:(void (^)(ARTErrorInfo *)) cb {
    if (cb) {
        void (^userCallback)(ARTErrorInfo *_Nullable error) = cb;
        cb = ^(ARTErrorInfo *_Nullable error) {
            ART_EXITING_ABLY_CODE(self->_rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    switch (self.connection.state_nosync) {
    case ARTRealtimeInitialized:
    case ARTRealtimeSuspended:
    case ARTRealtimeClosing:
    case ARTRealtimeClosed:
    case ARTRealtimeFailed:
        cb([ARTErrorInfo createWithCode:0 status:ARTStateConnectionFailed message:[NSString stringWithFormat:@"Can't ping a %@ connection", ARTRealtimeConnectionStateToStr(self.connection.state_nosync)]]);
        return;
    case ARTRealtimeConnecting:
    case ARTRealtimeDisconnected:
    case ARTRealtimeConnected:
        if (![self shouldSendEvents]) {
            [self->_connectedEventEmitter once:^(NSNull *n) {
                [self ping:cb];
            }];
            return;
        }
        [[[self->_pingEventEmitter once:cb] setTimer:[ARTDefault realtimeRequestTimeout] onTimeout:^{
            [self.logger verbose:__FILE__ line:__LINE__ message:@"R:%p ping timed out", self];
            cb([ARTErrorInfo createWithCode:ARTCodeErrorConnectionTimedOut status:ARTStateConnectionFailed message:@"timed out"]);
        }] startTimer];
        [self.transport sendPing];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
});
}

- (BOOL)stats:(void (^)(ARTPaginatedResult<ARTStats *> *, ARTErrorInfo *))callback {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    return [self stats:[[ARTStatsQuery alloc] init] callback:callback error:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)stats:(ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult<ARTStats *> *, ARTErrorInfo *))callback error:(NSError **)errorPtr {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    return [self.rest stats:query callback:callback error:errorPtr];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)transition:(ARTRealtimeConnectionState)state {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self transition:state withErrorInfo:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)transition:(ARTRealtimeConnectionState)state withErrorInfo:(ARTErrorInfo *)errorInfo {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p realtime state transitions to %tu - %@", self, state, ARTRealtimeConnectionStateToStr(state)];

    ARTConnectionStateChange *stateChange = [[ARTConnectionStateChange alloc] initWithCurrent:state previous:self.connection.state_nosync event:(ARTRealtimeConnectionEvent)state reason:errorInfo retryIn:0];
    [self.connection setState:state];

    if (errorInfo != nil) {
        [self.connection setErrorReason:errorInfo];
    }

    ARTEventListener *stateChangeEventListener = [self transitionSideEffects:stateChange];

    [_internalEventEmitter emit:[ARTEvent newWithConnectionEvent:(ARTRealtimeConnectionEvent)state] with:stateChange];

    [stateChangeEventListener startTimer];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)updateWithErrorInfo:(nullable ARTErrorInfo *)errorInfo {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p update requested", self];

    if (self.connection.state_nosync != ARTRealtimeConnected) {
        [self.logger warn:@"R:%p update ignored because connection is not connected", self];
        return;
    }

    ARTConnectionStateChange *stateChange = [[ARTConnectionStateChange alloc] initWithCurrent:self.connection.state_nosync previous:self.connection.state_nosync event:ARTRealtimeConnectionEventUpdate reason:errorInfo retryIn:0];

    ARTEventListener *stateChangeEventListener = [self transitionSideEffects:stateChange];

    [stateChangeEventListener startTimer];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)transitionSideEffects:(ARTConnectionStateChange *)stateChange {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    ARTStatus *status = nil;
    ARTEventListener *stateChangeEventListener = nil;
    // Do not increase the reference count (avoid retain cycles):
    // i.e. the `unlessStateChangesBefore` is setting a timer and if the `ARTRealtime` instance is released before that timer, then it could create a leak.
    __weak __typeof(self) weakSelf = self;

    [self.logger verbose:@"R:%p realtime is transitioning from %@ to %@", self, ARTRealtimeConnectionStateToStr(stateChange.previous), ARTRealtimeConnectionStateToStr(stateChange.current)];

    switch (stateChange.current) {
        case ARTRealtimeConnecting: {
            
            // RTN15g We want to enforce a new connection also when there hasn't been activity for longer than (idle interval + TTL)
            if (stateChange.previous == ARTRealtimeDisconnected || stateChange.previous == ARTRealtimeSuspended) {
                NSTimeInterval intervalSinceLast = [[NSDate date] timeIntervalSinceDate:_lastActivity];
                if (intervalSinceLast > (_maxIdleInterval + _connectionStateTtl)) {
                    [self.connection setId:nil];
                    [self.connection setKey:nil];
                    [self.connection setSerial:0];
                }
            }
            
            stateChangeEventListener = [self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
                [weakSelf onConnectionTimeOut];
            }];
            _connectingTimeoutListener = stateChangeEventListener;

            if (!_reachability) {
                _reachability = [[_reachabilityClass alloc] initWithLogger:self.logger queue:_queue];
            }

            if (!_transport) {
                NSString *resumeKey = nil;
                NSNumber *connectionSerial = nil;
                if (stateChange.previous == ARTRealtimeFailed || stateChange.previous == ARTRealtimeDisconnected || stateChange.previous == ARTRealtimeSuspended) {
                    resumeKey = self.connection.key_nosync;
                    connectionSerial = [NSNumber numberWithLongLong:self.connection.serial_nosync];
                    _resuming = true;
                }
                _transport = [[_transportClass alloc] initWithRest:self.rest options:self.options resumeKey:resumeKey connectionSerial:connectionSerial];
                _transport.delegate = self;
                [self transportConnectForcingNewToken:_renewingToken keepConnection:false];
            }

            if (self.connection.state_nosync != ARTRealtimeFailed && self.connection.state_nosync != ARTRealtimeClosed && self.connection.state_nosync != ARTRealtimeDisconnected) {
                [_reachability listenForHost:[_transport host] callback:^(BOOL reachable) {
                    if (reachable) {
                        switch (weakSelf.connection.state_nosync) {
                            case ARTRealtimeDisconnected:
                            case ARTRealtimeSuspended:
                                [weakSelf transition:ARTRealtimeConnecting];
                            default:
                                break;
                        }
                    } else {
                        switch (weakSelf.connection.state_nosync) {
                            case ARTRealtimeConnecting:
                            case ARTRealtimeConnected: {
                                ARTErrorInfo *unreachable = [ARTErrorInfo createWithCode:-1003 message:@"unreachable host"];
                                [weakSelf transition:ARTRealtimeDisconnected withErrorInfo:unreachable];
                                break;
                            }
                            default:
                                break;
                        }
                    }
                }];
            }
            break;
        }
        case ARTRealtimeClosing: {
            [self stopIdleTimer];
            [_reachability off];
            stateChangeEventListener = [self unlessStateChangesBefore:[ARTDefault realtimeRequestTimeout] do:^{
                [weakSelf transition:ARTRealtimeClosed];
            }];
            [self.transport sendClose];
            break;
        }
        case ARTRealtimeClosed:
            [self stopIdleTimer];
            [_reachability off];
            [self.transport close];
            _connection.key = nil;
            _connection.id = nil;
            _transport = nil;
            self.rest.prioritizedHost = nil;
            [_authorizationEmitter emit:[ARTEvent newWithAuthorizationState:ARTAuthorizationFailed] with:[ARTErrorInfo createWithCode:ARTStateAuthorizationFailed message:@"Connection has been closed"]];
            break;
        case ARTRealtimeFailed:
            status = [ARTStatus state:ARTStateConnectionFailed info:stateChange.reason];
            [self.transport abort:status];
            _transport = nil;
            self.rest.prioritizedHost = nil;
            [_authorizationEmitter emit:[ARTEvent newWithAuthorizationState:ARTAuthorizationFailed] with:stateChange.reason];
            break;
        case ARTRealtimeDisconnected: {
            [_authorizationEmitter emit:[ARTEvent newWithAuthorizationState:ARTAuthorizationCancelled] with:nil];

            if (!_startedReconnection) {
                _startedReconnection = [NSDate date];
                [_internalEventEmitter on:^(ARTConnectionStateChange *change) {
                    if (change.current != ARTRealtimeDisconnected && change.current != ARTRealtimeConnecting) {
                        self->_startedReconnection = nil;
                    }
                }];
            }

            if ([[NSDate date] timeIntervalSinceDate:_startedReconnection] >= _connectionStateTtl) {
                artDispatchScheduled(0, _rest.queue, ^{
                    [self transition:ARTRealtimeSuspended withErrorInfo:stateChange.reason];
                });
                return nil;
            }

            [self.transport close];
            _transport = nil;
            NSTimeInterval retryInterval = self.options.disconnectedRetryTimeout;
            // RTN15a - retry immediately if client was connected
            if (stateChange.previous == ARTRealtimeConnected && !_suspendImmediateReconnection) {
                retryInterval = 0.1;
            }
            [stateChange setRetryIn:retryInterval];
            stateChangeEventListener = [self unlessStateChangesBefore:stateChange.retryIn do:^{
                [weakSelf transition:ARTRealtimeConnecting];
                self->_connectionRetryFromDisconnectedListener = nil;
            }];
            _connectionRetryFromDisconnectedListener = stateChangeEventListener;
            break;
        }
        case ARTRealtimeSuspended: {
            [self.transport close];
            _transport = nil;
            [stateChange setRetryIn:self.options.suspendedRetryTimeout];
            stateChangeEventListener = [self unlessStateChangesBefore:stateChange.retryIn do:^{
                [weakSelf transition:ARTRealtimeConnecting];
                self->_connectionRetryFromSuspendedListener = nil;
            }];
            _connectionRetryFromSuspendedListener = stateChangeEventListener;
            [_authorizationEmitter emit:[ARTEvent newWithAuthorizationState:ARTAuthorizationFailed] with:[ARTErrorInfo createWithCode:ARTStateAuthorizationFailed message:@"Connection has been suspended"]];
            break;
        }
        case ARTRealtimeConnected: {
            _fallbacks = nil;
            if (stateChange.reason) {
                ARTStatus *status = [ARTStatus state:ARTStateError info:[stateChange.reason copy]];
                [self failPendingMessages:status];
            }
            else {
                [self resendPendingMessages];
            }
            [_connectedEventEmitter emit:nil with:nil];
            [_authorizationEmitter emit:[ARTEvent newWithAuthorizationState:ARTAuthorizationSucceeded] with:nil];
            break;
        }
        case ARTRealtimeInitialized:
            break;
    }

    if ([self shouldSendEvents]) {
        [self sendQueuedMessages];
        // For every Channel
        for (ARTRealtimeChannel* channel in self.channels.nosyncIterable) {
            if (channel.state_nosync == ARTRealtimeChannelSuspended) {
                [channel _attach:nil];
            }
        }
    } else if (![self shouldQueueEvents]) {
        ARTStatus *channelStatus = status;
        if (!channelStatus) {
            channelStatus = stateChange.reason ? [ARTStatus state:ARTStateError info:stateChange.reason] : [self defaultError];
        }
        [self failQueuedMessages:channelStatus];
        // For every Channel
        for (ARTRealtimeChannel *channel in self.channels.nosyncIterable) {
            if (stateChange.current == ARTRealtimeClosing) {
                //do nothing. Closed state is coming.
            }
            else if (stateChange.current == ARTRealtimeClosed) {
                [channel detachChannel:[ARTStatus state:ARTStateOk]];
            }
            else if (stateChange.current == ARTRealtimeSuspended) {
                [channel setSuspended:channelStatus];
            }
            else {
                [channel setFailed:channelStatus];
            }
        }
    }

    [self.connection emit:stateChange.event with:stateChange];
    return stateChangeEventListener;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTEventListener *)unlessStateChangesBefore:(NSTimeInterval)deadline do:(void(^)(void))callback __attribute__((warn_unused_result)) {
    return [[_internalEventEmitter once:^(ARTConnectionStateChange *change) {
        // Any state change cancels the timeout.
    }] setTimer:deadline onTimeout:^{
        if (callback) {
            callback();
        }
    }];
}

- (void)onHeartbeat {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self.logger verbose:@"R:%p heartbeat received", self];
    if(self.connection.state_nosync != ARTRealtimeConnected) {
        NSString *msg = [NSString stringWithFormat:@"received a ping when in state %@", ARTRealtimeConnectionStateToStr(self.connection.state_nosync)];
        [self.logger warn:@"R:%p %@", self, msg];
    }
    [_pingEventEmitter emit:nil with:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onConnected:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
   _renewingToken = false;

    // Resuming
    if (_resuming) {
        if (![message.connectionId isEqualToString:self.connection.id_nosync]) {
            [self.logger warn:@"R:%p ARTRealtime: connection has reconnected, but resume failed. Reattaching any attached channels", self];
            // Reattach all channels
            for (ARTRealtimeChannel *channel in self.channels.nosyncIterable) {
                [channel reattachWithReason:message.error callback:nil];
            }
            _resuming = false;
        }
        else if (message.error) {
            [self.logger warn:@"R:%p ARTRealtime: connection has resumed with non-fatal error %@", self, message.error.message];
            // The error will be emitted on `transition`
        }

        [self.logger debug:@"RT:%p connection \"%@\" has reconnected and resumed successfully", self, self.connection.id_nosync];

        for (ARTRealtimeChannel *channel in self.channels.nosyncIterable) {
            if (channel.presenceMap.syncInProgress) {
                // FIXME or not, regarding https://github.com/ably/docs/issues/349
                //[channel requestContinueSync];
            }
        }
    }

    switch (self.connection.state_nosync) {
        case ARTRealtimeConnecting:
            [self.connection setId:message.connectionId];
            [self.connection setKey:message.connectionKey];
            [self.connection setMaxMessageSize:message.connectionDetails.maxMessageSize];
            if (!_resuming) {
                [self.connection setSerial:message.connectionSerial];
                [self.logger debug:@"RT:%p msgSerial of connection \"%@\" has been reset", self, self.connection.id_nosync];
                self.msgSerial = 0;
                self.pendingMessageStartSerial = 0;
            }
            if (message.connectionDetails && message.connectionDetails.connectionStateTtl) {
                _connectionStateTtl = message.connectionDetails.connectionStateTtl;
            }
            if (message.connectionDetails && message.connectionDetails.maxIdleInterval) {
                _maxIdleInterval = message.connectionDetails.maxIdleInterval;
                _lastActivity = [NSDate date];
                [self setIdleTimer];
            }
            [self transition:ARTRealtimeConnected withErrorInfo:message.error];
            break;
        case ARTRealtimeConnected: {
            // Renewing token.
            [self updateWithErrorInfo:message.error];
        }
        default:
            break;
    }

    _resuming = false;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onDisconnected {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self onDisconnected:nil];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onDisconnected:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self.logger info:@"R:%p Realtime disconnected", self];
    ARTErrorInfo *error = message.error;
    if ([self shouldRenewToken:&error]) {
        [self transition:ARTRealtimeDisconnected withErrorInfo:error];
        [self.connection setErrorReason:nil];
        _renewingToken = true;
        [self transition:ARTRealtimeConnecting withErrorInfo:nil];
        return;
    }
    [self transition:ARTRealtimeDisconnected withErrorInfo:error];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onClosed {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self.logger info:@"R:%p Realtime closed", self];
    switch (self.connection.state_nosync) {
        case ARTRealtimeClosed:
            break;
        case ARTRealtimeClosing:
            [self.connection setId:nil];
            [self transition:ARTRealtimeClosed];
            break;
        default:
            NSAssert(false, @"Invalid Realtime state transitioning to Closed: expected Closing or Closed, has %@", ARTRealtimeConnectionStateToStr(self.connection.state_nosync));
            break;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onAuth {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self.logger info:@"R:%p server has requested an authorize", self];
    switch (self.connection.state_nosync) {
        case ARTRealtimeConnecting:
        case ARTRealtimeConnected:
            [self transportConnectForcingNewToken:true keepConnection:true];
            break;
        default:
            [self.logger error:@"Invalid Realtime state: expected Connecting or Connected, has %@", ARTRealtimeConnectionStateToStr(self.connection.state_nosync)];
            break;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onError:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (message.channel) {
        [self onChannelMessage:message];
    } else {
        ARTErrorInfo *error = message.error;
        if (error.code >= 40140 && error.code < 40150) {
            if (![self shouldRenewToken:&error]) {
                [self transition:ARTRealtimeFailed withErrorInfo:message.error];
                return;
            }
            [self transition:ARTRealtimeDisconnected withErrorInfo:message.error];
            return;
        }
        if ([self shouldRenewToken:&error]) {
            [self.transport close];
            [self transportReconnectWithRenewedToken];
            return;
        }
        [self.connection setId:nil];
        [self transition:ARTRealtimeFailed withErrorInfo:message.error];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)cancelTimers {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self.logger verbose:__FILE__ line:__LINE__ message:@"R:%p cancel timers", self];
    [_connectionRetryFromSuspendedListener stopTimer];
    _connectionRetryFromSuspendedListener = nil;
    [_connectionRetryFromDisconnectedListener stopTimer];
    _connectionRetryFromDisconnectedListener = nil;
    // Cancel connecting scheduled work
    [_connectingTimeoutListener stopTimer];
    _connectingTimeoutListener = nil;
    // Cancel auth scheduled work
    artDispatchCancel(_authenitcatingTimeoutWork);
    _authenitcatingTimeoutWork = nil;
    // Idle timer
    [self stopIdleTimer];
    // Ping timer
    [_pingEventEmitter off];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onConnectionTimeOut {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self.logger verbose:__FILE__ line:__LINE__ message:@"R:%p connection timed out", self];
    // Cancel connecting scheduled work
    [_connectingTimeoutListener stopTimer];
    _connectingTimeoutListener = nil;
    // Cancel auth scheduled work
    artDispatchCancel(_authenitcatingTimeoutWork);
    _authenitcatingTimeoutWork = nil;

    ARTErrorInfo *error;
    if (self.auth.authorizing && (self.options.authUrl || self.options.authCallback)) {
        error = [ARTErrorInfo createWithCode:ARTCodeErrorAuthConfiguredProviderFailure status:ARTStateConnectionFailed message:@"timed out"];
    }
    else {
        error = [ARTErrorInfo createWithCode:ARTCodeErrorConnectionTimedOut status:ARTStateConnectionFailed message:@"timed out"];
    }
    switch (self.connection.state_nosync) {
        case ARTRealtimeConnected:
            [self transition:ARTRealtimeConnected withErrorInfo:error];
            break;
        default:
            [self transition:ARTRealtimeDisconnected withErrorInfo:error];
            break;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)shouldRenewToken:(ARTErrorInfo **)errorPtr {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (!_renewingToken && errorPtr && *errorPtr &&
        (*errorPtr).statusCode == 401 && (*errorPtr).code >= 40140 && (*errorPtr).code < 40150) {
        if ([self.auth tokenIsRenewable]) {
            return YES;
        }
        *errorPtr = [ARTErrorInfo createWithCode:ARTStateRequestTokenFailed message:ARTAblyMessageNoMeansToRenewToken];
    }
    return NO;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)transportReconnectWithHost:(NSString *)host {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self.transport setHost:host];
    [self transportConnectForcingNewToken:false keepConnection:false];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)transportReconnectWithRenewedToken {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    _renewingToken = true;
    [self transportConnectForcingNewToken:true keepConnection:false];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)transportConnectForcingNewToken:(BOOL)forceNewToken keepConnection:(BOOL)keepConnection {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    ARTClientOptions *options = [self.options copy];
    if ([options isBasicAuth]) {
        // Basic
        [self.transport connectWithKey:options.key];
    }
    else {
        // Token
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p connecting with token auth; authorising (timeout of %f)", self, [ARTDefault realtimeRequestTimeout]];

        if (!forceNewToken && [self.auth tokenRemainsValid]) {
            // Reuse token
            [self.transport connectWithToken:self.auth.tokenDetails.token];
        }
        else {
            // New Token
            // Transport instance couldn't exist anymore when `authorize` completes or reaches time out.
            __weak __typeof(self) weakSelf = self;

            // Schedule timeout handler
            _authenitcatingTimeoutWork = artDispatchScheduled([ARTDefault realtimeRequestTimeout], _rest.queue, ^{
                [weakSelf onConnectionTimeOut];
                // FIXME: should cancel the auth request as well.
            });

            id<ARTAuthDelegate> delegate = self.auth.delegate;
            if (!keepConnection) {
                // Deactivate use of `ARTAuthDelegate`: `authorize` should complete without waiting for a CONNECTED state.
                self.auth.delegate = nil;
            }
            @try {
                [self.auth _authorize:nil options:options callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
                    // Cancel scheduled work
                    artDispatchCancel(self->_authenitcatingTimeoutWork);
                    self->_authenitcatingTimeoutWork = nil;

                    // It's still valid?
                    switch (weakSelf.connection.state_nosync) {
                        case ARTRealtimeClosing:
                        case ARTRealtimeClosed:
                            return;
                        default:
                            break;
                    }

                    [[weakSelf getLogger] debug:__FILE__ line:__LINE__ message:@"R:%p authorized: %@ error: %@", weakSelf, tokenDetails, error];
                    if (error) {
                        [weakSelf handleTokenAuthError:error];
                        return;
                    }

                    if (forceNewToken && !keepConnection) {
                        [self->_transport close];
                        self->_transport = [[self->_transportClass alloc] initWithRest:self.rest options:self.options resumeKey:self->_transport.resumeKey connectionSerial:self->_transport.connectionSerial];
                        self->_transport.delegate = self;
                    }
                    if (!keepConnection) {
                        [[weakSelf transport] connectWithToken:tokenDetails.token];
                    }
                }];
            }
            @finally {
                self.auth.delegate = delegate;
            }
        }
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)handleTokenAuthError:(NSError *)error {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self.logger error:@"R:%p token auth failed with %@", self, error.description];
    if (error.code == 40102 /*incompatible credentials*/ || error.code == 40300 /*auth fails with a 403 (RSA4d)*/) {
        // RSA15c
        [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createFromNSError:error]];
    }
    else if (self.options.authUrl || self.options.authCallback) {
        ARTErrorInfo *errorInfo = [ARTErrorInfo createWithCode:ARTCodeErrorAuthConfiguredProviderFailure status:ARTStateConnectionFailed message:error.description];
        switch (self.connection.state_nosync) {
            case ARTRealtimeConnected:
                // RSA4c3
                [self.connection setErrorReason:errorInfo];
                break;
            default:
                // RSA4c
                [self transition:ARTRealtimeDisconnected withErrorInfo:errorInfo];
                break;
        }
    }
    else {
        // RSA4b
        [self transition:ARTRealtimeDisconnected withErrorInfo:[ARTErrorInfo createFromNSError:error]];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onAck:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self ack:message];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onNack:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self nack:message];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onChannelMessage:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (message.channel == nil) {
        return;
    }
    ARTRealtimeChannel *channel = [self.channels _getChannel:message.channel options:nil addPrefix:false];
    [channel onChannelMessage:message];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onSuspended {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self transition:ARTRealtimeSuspended];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)shouldSendEvents {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    switch (self.connection.state_nosync) {
        case ARTRealtimeConnected:
            return !_renewingToken;
        default:
            return false;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)shouldQueueEvents {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if(!self.options.queueMessages) {
        return false;
    }
    switch (self.connection.state_nosync) {
        case ARTRealtimeInitialized:
        case ARTRealtimeConnecting:
        case ARTRealtimeDisconnected:
            return true;
        case ARTRealtimeConnected:
            return _renewingToken;
        default:
            return false;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTStatus *)defaultError {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    return [ARTStatus state:ARTStateError];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)isActive {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    return [self shouldQueueEvents] || [self shouldSendEvents];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)sendImpl:(ARTProtocolMessage *)msg sentCallback:(void (^)(ARTErrorInfo *))sentCallback ackCallback:(void (^)(ARTStatus *))ackCallback {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (msg.ackRequired) {
        msg.msgSerial = [NSNumber numberWithLongLong:self.msgSerial];
    }

    NSError *error = nil;
    NSData *data = [self.rest.defaultEncoder encodeProtocolMessage:msg error:&error];

    if (error) {
        ARTErrorInfo *e = [ARTErrorInfo createFromNSError:error];
        if (sentCallback) sentCallback(e);
        if (ackCallback) ackCallback([ARTStatus state:ARTStateError info:e]);
        return;
    }
    else if (!data) {
        ARTErrorInfo *e = [ARTErrorInfo createWithCode:ARTClientCodeErrorInvalidType message:@"Encoder as failed without error."];
        if (sentCallback) sentCallback(e);
        if (ackCallback) ackCallback([ARTStatus state:ARTStateError info:e]);
        return;
    }

    if (msg.ackRequired) {
        self.msgSerial++;
        ARTPendingMessage *pm = [[ARTPendingMessage alloc] initWithProtocolMessage:msg ackCallback:ackCallback];
        [self.pendingMessages addObject:pm];
    }

    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p sending action %tu - %@", self, msg.action, ARTProtocolMessageActionToStr(msg.action)];
    if ([self.transport send:data withSource:msg]) {
        if (sentCallback) sentCallback(nil);
        // `ackCallback()` is called with ACK/NACK action
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)send:(ARTProtocolMessage *)msg sentCallback:(void (^)(ARTErrorInfo *))sentCallback ackCallback:(void (^)(ARTStatus *))ackCallback {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if ([self shouldSendEvents]) {
        [self sendImpl:msg sentCallback:sentCallback ackCallback:ackCallback];
    }
    else if ([self shouldQueueEvents]) {
        BOOL merged = NO;
        for (ARTQueuedMessage *queuedMsg in self.queuedMessages) {
            merged = [queuedMsg mergeFrom:msg sentCallback:nil ackCallback:ackCallback];
            if (merged) {
                break;
            }
        }
        if (!merged) {
            ARTQueuedMessage *qm = [[ARTQueuedMessage alloc] initWithProtocolMessage:msg sentCallback:nil ackCallback:ackCallback];
            [self.queuedMessages addObject:qm];
        }
    }
    else {
        // TODO review error code
        if (ackCallback) {
            ackCallback([ARTStatus state:ARTStateError]);
        }
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)resendPendingMessages {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    NSArray<ARTPendingMessage *> *pms = self.pendingMessages;
    self.pendingMessages = [NSMutableArray array];
    for (ARTPendingMessage *pendingMessage in pms) {
        [self send:pendingMessage.msg sentCallback:nil ackCallback:^(ARTStatus *status) {
            pendingMessage.ackCallback(status);
        }];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)failPendingMessages:(ARTStatus *)status {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    NSArray<ARTPendingMessage *> *pms = self.pendingMessages;
    self.pendingMessages = [NSMutableArray array];
    for (ARTPendingMessage *pendingMessage in pms) {
        pendingMessage.ackCallback(status);
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)sendQueuedMessages {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];

    for (ARTQueuedMessage *message in qms) {
        [self sendImpl:message.msg sentCallback:message.sentCallback ackCallback:message.ackCallback];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)failQueuedMessages:(ARTStatus *)status {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    NSArray *qms = self.queuedMessages;
    self.queuedMessages = [NSMutableArray array];
    for (ARTQueuedMessage *message in qms) {
        message.sentCallback(status.errorInfo);
        message.ackCallback(status);
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)ack:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    int64_t serial = [message.msgSerial longLongValue];
    int count = message.count;
    NSArray *nackMessages = nil;
    NSArray *ackMessages = nil;
    [self.logger verbose:@"R:%p ACK: msgSerial=%lld, count=%d", self, serial, count];
    [self.logger verbose:@"R:%p ACK (before processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self, self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count];

    if (serial < self.pendingMessageStartSerial) {
        // This is an error condition and shouldn't happen but
        // we can handle it gracefully by only processing the
        // relevant portion of the response
        count -= (int)(self.pendingMessageStartSerial - serial);
        serial = self.pendingMessageStartSerial;
    }

    if (serial > self.pendingMessageStartSerial) {
        // This counts as a nack of the messages earlier than serial,
        // as well as an ack
        int nCount = (int)(serial - self.pendingMessageStartSerial);
        NSRange nackRange;
        if (nCount > self.pendingMessages.count) {
            NSString *message = [NSString stringWithFormat:@"R:%p ACK: receiving a serial greater than expected", self];
            [self.logger error:@"%@", message];
            [_rest forceReport:message exception:[NSException exceptionWithName:@"ARTReport" reason:message userInfo:@{}]];
            // Process all the available pending messages as nack
            nackRange = NSMakeRange(0, self.pendingMessages.count);
        }
        else {
            nackRange = NSMakeRange(0, nCount);
        }
        nackMessages = [self.pendingMessages subarrayWithRange:nackRange];
        [self.pendingMessages removeObjectsInRange:nackRange];
        self.pendingMessageStartSerial = serial;
    }

    if (serial == self.pendingMessageStartSerial) {
        NSRange ackRange;
        if (count > self.pendingMessages.count) {
            [self.logger error:@"R:%p ACK: count response is greater than the total of pending messages", self];
            // Process all the available pending messages
            ackRange = NSMakeRange(0, self.pendingMessages.count);
        }
        else {
            ackRange = NSMakeRange(0, count);
        }
        ackMessages = [self.pendingMessages subarrayWithRange:ackRange];
        [self.pendingMessages removeObjectsInRange:ackRange];
        self.pendingMessageStartSerial += count;
    }

    for (ARTPendingMessage *msg in nackMessages) {
        msg.ackCallback([ARTStatus state:ARTStateError info:message.error]);
    }

    for (ARTPendingMessage *msg in ackMessages) {
        msg.ackCallback([ARTStatus state:ARTStateOk]);
    }

    [self.logger verbose:@"R:%p ACK (after processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self, self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)nack:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    int64_t serial = [message.msgSerial longLongValue];
    int count = message.count;
    [self.logger verbose:@"R:%p NACK: msgSerial=%lld, count=%d", self, serial, count];
    [self.logger verbose:@"R:%p NACK (before processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self, self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count];

    if (serial != self.pendingMessageStartSerial) {
        // This is an error condition and it shouldn't happen but
        // we can handle it gracefully by only processing the
        // relevant portion of the response
        count -= (int)(self.pendingMessageStartSerial - serial);
    }

    NSRange nackRange;
    if (count > self.pendingMessages.count) {
        [self.logger error:@"R:%p NACK: count response is greater than the total of pending messages", self];
        // Process all the available pending messages
        nackRange = NSMakeRange(0, self.pendingMessages.count);
    }
    else {
        nackRange = NSMakeRange(0, count);
    }

    NSArray *nackMessages = [self.pendingMessages subarrayWithRange:nackRange];
    [self.pendingMessages removeObjectsInRange:nackRange];
    self.pendingMessageStartSerial += count;

    for (ARTPendingMessage *msg in nackMessages) {
        msg.ackCallback([ARTStatus state:ARTStateError info:message.error]);
    }

    [self.logger verbose:@"R:%p NACK (after processing): pendingMessageStartSerial=%lld, pendingMessages=%lu", self, self.pendingMessageStartSerial, (unsigned long)self.pendingMessages.count];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)reconnectWithFallback {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    NSString *host = [_fallbacks popFallbackHost];
    if (host != nil) {
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p host is down; retrying realtime connection at %@", self, host];
        self.rest.prioritizedHost = host;
        [self transportReconnectWithHost:host];
        return true;
    } else {
        _fallbacks = nil;
        return false;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)shouldRetryWithFallback:(ARTRealtimeTransportError *)error {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (
        (error.type == ARTRealtimeTransportErrorTypeBadResponse && error.badResponseCode >= 500 && error.badResponseCode <= 504) ||
        error.type == ARTRealtimeTransportErrorTypeHostUnreachable ||
        error.type == ARTRealtimeTransportErrorTypeTimeout
    ) {
        return YES;
    }
    return NO;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onActivity {
    [self.logger verbose:__FILE__ line:__LINE__ message:@"R:%p activity", self];
    _lastActivity = [NSDate date];
    [self setIdleTimer];
}

- (void)setIdleTimer {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (self.maxIdleInterval <= 0) {
        [self.logger verbose:@"R:%p set idle timer had been ignored", self];
        return;
    }
    artDispatchCancel(_idleTimer);
    _idleTimer = artDispatchScheduled([ARTDefault realtimeRequestTimeout] + self.maxIdleInterval, _rest.queue, ^{
        [self.logger error:@"R:%p No activity seen from realtime in %f seconds; assuming connection has dropped", self, [[NSDate date] timeIntervalSinceDate:self->_lastActivity]];

        [self transition:ARTRealtimeDisconnected withErrorInfo:[ARTErrorInfo createWithCode:80003 status:408 message:@"Idle timer expired"]];
    });
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)stopIdleTimer {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    artDispatchCancel(_idleTimer);
    _idleTimer = nil;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setTransportClass:(Class)transportClass {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    _transportClass = transportClass;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setReachabilityClass:(Class)reachabilityClass {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    _reachabilityClass = reachabilityClass;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

#pragma mark - ARTRealtimeTransportDelegate implementation

- (void)realtimeTransport:(id)transport didReceiveMessage:(ARTProtocolMessage *)message {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self onActivity];

    if (!message) {
        // Invalid data
        return;
    }

    if (transport != self.transport) {
        // Old connection
        return;
    }

    if (self.connection.state_nosync == ARTRealtimeDisconnected) {
        // Already disconnected
        return;
    }

    [self.logger verbose:@"R:%p did receive Protocol Message %@ (connection state is %@)", self, ARTProtocolMessageActionToStr(message.action), ARTRealtimeConnectionStateToStr(self.connection.state_nosync)];

    if (message.error) {
        [self.logger verbose:@"R:%p Protocol Message with error %@ ", self, message.error];
    }

    NSAssert(transport == self.transport, @"Unexpected transport");
    if (message.hasConnectionSerial) {
        [self.connection setSerial:message.connectionSerial];
    }

    switch (message.action) {
        case ARTProtocolMessageHeartbeat:
            [self onHeartbeat];
            break;
        case ARTProtocolMessageError:
            [self onError:message];
            break;
        case ARTProtocolMessageConnected:
            // Set Auth#clientId
            if (message.connectionDetails) {
                [self.auth setProtocolClientId:message.connectionDetails.clientId];
            }
            // Event
            [self onConnected:message];
            break;
        case ARTProtocolMessageDisconnect:
        case ARTProtocolMessageDisconnected:
            [self onDisconnected:message];
            break;
        case ARTProtocolMessageAck:
            [self onAck:message];
            break;
        case ARTProtocolMessageNack:
            [self onNack:message];
            break;
        case ARTProtocolMessageClosed:
            [self onClosed];
            break;
        case ARTProtocolMessageAuth:
            [self onAuth];
            break;
        default:
            [self onChannelMessage:message];
            break;
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)realtimeTransportAvailable:(id<ARTRealtimeTransport>)transport {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    // Do nothing
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)realtimeTransportUnavailable:(id<ARTRealtimeTransport>)transport {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    [self transition:ARTRealtimeDisconnected];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)realtimeTransportClosed:(id<ARTRealtimeTransport>)transport {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    if (self.connection.state_nosync == ARTRealtimeClosing) {
        // Close succeeded. Nothing more to do.
        [self transition:ARTRealtimeClosed];
    } else if (self.connection.state_nosync != ARTRealtimeClosed && self.connection.state_nosync != ARTRealtimeFailed) {
        // Unexpected closure; recover.
        [self transition:ARTRealtimeDisconnected];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)realtimeTransportDisconnected:(id<ARTRealtimeTransport>)transport withError:(ARTRealtimeTransportError *)error {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    if (self.connection.state_nosync == ARTRealtimeClosing) {
        [self transition:ARTRealtimeClosed];
    } else {
        [self transition:ARTRealtimeDisconnected withErrorInfo:[ARTErrorInfo createFromNSError:error.error]];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)realtimeTransportFailed:(id<ARTRealtimeTransport>)transport withError:(ARTRealtimeTransportError *)error {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p realtime transport failed: %@", self, error];

    if ([self shouldRetryWithFallback:error]) {
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p host is down; can retry with fallback host", self];
        if (!_fallbacks && [error.url.host isEqualToString:[ARTDefault realtimeHost]]) {
            [self.rest internetIsUp:^void(BOOL isUp) {
                self->_fallbacks = [[ARTFallback alloc] initWithOptions:[self getClientOptions]];
                (self->_fallbacks != nil) ? [self reconnectWithFallback] : [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createFromNSError:error.error]];
            }];
            return;
        } else if (_fallbacks && [self reconnectWithFallback]) {
            return;
        }
    }

    switch (error.type) {
        case ARTRealtimeTransportErrorTypeBadResponse:
        case ARTRealtimeTransportErrorTypeOther:
            [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createFromNSError:error.error]];
            break;
        default:
            [self transition:ARTRealtimeDisconnected withErrorInfo:[ARTErrorInfo createFromNSError:error.error]];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)realtimeTransportNeverConnected:(id<ARTRealtimeTransport>)transport {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createWithCode:ARTClientCodeErrorTransport message:@"Transport never connected"]];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)realtimeTransportRefused:(id<ARTRealtimeTransport>)transport withError:(ARTRealtimeTransportError *)error {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    if (error && error.type == ARTRealtimeTransportErrorTypeRefused) {
        [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createWithCode:ARTClientCodeErrorTransport message:[NSString stringWithFormat:@"Connection refused using %@", error.url]]];
    }
    else if (error) {
        [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createFromNSError:error.error]];
    }
    else {
        [self transition:ARTRealtimeFailed];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)realtimeTransportTooBig:(id<ARTRealtimeTransport>)transport {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createWithCode:ARTClientCodeErrorTransport message:@"Transport too big"]];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)realtimeTransportSetMsgSerial:(id<ARTRealtimeTransport>)transport msgSerial:(int64_t)msgSerial {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    self.msgSerial = msgSerial;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onUncaughtException:(NSException *)e {
    if ([e isKindOfClass:[ARTException class]]) {
        @throw e;
    }
    [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createFromNSException:e]];
    [_rest reportUncaughtException:e];
}

#if TARGET_OS_IOS
- (ARTLocalDevice *)device {
    return _rest.device;
}
#endif

@end
