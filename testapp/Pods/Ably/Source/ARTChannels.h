//
//  ARTChannels.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTRest;
@class ARTRestChannel;
@class ARTChannelOptions;

@interface ARTChannels<ChannelType> : NSObject<NSFastEnumeration>

- (BOOL)exists:(NSString *)name;
- (ChannelType)get:(NSString *)name;
- (ChannelType)get:(NSString *)name options:(ARTChannelOptions *)options;
- (void)release:(NSString *)name;

@end
