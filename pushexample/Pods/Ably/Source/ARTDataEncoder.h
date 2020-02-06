//
//  ARTDataEncoder.h
//  ably-ios
//
//  Created by Jason Choy on 18/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTStatus.h>
#import <Ably/ARTCrypto.h>

@class ARTCipherParams;

NS_ASSUME_NONNULL_BEGIN

@interface ARTDataEncoderOutput : NSObject

@property (readonly, nonatomic, nullable) id data;
@property (readonly, nonatomic, nullable) NSString *encoding;
@property (readonly, nonatomic, nullable) ARTErrorInfo *errorInfo;

- initWithData:(id _Nullable)data encoding:(NSString *_Nullable)encoding errorInfo:(ARTErrorInfo *_Nullable)errorInfo;

@end

@interface ARTDataEncoder : NSObject 

- (instancetype)initWithCipherParams:(ARTCipherParams *_Nullable)params error:(NSError *_Nullable*_Nullable)error;
- (ARTDataEncoderOutput *)encode:(id _Nullable)data;
- (ARTDataEncoderOutput *)decode:(id _Nullable)data encoding:(NSString *_Nullable)encoding;

@end

@interface NSString (ARTDataEncoder)

+ (NSString *)artAddEncoding:(NSString *)encoding toString:(NSString *_Nullable)s;
- (NSString *)artLastEncoding;
- (nullable NSString *)artRemoveLastEncoding;

@end

NS_ASSUME_NONNULL_END
