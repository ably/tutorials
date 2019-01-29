//
//  ARTRestChannels+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 21/07/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Ably/ARTRestChannels.h>

@class ARTRestChannel;

NS_ASSUME_NONNULL_BEGIN

@interface ARTRestChannels ()

- (ARTRestChannel *)_getChannel:(NSString *)name options:(ARTChannelOptions * _Nullable)options addPrefix:(BOOL)addPrefix;

@end

NS_ASSUME_NONNULL_END
