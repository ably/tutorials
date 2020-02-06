//
//  ARTCrypto+Private.h
//  ably
//
//  Created by Toni Cárdenas on 19/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTCrypto.h>
#import <Ably/ARTLog.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTCipherParams ()

@property (readonly, strong, nonatomic, nullable) NSData *iv;
@property (nonatomic, strong) ARTLog *logger;
- (instancetype)initWithAlgorithm:(NSString *)algorithm key:(id<ARTCipherKeyCompatible>)key iv:(NSData *_Nullable)iv;

@end

@protocol ARTChannelCipher

- (ARTStatus *)encrypt:(NSData *)plaintext output:(NSData *_Nullable *_Nullable)output;
- (ARTStatus *)decrypt:(NSData *)ciphertext output:(NSData *_Nullable *_Nullable)output;
- (NSString *)cipherName;
- (size_t) keyLength;

@end

@interface ARTCbcCipher : NSObject<ARTChannelCipher>

- (id)initWithCipherParams:(ARTCipherParams *)cipherParams;
+ (instancetype)cbcCipherWithParams:(ARTCipherParams *)cipherParams;


@property (nonatomic, strong) ARTLog *logger;
@property (readonly, strong, nonatomic) NSData *keySpec;
@property NSData *iv;
@property (readonly) NSUInteger blockLength;

@end

@interface ARTCrypto ()

+ (NSString *)defaultAlgorithm;
+ (int)defaultKeyLength;
+ (int)defaultBlockLength;

+ (nullable NSMutableData *)generateSecureRandomData:(size_t)length;
+ (NSData *)generateHashSHA256:(NSData *)data;

+ (id<ARTChannelCipher>)cipherWithParams:(ARTCipherParams *)params;

@end

NS_ASSUME_NONNULL_END
