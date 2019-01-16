//
//  ARTPushDeviceRegistrations.h
//  Ably
//
//  Created by Ricardo Pereira on 20/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

@class ARTDeviceDetails;
@class ARTPaginatedResult;
@class ARTRest;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushDeviceRegistrations : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRest:(ARTRest *)rest;

- (void)save:(ARTDeviceDetails *)deviceDetails callback:(void (^)(ARTErrorInfo *_Nullable))callback;

- (void)get:(ARTDeviceId *)deviceId callback:(void (^)(ARTDeviceDetails *_Nullable,  ARTErrorInfo *_Nullable))callback;

- (void)list:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTPaginatedResult<ARTDeviceDetails *> *_Nullable,  ARTErrorInfo *_Nullable))callback;

- (void)remove:(NSString *)deviceId callback:(void (^)(ARTErrorInfo *_Nullable))callback;
- (void)removeWhere:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTErrorInfo *_Nullable))callback;

@end

NS_ASSUME_NONNULL_END
