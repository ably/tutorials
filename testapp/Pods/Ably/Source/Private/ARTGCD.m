//
//  ARTGCD.m
//  Ably
//
//  Created by Ricardo Pereira on 17/11/2016.
//  Copyright © 2016 Ably. All rights reserved.
//

#import "ARTGCD.h"

dispatch_block_t artDispatchScheduled(NSTimeInterval seconds, dispatch_queue_t queue, dispatch_block_t block) {
    dispatch_block_t work = dispatch_block_create(0, block);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC * seconds)), queue, work);
    return work;
}

void artDispatchCancel(dispatch_block_t block) {
    if (block) dispatch_block_cancel(block);
}
