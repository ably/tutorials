//
//  ARTBaseMessage+Private.h
//  ably
//
//  Created by Toni Cárdenas on 29/1/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/CompatibilityMacros.h>
#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTDataEncoder.h>
#import <Ably/ARTStatus.h>

ART_ASSUME_NONNULL_BEGIN

@interface ARTBaseMessage ()

@property (nonatomic, assign, readonly) BOOL isIdEmpty;

- (id __art_nonnull)decodeWithEncoder:(ARTDataEncoder*)encoder error:(NSError *__art_nullable*__art_nullable)error;
- (id __art_nonnull)encodeWithEncoder:(ARTDataEncoder*)encoder error:(NSError *__art_nullable*__art_nullable)error;

@end

ART_ASSUME_NONNULL_END
