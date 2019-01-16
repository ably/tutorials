//
//  ARTEncoder.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CompatibilityMacros.h"
#import "ARTTypes.h"

@class ARTMessage;
@class ARTPresenceMessage;
@class ARTProtocolMessage;
@class ARTTokenDetails;
@class ARTTokenRequest;
@class ARTDeviceDetails;
@class ARTDeviceIdentityTokenDetails;
@class ARTDevicePushDetails;
@class ARTPushChannelSubscription;

@protocol ARTPushRecipient;

typedef NS_ENUM(NSUInteger, ARTEncoderFormat) {
    ARTEncoderFormatJson,
    ARTEncoderFormatMsgPack
};

NS_ASSUME_NONNULL_BEGIN

@protocol ARTEncoder

- (NSString *)mimeType;
- (ARTEncoderFormat)format;
- (NSString *)formatAsString;

- (nullable id)decode:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (nullable NSData *)encode:(id)obj error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(encode(any:error:));

/// Decode data to an Array of Dictionaries with AnyObjects.
///  - One use case could be when the response is an array of JSON Objects.
- (nullable NSArray<NSDictionary *> *)decodeToArray:(NSData *)data error:(NSError **)error NS_SWIFT_NAME(decodeToArray(_:error:));

// TokenRequest
- (nullable NSData *)encodeTokenRequest:(ARTTokenRequest *)request error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTTokenRequest *)decodeTokenRequest:(NSData *)data error:(NSError * __autoreleasing *)error;

// TokenDetails
- (nullable NSData *)encodeTokenDetails:(ARTTokenDetails *)tokenDetails error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTTokenDetails *)decodeTokenDetails:(NSData *)data error:(NSError * __autoreleasing *)error;

// Message
- (nullable NSData *)encodeMessage:(ARTMessage *)message error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTMessage *)decodeMessage:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

// Message list
- (nullable NSData *)encodeMessages:(NSArray<ARTMessage *> *)messages error:(NSError *_Nullable *_Nullable)error;
- (nullable NSArray<ARTMessage *> *)decodeMessages:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

// PresenceMessage
- (nullable NSData *)encodePresenceMessage:(ARTPresenceMessage *)message error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTPresenceMessage *)decodePresenceMessage:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

// PresenceMessage list
- (nullable NSData *)encodePresenceMessages:(NSArray<ARTPresenceMessage *> *)messages error:(NSError *_Nullable *_Nullable)error;
- (nullable NSArray<ARTPresenceMessage *> *)decodePresenceMessages:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

// ProtocolMessage
- (nullable NSData *)encodeProtocolMessage:(ARTProtocolMessage *)message error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTProtocolMessage *)decodeProtocolMessage:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

// DeviceDetails
- (nullable NSData *)encodeDeviceDetails:(ARTDeviceDetails *)deviceDetails error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTDeviceDetails *)decodeDeviceDetails:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (nullable NSArray<ARTDeviceDetails *> *)decodeDevicesDetails:(NSData *)data error:(NSError * __autoreleasing *)error;
- (nullable ARTDeviceIdentityTokenDetails *)decodeDeviceIdentityTokenDetails:(NSData *)data error:(NSError * __autoreleasing *)error;

// DevicePushDetails
- (nullable NSData *)encodeDevicePushDetails:(ARTDevicePushDetails *)devicePushDetails error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTDevicePushDetails *)decodeDevicePushDetails:(NSData *)data error:(NSError * __autoreleasing *)error;

// Push Channel Subscription
- (nullable NSData *)encodePushChannelSubscription:(ARTPushChannelSubscription *)channelSubscription error:(NSError * __autoreleasing *)error;
- (nullable ARTPushChannelSubscription *)decodePushChannelSubscription:(NSData *)data error:(NSError * __autoreleasing *)error;
- (nullable NSArray<ARTPushChannelSubscription *> *)decodePushChannelSubscriptions:(NSData *)data error:(NSError * __autoreleasing *)error;

// Others
- (nullable NSDate *)decodeTime:(NSData *)data error:(NSError *_Nullable *_Nullable)error;
- (nullable ARTErrorInfo *)decodeErrorInfo:(NSData *)error error:(NSError *_Nullable *_Nullable)error;
- (nullable NSArray *)decodeStats:(NSData *)data error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
