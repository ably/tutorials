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

@protocol ARTConnectionProtocol <NSObject>

@property (nullable, readonly) NSString *id;
@property (nullable, readonly) NSString *key;
@property (nullable, readonly) NSString *recoveryKey;
@property (readonly) int64_t serial;
@property (readonly) NSInteger maxMessageSize;
@property (readonly) ARTRealtimeConnectionState state;
@property (nullable, readonly) ARTErrorInfo *errorReason;

- (void)connect;
- (void)close;
- (void)ping:(void (^)(ARTErrorInfo *_Nullable))cb;

ART_EMBED_INTERFACE_EVENT_EMITTER(ARTRealtimeConnectionEvent, ARTConnectionStateChange *)

@end

@interface ARTConnection: NSObject <ARTConnectionProtocol>

@end

#pragma mark - ARTEvent

@interface ARTEvent (ConnectionEvent)
- (instancetype)initWithConnectionEvent:(ARTRealtimeConnectionEvent)value;
+ (instancetype)newWithConnectionEvent:(ARTRealtimeConnectionEvent)value;
@end

NS_ASSUME_NONNULL_END
