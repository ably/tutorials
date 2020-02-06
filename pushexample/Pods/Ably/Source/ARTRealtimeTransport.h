//
//  ARTRealtimeTransport.h
//  ably-ios
//
//  Created by Jason Choy on 10/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTLog.h>

@protocol ARTRealtimeTransport;

@class ARTProtocolMessage;
@class ARTStatus;
@class ARTErrorInfo;
@class ARTClientOptions;
@class ARTRestInternal;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ARTRealtimeTransportErrorType) {
    ARTRealtimeTransportErrorTypeOther,
    ARTRealtimeTransportErrorTypeHostUnreachable,
    ARTRealtimeTransportErrorTypeNoInternet,
    ARTRealtimeTransportErrorTypeTimeout,
    ARTRealtimeTransportErrorTypeBadResponse,
    ARTRealtimeTransportErrorTypeRefused
};

typedef NS_ENUM(NSUInteger, ARTRealtimeTransportState) {
    ARTRealtimeTransportStateOpening,
    ARTRealtimeTransportStateOpened,
    ARTRealtimeTransportStateClosing,
    ARTRealtimeTransportStateClosed,
};

@interface ARTRealtimeTransportError : NSObject

@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) ARTRealtimeTransportErrorType type;
@property (nonatomic, assign) NSInteger badResponseCode;
@property (nonatomic, strong) NSURL *url;

- (instancetype)initWithError:(NSError *)error type:(ARTRealtimeTransportErrorType)type url:(NSURL *)url;
- (instancetype)initWithError:(NSError *)error badResponseCode:(NSInteger)badResponseCode url:(NSURL *)url;

- (NSString *)description;

@end

@protocol ARTRealtimeTransportDelegate

// All methods must be called from rest's serial queue.

- (void)realtimeTransport:(id<ARTRealtimeTransport>)transport didReceiveMessage:(ARTProtocolMessage *)message;

- (void)realtimeTransportAvailable:(id<ARTRealtimeTransport>)transport;

- (void)realtimeTransportClosed:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportDisconnected:(id<ARTRealtimeTransport>)transport withError:(nullable ARTRealtimeTransportError *)error;
- (void)realtimeTransportNeverConnected:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportRefused:(id<ARTRealtimeTransport>)transport withError:(nullable ARTRealtimeTransportError *)error;
- (void)realtimeTransportTooBig:(id<ARTRealtimeTransport>)transport;
- (void)realtimeTransportFailed:(id<ARTRealtimeTransport>)transport withError:(ARTRealtimeTransportError *)error;

- (void)realtimeTransportSetMsgSerial:(id<ARTRealtimeTransport>)transport msgSerial:(int64_t)msgSerial;

@end

@protocol ARTRealtimeTransport

// All methods must be called from rest's serial queue.

- (instancetype)initWithRest:(ARTRestInternal *)rest options:(ARTClientOptions *)options resumeKey:(nullable NSString *)resumeKey connectionSerial:(nullable NSNumber *)connectionSerial;

@property (readonly, strong, nonatomic) NSString *resumeKey;
@property (readonly, strong, nonatomic) NSNumber *connectionSerial;
@property (readonly, assign, nonatomic) ARTRealtimeTransportState state;
@property (nullable, readwrite, strong, nonatomic) id<ARTRealtimeTransportDelegate> delegate;
@property (readonly, strong, nonatomic) ARTLog *protocolMessagesLogger;
@property (nonatomic, readonly) ARTEventEmitter<ARTEvent *, id> *stateEmitter;

- (BOOL)send:(NSData *)data withSource:(nullable id)decodedObject;
- (void)receive:(ARTProtocolMessage *)msg;
- (nullable ARTProtocolMessage *)receiveWithData:(NSData *)data;
- (void)connectWithKey:(NSString *)key;
- (void)connectWithToken:(NSString *)token;
- (void)sendClose;
- (void)sendPing;
- (void)close;
- (void)abort:(ARTStatus *)reason;
- (NSString *)host;
- (void)setHost:(NSString *)host;
- (ARTRealtimeTransportState)state;

@end

NS_ASSUME_NONNULL_END
