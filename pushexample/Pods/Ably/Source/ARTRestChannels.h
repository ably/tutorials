//
//  ARTRestChannels.h
//  ably
//
//  Created by Toni Cárdenas on 3/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTChannels.h>
#import <Ably/ARTRestChannel.h>
#import <Ably/ARTRest.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTRestChannelsProtocol

// We copy this from the parent class and replace ChannelType by ARTRestChannel * because
// Swift ignores Objective-C generics and thinks this is returning an id, failing to compile.
// Thus, we can't make ARTRestChannels inherit from ARTChannels; we have to compose them instead.
- (BOOL)exists:(NSString *)name;
- (void)release:(NSString *)name;

@end

@interface ARTRestChannels : NSObject<ARTRestChannelsProtocol>

- (ARTRestChannel *)get:(NSString *)name;
- (ARTRestChannel *)get:(NSString *)name options:(ARTChannelOptions *)options;
- (id<NSFastEnumeration>)iterate;

@end

NS_ASSUME_NONNULL_END
