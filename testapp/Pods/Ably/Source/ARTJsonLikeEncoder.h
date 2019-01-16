//
//  ARTJsonLikeEncoder.h
//  Ably
//
//  Created by Toni Cárdenas on 2/5/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#ifndef ARTJsonLikeEncoder_h
#define ARTJsonLikeEncoder_h

#import "CompatibilityMacros.h"
#import <Ably/ARTRest.h>
#import <Ably/ARTEncoder.h>
#import <Ably/ARTTokenDetails.h>
#import <Ably/ARTTokenRequest.h>
#import <Ably/ARTAuthDetails.h>
#import <Ably/ARTStats.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTJsonLikeEncoderDelegate <NSObject>

- (NSString *)mimeType;
- (ARTEncoderFormat)format;
- (NSString *)formatAsString;

- (nullable id)decode:(NSData *)data error:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (nullable NSData *)encode:(id)obj error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

@interface ARTJsonLikeEncoder : NSObject <ARTEncoder>

@property (nonatomic, strong, nullable) id<ARTJsonLikeEncoderDelegate> delegate;

- (instancetype)initWithDelegate:(id<ARTJsonLikeEncoderDelegate>)delegate;
- (instancetype)initWithLogger:(ARTLog *)logger delegate:(nullable id<ARTJsonLikeEncoderDelegate>)delegate;
- (instancetype)initWithRest:(ARTRest *)rest delegate:(nullable id<ARTJsonLikeEncoderDelegate>)delegate;

@end

@interface ARTJsonLikeEncoder ()

- (ARTMessage *)messageFromDictionary:(NSDictionary *)input;
- (NSArray *)messagesFromArray:(NSArray *)input;

- (ARTPresenceMessage *)presenceMessageFromDictionary:(NSDictionary *)input;
- (NSArray *)presenceMessagesFromArray:(NSArray *)input;

- (NSDictionary *)messageToDictionary:(ARTMessage *)message;
- (NSArray *)messagesToArray:(NSArray *)messages;

- (NSDictionary *)presenceMessageToDictionary:(ARTPresenceMessage *)message;
- (NSArray *)presenceMessagesToArray:(NSArray *)messages;

- (NSDictionary *)protocolMessageToDictionary:(ARTProtocolMessage *)message;
- (ARTProtocolMessage *)protocolMessageFromDictionary:(NSDictionary *)input;

- (NSDictionary *)tokenRequestToDictionary:(ARTTokenRequest *)tokenRequest;

- (NSDictionary *)authDetailsToDictionary:(ARTAuthDetails *)authDetails;
- (ARTAuthDetails *)authDetailsFromDictionary:(NSDictionary *)input;

- (NSArray *)statsFromArray:(NSArray *)input;
- (ARTStats *)statsFromDictionary:(NSDictionary *)input;
- (ARTStatsMessageTypes *)statsMessageTypesFromDictionary:(NSDictionary *)input;
- (ARTStatsMessageCount *)statsMessageCountFromDictionary:(NSDictionary *)input;
- (ARTStatsMessageTraffic *)statsMessageTrafficFromDictionary:(NSDictionary *)input;
- (ARTStatsConnectionTypes *)statsConnectionTypesFromDictionary:(NSDictionary *)input;
- (ARTStatsResourceCount *)statsResourceCountFromDictionary:(NSDictionary *)input;
- (ARTStatsRequestCount *)statsRequestCountFromDictionary:(NSDictionary *)input;

- (void)writeData:(id)data encoding:(NSString *)encoding toDictionary:(NSMutableDictionary *)output;

- (NSDictionary *)decodeDictionary:(NSData *)data error:(NSError **)error;
- (NSArray *)decodeArray:(NSData *)data error:(NSError **)error;

@end

ART_ASSUME_NONNULL_END

#endif /* ARTJsonLikeEncoder_h */
