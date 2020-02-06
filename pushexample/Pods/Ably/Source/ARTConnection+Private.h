//
//  ARTConnection+Private.h
//  ably
//
//  Created by Toni Cárdenas on 3/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTConnection.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTTypes.h>
#import "ARTQueuedDealloc.h"

NS_ASSUME_NONNULL_BEGIN

@class ARTRealtimeInternal;

@interface ARTConnectionInternal : NSObject<ARTConnectionProtocol>

@property (nullable, readonly, strong, nonatomic) NSString *id;
@property (nullable, readonly, strong, nonatomic) NSString *key;
@property (nullable, readonly) NSString *recoveryKey;
@property (readonly, assign, nonatomic) int64_t serial;
@property (readonly, assign, nonatomic) NSInteger maxMessageSize;
@property (readonly, assign, nonatomic) ARTRealtimeConnectionState state;
@property (nullable, readonly, strong, nonatomic) ARTErrorInfo *errorReason;

- (instancetype)initWithRealtime:(ARTRealtimeInternal *)realtime;

- (NSString *)id_nosync;
- (NSString *)key_nosync;
- (int64_t)serial_nosync;
- (ARTRealtimeConnectionState)state_nosync;
- (ARTErrorInfo *)errorReason_nosync;
- (NSString *)recoveryKey_nosync;

@property (readonly, strong, nonatomic) ARTEventEmitter<ARTEvent *, ARTConnectionStateChange *> *eventEmitter;
@property(weak, nonatomic) ARTRealtimeInternal* realtime; // weak because realtime owns self

- (void)setId:(NSString *_Nullable)newId;
- (void)setKey:(NSString *_Nullable)key;
- (void)setSerial:(int64_t)serial;
- (void)setMaxMessageSize:(NSInteger)maxMessageSize;
- (void)setState:(ARTRealtimeConnectionState)state;
- (void)setErrorReason:(ARTErrorInfo *_Nullable)errorReason;

- (void)emit:(ARTRealtimeConnectionEvent)event with:(ARTConnectionStateChange *)data;

@property (readonly, nonatomic) dispatch_queue_t queue;

@end

@interface ARTConnection ()

@property (nonatomic, readonly) ARTConnectionInternal *internal;

- (instancetype)initWithInternal:(ARTConnectionInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc;

@property (readonly) ARTConnectionInternal *internal_nosync;

@end

NS_ASSUME_NONNULL_END
