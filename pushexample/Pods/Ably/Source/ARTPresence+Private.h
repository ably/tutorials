//
//  ARTPresence+Private.h
//  ably
//
//  Created by Toni Cárdenas on 5/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTPresence.h>
#import <Ably/ARTChannel.h>

@interface ARTPresenceQuery ()

- (NSMutableArray<NSURLQueryItem *> *)asQueryItems;

@end

@interface ARTPresence ()

@property (readonly, getter=getChannel) ARTChannel *channel;

- (instancetype)initWithChannel:(ARTChannel *)channel;

@end
