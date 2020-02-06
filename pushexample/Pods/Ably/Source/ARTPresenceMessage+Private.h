//
//  ARTPresenceMessage+Private.h
//  Ably
//
//  Created by Ricardo Pereira on 1/2/17.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Ably/ARTPresenceMessage.h>

@interface ARTPresenceMessage ()

@property (readwrite, assign, nonatomic) NSUInteger syncSessionId;

/**
 Returns whether this presenceMessage is synthesized, i.e. was not actually sent by the connection (usually means a leave event sent 15s after a disconnection). This is useful because synthesized messages cannot be compared for newness by id lexicographically - RTP2b1.
 */
- (BOOL)isSynthesized;

- (nonnull NSArray<NSString *> *)parseId;
- (NSInteger)msgSerialFromId;
- (NSInteger)indexFromId;

@end
