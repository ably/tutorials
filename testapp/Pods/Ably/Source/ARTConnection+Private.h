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

NS_ASSUME_NONNULL_BEGIN

@interface ARTConnection ()

- (NSString *)id_nosync;
- (NSString *)key_nosync;
- (int64_t)serial_nosync;
- (ARTRealtimeConnectionState)state_nosync;
- (ARTErrorInfo *)errorReason_nosync;
- (NSString *)recoveryKey_nosync;

@property (readonly, strong, nonatomic) ARTEventEmitter<ARTEvent *, ARTConnectionStateChange *> *eventEmitter;
@property(weak, nonatomic) ARTRealtime* realtime;

@end

@interface ARTConnection (Private)

- (void)setId:(NSString *_Nullable)newId;
- (void)setKey:(NSString *_Nullable)key;
- (void)setSerial:(int64_t)serial;
- (void)setMaxMessageSize:(NSInteger)maxMessageSize;
- (void)setState:(ARTRealtimeConnectionState)state;
- (void)setErrorReason:(ARTErrorInfo *_Nullable)errorReason;

- (void)emit:(ARTRealtimeConnectionEvent)event with:(ARTConnectionStateChange *)data;

@end

NS_ASSUME_NONNULL_END
