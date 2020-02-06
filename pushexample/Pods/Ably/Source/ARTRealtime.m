
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
#import "ARTWebSocketTransport+Private.h"
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
#import "ARTQueuedDealloc.h"

@interface ARTConnectionStateChange ()

- (void)setRetryIn:(NSTimeInterval)retryIn;

@end

#pragma mark - ARTRealtime implementation

@implementation ARTRealtime {
    ARTQueuedDealloc *_dealloc;
}

- (void)internalAsync:(void (^)(ARTRealtimeInternal * _Nonnull))use {
    dispatch_async(_internal.queue, ^{
        use(self->_internal);
    });
}

- (ARTConnection *)connection {
    return [[ARTConnection alloc] initWithInternal:_internal.connection queuedDealloc:_dealloc];
}

- (ARTRealtimeChannels *)channels {
    return [[ARTRealtimeChannels alloc] initWithInternal:_internal.channels queuedDealloc:_dealloc];
}

- (ARTAuth *)auth {
    return [[ARTAuth alloc] initWithInternal:_internal.auth queuedDealloc:_dealloc];
}

- (ARTPush *)push {
    return [[ARTPush alloc] initWithInternal:_internal.push queuedDealloc:_dealloc];
}

#if TARGET_OS_IOS
- (ARTLocalDevice *)device {
    return _internal.device;
}
#endif

- (NSString *)clientId {
    return _internal.clientId;
}

- (void)initCommon {
    _dealloc = [[ARTQueuedDealloc alloc] init:_internal queue:_internal.queue];
}

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        _internal = [[ARTRealtimeInternal alloc] initWithOptions:options];
        [self initCommon];
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key {
    self = [super init];
    if (self) {
        _internal = [[ARTRealtimeInternal alloc] initWithKey:key];
        [self initCommon];
    }
    return self;
}

- (instancetype)initWithToken:(NSString *)token {
    self = [super init];
    if (self) {
        _internal = [[ARTRealtimeInternal alloc] initWithToken:token];
        [self initCommon];
    }
    return self;
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

- (void)time:(void (^)(NSDate *_Nullable, NSError *_Nullable))cb {
    [_internal time:cb];
}

- (void)ping:(void (^)(ARTErrorInfo *_Nullable))cb {
    [_internal ping:cb];
}

- (BOOL)stats:(void (^)(ARTPaginatedResult<ARTStats *> *_Nullable, ARTErrorInfo *_Nullable))callback {
    return [_internal stats:callback];
}

- (BOOL)stats:(nullable ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult<ARTStats *> *_Nullable, ARTErrorInfo *_Nullable))callback error:(NSError *_Nullable *_Nullable)errorPtr {
    return [_internal stats:query callback:callback error:errorPtr];
}

- (void)connect {
    [_internal connect];
}

- (void)close {
    [_internal close];
}

@end

@implementation ARTRealtimeInternal {
    BOOL _resuming;
    BOOL _renewingToken;
    BOOL _shouldImmediatelyReconnect;
    ARTEventEmitter<ARTEvent *, ARTErrorInfo *> *_pingEventEmitter;
    NSDate *_connectionLostAt;
    NSDate *_lastActivity;
    Class _transportClass;
    Class _reachabilityClass;
    id<ARTRealtimeTransport> _transport;
    ARTFallback *_fallbacks;
    __weak ARTEventListener *_connectionRetryFromSuspendedListener;
    __weak ARTEventListener *_connectionRetryFromDisconnectedListener;
    __weak ARTEventListener *_connectingTimeoutListener;
    ARTScheduledBlockHandle *_authenitcatingTimeoutWork;
    ARTScheduledBlockHandle *_idleTimer;
    dispatch_queue_t _userQueue;
    dispatch_queue_t _queue;
}

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        NSAssert(options, @"ARTRealtime: No options provided");

        _rest = [[ARTRestInternal alloc] initWithOptions:options realtime:self];
        _userQueue = _rest.userQueue;
        _queue = _rest.queue;
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
        _internalEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_rest.queue];
        _connectedEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_rest.queue];
        _pingEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_rest.queue];
        _channels = [[ARTRealtimeChannelsInternal alloc] initWithRealtime:self];
        _transport = nil;
        _transportClass = [ARTWebSocketTransport class];
        _reachabilityClass = [ARTOSReachability class];
        _msgSerial = 0;
        _queuedMessages = [NSMutableArray array];
        _pendingMessages = [NSMutableArray array];
        _pendingMessageStartSerial = 0;
        _pendingAuthorizations = [NSMutableArray array];
        _connection = [[ARTConnectionInternal alloc] initWithRealtime:self];
        _connectionStateTtl = [ARTDefault connectionStateTtl];
        _shouldImmediatelyReconnect = true;
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

#pragma mark - ARTAuthDelegate

- (void)auth:(ARTAuthInternal *)auth didAuthorize:(ARTTokenDetails *)tokenDetails completion:(void (^)(ARTAuthorizationState, ARTErrorInfo *_Nullable))completion {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    void (^waitForResponse)(void) = ^{
        [self.pendingAuthorizations enqueue:^(ARTRealtimeConnectionState state, ARTErrorInfo *_Nullable error){
            switch (state) {
                case ARTRealtimeConnected:
                    completion(ARTAuthorizationSucceeded, nil);
                    break;
                case ARTRealtimeFailed:
                    completion(ARTAuthorizationFailed, error);
                    break;
                case ARTRealtimeSuspended:
                    completion(ARTAuthorizationFailed, [ARTErrorInfo createWithCode:ARTStateAuthorizationFailed message:@"Connection has been suspended"]);
                    break;
                case ARTRealtimeClosed:
                    completion(ARTAuthorizationFailed, [ARTErrorInfo createWithCode:ARTStateAuthorizationFailed message:@"Connection has been closed"]);
                    break;
                case ARTRealtimeDisconnected:
                    completion(ARTAuthorizationCancelled, nil);
                    break;
                case ARTRealtimeInitialized:
                case ARTRealtimeConnecting:
                case ARTRealtimeClosing:
                    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p authorize completion has been ignored because the connection state is unexpected (%@)", self.rest, ARTRealtimeConnectionStateToStr(state)];
                    break;
            }
        }];
    };

    void (^haltCurrentConnectionAndReconnect)(void) = ^{
        // Halt the current connection and reconnect with the most recent token
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p halt current connection and reconnect with %@", self.rest, tokenDetails];
        [self abortAndReleaseTransport:[ARTStatus state:ARTStateOk]];
        [self setTransportWithResumeKey:self->_transport.resumeKey connectionSerial:self->_transport.connectionSerial];
        [self->_transport connectWithToken:tokenDetails.token];
        [self cancelAllPendingAuthorizations];
        waitForResponse();
    };

    switch (self.connection.state_nosync) {
        case ARTRealtimeConnected: {
            // Update (send AUTH message)
            [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p AUTH message using %@", self.rest, tokenDetails];
            ARTProtocolMessage *msg = [[ARTProtocolMessage alloc] init];
            msg.action = ARTProtocolMessageAuth;
            msg.auth = [[ARTAuthDetails alloc] initWithToken:tokenDetails.token];
            [self send:msg sentCallback:nil ackCallback:nil];
            waitForResponse();
            break;
        }
        case ARTRealtimeConnecting: {
            [_transport.stateEmitter once:[ARTEvent newWithTransportState:ARTRealtimeTransportStateOpened] callback:^(id sender) {
                haltCurrentConnectionAndReconnect();
            }];
            break;
        }
        case ARTRealtimeClosing: {
            // Should ignore because the connection is being closed
            [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p authorize has been cancelled because the connection is closing", self.rest];
            [self cancelAllPendingAuthorizations];
            break;
        }
        default: {
            // Client state is NOT Connecting or Connected, so it should start a new connection
            [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p new connection from successfull authorize %@", self.rest, tokenDetails];
            [self transition:ARTRealtimeConnecting];
            waitForResponse();
            break;
        }
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)performPendingAuthorizationWithState:(ARTRealtimeConnectionState)state error:(nullable ARTErrorInfo *)error {
    void (^pendingAuthorization)(ARTRealtimeConnectionState, ARTErrorInfo *_Nullable) = [self.pendingAuthorizations dequeue];
    if (!pendingAuthorization) {
        return;
    }
    switch (state) {
        case ARTRealtimeConnected:
            pendingAuthorization(state, nil);
            break;
        case ARTRealtimeFailed:
            pendingAuthorization(state, error);
            break;
        default:
            [self discardPendingAuthorizations];
            pendingAuthorization(state, error);
            break;
    }
}

- (void)cancelAllPendingAuthorizations {
    [self.pendingAuthorizations enumerateObjectsUsingBlock:^(void (^pendingAuthorization)(ARTRealtimeConnectionState, ARTErrorInfo * _Nullable), NSUInteger idx, BOOL * _Nonnull stop) {
        pendingAuthorization(ARTRealtimeDisconnected, nil);
    }];
    [self.pendingAuthorizations removeAllObjects];
}

- (void)discardPendingAuthorizations {
    [self.pendingAuthorizations removeAllObjects];
}

#pragma mark - Realtime

- (instancetype)initWithKey:(NSString *)key {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithKey:key]];
}

- (instancetype)initWithToken:(NSString *)token {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithToken:token]];
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

- (NSString *)clientId {
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

- (ARTAuthInternal *)auth {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    return self.rest.auth;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (ARTPushInternal *)push {
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
    [self.logger verbose:__FILE__ line:__LINE__ message:@"R:%p realtime state transitions to %tu - %@", self, state, ARTRealtimeConnectionStateToStr(state)];

    ARTConnectionStateChange *stateChange = [[ARTConnectionStateChange alloc] initWithCurrent:state previous:self.connection.state_nosync event:(ARTRealtimeConnectionEvent)state reason:errorInfo retryIn:0];
    [self.connection setState:state];
    [self.connection setErrorReason:errorInfo];

    ARTEventListener *stateChangeEventListener = [self transitionSideEffects:stateChange];

    [_internalEventEmitter emit:[ARTEvent newWithConnectionEvent:(ARTRealtimeConnectionEvent)state] with:stateChange];

    [stateChangeEventListener startTimer];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)transitionToDisconnectedOrSuspended {
    [self transitionToDisconnectedOrSuspendedWithError:nil];
}

- (void)transitionToDisconnectedOrSuspendedWithError:(nullable ARTErrorInfo *)errorInfo {
    if ([self isSuspendMode]) {
        [self transition:ARTRealtimeSuspended withErrorInfo:errorInfo];
    }
    else {
        [self transition:ARTRealtimeDisconnected withErrorInfo:errorInfo];
    }
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

    [self.logger debug:@"R:%p realtime is transitioning from %tu - %@ to %tu - %@", self, stateChange.previous, ARTRealtimeConnectionStateToStr(stateChange.previous), stateChange.current, ARTRealtimeConnectionStateToStr(stateChange.current)];

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
                [self onConnectionTimeOut];
            }];
            _connectingTimeoutListener = stateChangeEventListener;

            if (!_reachability) {
                _reachability = [[_reachabilityClass alloc] initWithLogger:self.logger queue:_queue];
            }

            if (!_transport) {
                NSString *resumeKey = nil;
                NSNumber *connectionSerial = nil;
                if (stateChange.previous == ARTRealtimeFailed ||
                    stateChange.previous == ARTRealtimeDisconnected ||
                    stateChange.previous == ARTRealtimeSuspended) {
                    resumeKey = self.connection.key_nosync;
                    connectionSerial = [NSNumber numberWithLongLong:self.connection.serial_nosync];
                    _resuming = true;
                }
                [self setTransportWithResumeKey:resumeKey connectionSerial:connectionSerial];
                [self transportConnectForcingNewToken:_renewingToken newConnection:true];
            }

            if (self.connection.state_nosync != ARTRealtimeFailed &&
                self.connection.state_nosync != ARTRealtimeClosed &&
                self.connection.state_nosync != ARTRealtimeDisconnected) {
                [_reachability listenForHost:[_transport host] callback:^(BOOL reachable) {
                    // The ref cycle creating by taking self here is resolved on close
                    // when [_reachability off] is called.
                    if (reachable) {
                        switch (self.connection.state_nosync) {
                            case ARTRealtimeDisconnected:
                            case ARTRealtimeSuspended:
                                [self transition:ARTRealtimeConnecting];
                            default:
                                break;
                        }
                    } else {
                        switch (self.connection.state_nosync) {
                            case ARTRealtimeConnecting:
                            case ARTRealtimeConnected: {
                                ARTErrorInfo *unreachable = [ARTErrorInfo createWithCode:-1003 message:@"unreachable host"];
                                [self transitionToDisconnectedOrSuspendedWithError:unreachable];
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
                [self transition:ARTRealtimeClosed];
            }];
            [self.transport sendClose];
            break;
        }
        case ARTRealtimeClosed:
            [self stopIdleTimer];
            [_reachability off];
            [self closeAndReleaseTransport];
            _connection.key = nil;
            _connection.id = nil;
            _transport = nil;
            self.rest.prioritizedHost = nil;
            [self.auth cancelAuthorization:nil];
            break;
        case ARTRealtimeFailed:
            status = [ARTStatus state:ARTStateConnectionFailed info:stateChange.reason];
            [self abortAndReleaseTransport:status];
            self.rest.prioritizedHost = nil;
            [self.auth cancelAuthorization:stateChange.reason];
            break;
        case ARTRealtimeDisconnected: {
            [self closeAndReleaseTransport];
            if (!_connectionLostAt) {
                _connectionLostAt = [NSDate date];
                [self.logger verbose:@"RT:%p set connection lost time; expected suspension at %@ (ttl=%f)", self, [self suspensionTime], self.connectionStateTtl];
            }
            NSTimeInterval retryInterval = self.options.disconnectedRetryTimeout;
            // RTN15a - retry immediately if client was connected
            if (stateChange.previous == ARTRealtimeConnected && _shouldImmediatelyReconnect) {
                retryInterval = 0.1;
            }
            [stateChange setRetryIn:retryInterval];
            stateChangeEventListener = [self unlessStateChangesBefore:stateChange.retryIn do:^{
                self->_connectionRetryFromDisconnectedListener = nil;
                [self transition:ARTRealtimeConnecting];
            }];
            _connectionRetryFromDisconnectedListener = stateChangeEventListener;
            break;
        }
        case ARTRealtimeSuspended: {
            [_connectionRetryFromDisconnectedListener stopTimer];
            _connectionRetryFromDisconnectedListener = nil;
            [self.auth cancelAuthorization:nil];
            [self closeAndReleaseTransport];
            [stateChange setRetryIn:self.options.suspendedRetryTimeout];
            stateChangeEventListener = [self unlessStateChangesBefore:stateChange.retryIn do:^{
                self->_connectionRetryFromSuspendedListener = nil;
                [self transition:ARTRealtimeConnecting];
            }];
            _connectionRetryFromSuspendedListener = stateChangeEventListener;
            break;
        }
        case ARTRealtimeConnected: {
            _fallbacks = nil;
            _connectionLostAt = nil;
            if (stateChange.reason) {
                ARTStatus *status = [ARTStatus state:ARTStateError info:[stateChange.reason copy]];
                [self failPendingMessages:status];
            }
            else {
                [self resendPendingMessages];
            }
            [_connectedEventEmitter emit:nil with:nil];
            break;
        }
        case ARTRealtimeInitialized:
            break;
    }

    if ([self shouldSendEvents]) {
        [self sendQueuedMessages];
        // For every Channel
        for (ARTRealtimeChannelInternal *channel in self.channels.nosyncIterable) {
            [channel sendQueuedMessages];
        }
    } else if (![self shouldQueueEvents]) {
        ARTStatus *channelStatus = status;
        if (!channelStatus) {
            channelStatus = stateChange.reason ? [ARTStatus state:ARTStateError info:stateChange.reason] : [self defaultError];
        }
        [self failQueuedMessages:channelStatus];
        
        // If there's a channels.release() going on waiting on this channel
        // to detach, doing those operations on it here would fire its event listener and
        // immediately remove the channel from the channels dictionary, thus
        // invalidating the iterator and causing a crashing.
        //
        // So copy the channels and operate on them later, when we're done using the iterator.
        NSMutableArray<ARTRealtimeChannelInternal *> * const channels = [[NSMutableArray alloc] init];
        for (ARTRealtimeChannelInternal *channel in self.channels.nosyncIterable) {
            [channels addObject:channel];
        }
        
        for (ARTRealtimeChannelInternal *channel in channels) {
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

    [self performPendingAuthorizationWithState:stateChange.current error:stateChange.reason];

    return stateChangeEventListener;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)abortAndReleaseTransport:(ARTStatus *)status {
    [_transport abort:status];
    _transport = nil;
}

- (void)closeAndReleaseTransport {
    if (_transport) {
        [_transport close];
        _transport = nil;
    }
}

- (void)resetTransportWithResumeKey:(NSString *)resumeKey connectionSerial:(NSNumber *)connectionSerial {
    [self closeAndReleaseTransport];
    [self setTransportWithResumeKey:resumeKey connectionSerial:connectionSerial];
}

- (void)setTransportWithResumeKey:(NSString *)resumeKey connectionSerial:(NSNumber *)connectionSerial {
    _transport = [[_transportClass alloc] initWithRest:self.rest options:self.options resumeKey:resumeKey connectionSerial:connectionSerial];
    _transport.delegate = self;
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
            [self.logger warn:@"RT:%p connection \"%@\" has reconnected, but resume failed. Reattaching any attached channels", self, message.connectionId];
            // Reattach all channels
            for (ARTRealtimeChannelInternal *channel in self.channels.nosyncIterable) {
                [channel reattachWithReason:message.error callback:nil];
            }
            _resuming = false;
        }
        else if (message.error) {
            [self.logger warn:@"RT:%p connection \"%@\" has resumed with non-fatal error %@", self, message.connectionId, message.error.message];
            // The error will be emitted on `transition`
        }
        else {
            [self.logger debug:@"RT:%p connection \"%@\" has reconnected and resumed successfully", self, message.connectionId];
        }

        for (ARTRealtimeChannelInternal *channel in self.channels.nosyncIterable) {
            if (channel.presenceMap.syncInProgress) {
                // FIXME or not, regarding https://github.com/ably/docs/issues/349
                //[channel requestContinueSync];
            }
        }
    }

    switch (self.connection.state_nosync) {
        case ARTRealtimeConnecting: {
            // If there's no previous connectionId, then don't reset the msgSerial
            //as it may have been set by recover data (unless the recover failed).
            NSString *prevConnId = self.connection.id_nosync;
            BOOL connIdChanged = prevConnId && ![message.connectionId isEqualToString:prevConnId];
            BOOL recoverFailure = !prevConnId && message.error;
            if (connIdChanged || recoverFailure) {
                [self.logger debug:@"RT:%p msgSerial of connection \"%@\" has been reset", self, self.connection.id_nosync];
                self.msgSerial = 0;
                self.pendingMessageStartSerial = 0;
            }

            [self.connection setId:message.connectionId];
            [self.connection setKey:message.connectionKey];
            [self.connection setMaxMessageSize:message.connectionDetails.maxMessageSize];
            [self.connection setSerial:message.connectionSerial];

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
        }
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
        [self transitionToDisconnectedOrSuspendedWithError:error];
        [self.connection setErrorReason:nil];
        _renewingToken = true;
        [self transition:ARTRealtimeConnecting withErrorInfo:nil];
    }
    else {
        [self transitionToDisconnectedOrSuspendedWithError:error];
    }
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
            [self transportConnectForcingNewToken:true newConnection:false];
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
            [self transitionToDisconnectedOrSuspendedWithError:message.error];
            return;
        }
        if ([self shouldRenewToken:&error]) {
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
    if (self.auth.authorizing_nosync && (self.options.authUrl || self.options.authCallback)) {
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
            [self transitionToDisconnectedOrSuspendedWithError:error];
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
    [self resetTransportWithResumeKey:_transport.resumeKey connectionSerial:_transport.connectionSerial];
    [self.transport setHost:host];
    [self transportConnectForcingNewToken:false newConnection:true];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)transportReconnectWithRenewedToken {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    _renewingToken = true;
    [self resetTransportWithResumeKey:_transport.resumeKey connectionSerial:_transport.connectionSerial];
    [self transportConnectForcingNewToken:true newConnection:true];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)transportConnectForcingNewToken:(BOOL)forceNewToken newConnection:(BOOL)newConnection {
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
            [self.auth setTokenDetails:nil];

            // Schedule timeout handler
            _authenitcatingTimeoutWork = artDispatchScheduled([ARTDefault realtimeRequestTimeout], _rest.queue, ^{
                [self onConnectionTimeOut];
            });

            id<ARTAuthDelegate> delegate = self.auth.delegate;
            if (newConnection) {
                // Deactivate use of `ARTAuthDelegate`: `authorize` should complete without waiting for a CONNECTED state.
                self.auth.delegate = nil;
            }
            @try {
                [self.auth _authorize:nil options:options callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
                    // Cancel scheduled work
                    artDispatchCancel(self->_authenitcatingTimeoutWork);
                    self->_authenitcatingTimeoutWork = nil;

                    // It's still valid?
                    switch (self.connection.state_nosync) {
                        case ARTRealtimeClosing:
                        case ARTRealtimeClosed:
                            return;
                        default:
                            break;
                    }

                    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p authorized: %@ error: %@", self, tokenDetails, error];
                    if (error) {
                        [self handleTokenAuthError:error];
                        return;
                    }

                    if (forceNewToken && newConnection) {
                        [self resetTransportWithResumeKey:self->_transport.resumeKey connectionSerial:self->_transport.connectionSerial];
                    }
                    if (newConnection) {
                        [self.transport connectWithToken:tokenDetails.token];
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
                [self transitionToDisconnectedOrSuspendedWithError:errorInfo];
                break;
        }
    }
    else {
        // RSA4b
        [self transitionToDisconnectedOrSuspendedWithError:[ARTErrorInfo createFromNSError:error]];
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
    ARTRealtimeChannelInternal *channel = [self.channels _getChannel:message.channel options:nil addPrefix:false];
    [channel onChannelMessage:message];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)onSuspended {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    [self transition:ARTRealtimeSuspended];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSDate *)suspensionTime {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    return [_connectionLostAt dateByAddingTimeInterval:self.connectionStateTtl];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (BOOL)isSuspendMode {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    NSDate *currentTime = [NSDate date];
    return [currentTime timeIntervalSinceDate:[self suspensionTime]] > 0;
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
        [self.rest internetIsUp:^void(BOOL isUp) {
            if (!isUp) {
                [self transition:ARTRealtimeDisconnected withErrorInfo:[ARTErrorInfo createWithCode:0 message:@"no Internet connection"]];
                return;
            }

            [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p host is down; retrying realtime connection at %@", self, host];
            self.rest.prioritizedHost = host;
            [self transportReconnectWithHost:host];
        }];
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

        ARTErrorInfo *idleTimerExpired = [ARTErrorInfo createWithCode:80003 status:408 message:@"Idle timer expired"];
        [self transitionToDisconnectedOrSuspendedWithError:idleTimerExpired];
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
        [self.logger verbose:@"R:%p Protocol Message with error %@", self, message.error];
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
        [self transitionToDisconnectedOrSuspended];
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
        [self transitionToDisconnectedOrSuspendedWithError:[ARTErrorInfo createFromNSError:error.error]];
    }
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)realtimeTransportFailed:(id<ARTRealtimeTransport>)transport withError:(ARTRealtimeTransportError *)transportError {
ART_TRY_OR_MOVE_TO_FAILED_START(self) {
    if (transport != self.transport) {
        // Old connection
        return;
    }

    [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p realtime transport failed: %@", self, transportError];

    if ([self shouldRetryWithFallback:transportError]) {
        [self.logger debug:__FILE__ line:__LINE__ message:@"R:%p host is down; can retry with fallback host", self];
        if (!_fallbacks && [transportError.url.host isEqualToString:[ARTDefault realtimeHost]]) {
            self->_fallbacks = [[ARTFallback alloc] initWithOptions:[self getClientOptions]];
            if (self->_fallbacks != nil) {
                [self reconnectWithFallback];
            } else {
                [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createFromNSError:transportError.error]];
            }
            return;
        } else if (_fallbacks && [self reconnectWithFallback]) {
            return;
        }
    }

    switch (transportError.type) {
        case ARTRealtimeTransportErrorTypeBadResponse:
        case ARTRealtimeTransportErrorTypeOther:
            [self transition:ARTRealtimeFailed withErrorInfo:[ARTErrorInfo createFromNSError:transportError.error]];
            break;
        default: {
            ARTErrorInfo *error = [ARTErrorInfo createFromNSError:transportError.error];
            [self transitionToDisconnectedOrSuspendedWithError:error];
        }
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
