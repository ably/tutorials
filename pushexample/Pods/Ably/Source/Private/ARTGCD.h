//
//  ARTGCD.h
//  Ably
//
//  Created by Ricardo Pereira on 17/11/2016.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARTScheduledBlockHandle : NSObject
@end

ARTScheduledBlockHandle *artDispatchScheduled(NSTimeInterval seconds, dispatch_queue_t queue, dispatch_block_t block);
void artDispatchCancel(ARTScheduledBlockHandle *handle);
