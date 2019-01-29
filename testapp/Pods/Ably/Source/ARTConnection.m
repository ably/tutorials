//
//  ARTConnection.m
//  ably
//
//  Created by Ricardo Pereira on 30/10/2015.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTConnection+Private.h"

#import "ARTRealtime+Private.h"
#import "ARTEventEmitter+Private.h"
#import "ARTSentry.h"

@interface ARTConnection ()

@end

@implementation ARTConnection {
    _Nonnull dispatch_queue_t _queue;
    NSString *_id;
    NSString *_key;
    NSInteger _maxMessageSize;
    int64_t _serial;
    ARTRealtimeConnectionState _state;
    ARTErrorInfo *_errorReason;
}

- (instancetype)initWithRealtime:(ARTRealtime *)realtime {
ART_TRY_OR_MOVE_TO_FAILED_START(realtime) {
    if (self = [super init]) {
        _eventEmitter = [[ARTPublicEventEmitter alloc] initWithRest:realtime.rest];
        _realtime = realtime;
        _queue = _realtime.rest.queue;
        _serial = -1;
    }
    return self;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)connect {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_realtime connect];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)close {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_realtime close];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)ping:(void (^)(ARTErrorInfo *))cb {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    [_realtime ping:cb];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSString *)id {
    __block NSString *ret;   
dispatch_sync(_queue, ^{
    ret = [self id_nosync];
});
    return ret;
} 

- (NSString *)key {
    __block NSString *ret;   
dispatch_sync(_queue, ^{
    ret = [self key_nosync];
});
    return ret;
} 

- (int64_t)serial {
    __block int64_t ret;   
dispatch_sync(_queue, ^{
    ret = [self serial_nosync];
});
    return ret;
} 

- (ARTRealtimeConnectionState)state {
    __block ARTRealtimeConnectionState ret;   
dispatch_sync(_queue, ^{
    ret = [self state_nosync];
});
    return ret;
}

- (ARTErrorInfo *)errorReason {
    __block ARTErrorInfo *ret;   
dispatch_sync(_queue, ^{
    ret = [self errorReason_nosync];
});
    return ret;
}

- (NSString *)id_nosync {
    return _id;
} 

- (NSString *)key_nosync {
    return _key;
} 

- (int64_t)serial_nosync {
    return _serial;
} 

- (ARTRealtimeConnectionState)state_nosync {
    return _state;
}

- (ARTErrorInfo *)errorReason_nosync {
    return _errorReason;
}

- (void)setId:(NSString *)newId {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _id = newId;
    [ARTSentry setExtras:@"connectionId" value:newId];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setKey:(NSString *)key {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _key = key;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setSerial:(int64_t)serial {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _serial = serial;
    [ARTSentry setExtras:@"connectionSerial" value: [NSNumber numberWithLongLong:serial]];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setMaxMessageSize:(NSInteger)maxMessageSize {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _maxMessageSize = maxMessageSize;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setState:(ARTRealtimeConnectionState)state {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _state = state;
    [ARTSentry setExtras:@"connectionState" value:ARTRealtimeConnectionStateToStr(state)];
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (void)setErrorReason:(ARTErrorInfo *_Nullable)errorReason {
ART_TRY_OR_MOVE_TO_FAILED_START(_realtime) {
    _errorReason = errorReason;
} ART_TRY_OR_MOVE_TO_FAILED_END
}

- (NSString *)getRecoveryKey {
    __block NSString *ret;
dispatch_sync(_queue, ^{
ART_TRY_OR_MOVE_TO_FAILED_START(self->_realtime) {
    ret = [self recoveryKey_nosync];
} ART_TRY_OR_MOVE_TO_FAILED_END
});
    return ret;
}

- (NSString *)recoveryKey_nosync {
    switch(self.state_nosync) {
        case ARTRealtimeConnecting:
        case ARTRealtimeConnected:
        case ARTRealtimeDisconnected:
        case ARTRealtimeSuspended: {
            NSString *recStr = self.key_nosync;
            if (recStr == nil) {
                return nil;
            }
            NSString *str = [recStr stringByAppendingString:[NSString stringWithFormat:@":%ld:%ld", (long)self.serial_nosync, (long)_realtime.msgSerial]];
            return str;
        } default:
            return nil;
    }
}

- (ARTEventListener *)on:(ARTRealtimeConnectionEvent)event callback:(void (^)(ARTConnectionStateChange *))cb {
    return [_eventEmitter on:[ARTEvent newWithConnectionEvent:event] callback:cb];
}

- (ARTEventListener *)on:(void (^)(ARTConnectionStateChange *))cb {
    return [_eventEmitter on:cb];
}

- (ARTEventListener *)once:(ARTRealtimeConnectionEvent)event callback:(void (^)(ARTConnectionStateChange *))cb {
    return [_eventEmitter once:[ARTEvent newWithConnectionEvent:event] callback:cb];
}

- (ARTEventListener *)once:(void (^)(ARTConnectionStateChange *))cb {
    return [_eventEmitter once:cb];
}

- (void)off {
    if (_realtime && _realtime.rest) {
        [_eventEmitter off];
    } else {
        [_eventEmitter off];
    }
}
- (void)off:(ARTRealtimeConnectionEvent)event listener:(ARTEventListener *)listener {
    [_eventEmitter off:[ARTEvent newWithConnectionEvent:event] listener:listener];
}

- (void)off:(ARTEventListener *)listener {
    [_eventEmitter off:listener];
}

- (void)emit:(ARTRealtimeConnectionEvent)event with:(ARTConnectionStateChange *)data {
    [_eventEmitter emit:[ARTEvent newWithConnectionEvent:event] with:data];
}

@end

#pragma mark - ARTEvent

@implementation ARTEvent (ConnectionEvent)

- (instancetype)initWithConnectionEvent:(ARTRealtimeConnectionEvent)value {
    return [self initWithString:[NSString stringWithFormat:@"ARTRealtimeConnectionEvent%@", ARTRealtimeConnectionEventToStr(value)]];
}

+ (instancetype)newWithConnectionEvent:(ARTRealtimeConnectionEvent)value {
    return [[self alloc] initWithConnectionEvent:value];
}

@end
