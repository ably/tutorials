//
//  ARTConnection.h
//  ably
//
//  Created by Ricardo Pereira on 30/10/2015.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>

@class ARTRealtime;
@class ARTEventEmitter;

NS_ASSUME_NONNULL_BEGIN

@interface ARTConnection: NSObject

@property (nullable, readonly, strong, nonatomic) NSString *id;
@property (nullable, readonly, strong, nonatomic) NSString *key;
@property (nullable, readonly, getter=getRecoveryKey) NSString *recoveryKey;
@property (readonly, assign, nonatomic) int64_t serial;
@property (readonly, assign, nonatomic) NSInteger maxMessageSize;
@property (readonly, assign, nonatomic) ARTRealtimeConnectionState state;
@property (nullable, readonly, strong, nonatomic) ARTErrorInfo *errorReason;

- (instancetype)initWithRealtime:(ARTRealtime *)realtime;

- (void)connect;
- (void)close;
- (void)ping:(void (^)(ARTErrorInfo *_Nullable))cb;

ART_EMBED_INTERFACE_EVENT_EMITTER(ARTRealtimeConnectionEvent, ARTConnectionStateChange *)

@end

#pragma mark - ARTEvent

@interface ARTEvent (ConnectionEvent)
- (instancetype)initWithConnectionEvent:(ARTRealtimeConnectionEvent)value;
+ (instancetype)newWithConnectionEvent:(ARTRealtimeConnectionEvent)value;
@end

NS_ASSUME_NONNULL_END
