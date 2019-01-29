//
//  ARTDeviceStorage.h
//  Ably
//
//  Created by Ricardo Pereira on 15/03/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTDeviceStorage <NSObject>
- (nullable id)objectForKey:(NSString *)key;
- (void)setObject:(nullable id)value forKey:(NSString *)key;
- (nullable NSString *)secretForDevice:(ARTDeviceId *)deviceId;
- (void)setSecret:(nullable NSString *)value forDevice:(ARTDeviceId *)deviceId;
@end

NS_ASSUME_NONNULL_END
