//
//  ARTGCD.m
//  Ably
//
//  Created by Ricardo Pereira on 17/11/2016.
//  Copyright © 2016 Ably. All rights reserved.
//

#import "ARTGCD.h"

@interface ARTScheduledBlockHandle ()

@property (strong, atomic) dispatch_block_t scheduled;
@property (strong, atomic) dispatch_block_t wrapped;

@end

@implementation ARTScheduledBlockHandle

@end

ARTScheduledBlockHandle *artDispatchScheduled(NSTimeInterval seconds, dispatch_queue_t queue, dispatch_block_t block) {
	// We don't pass the block directly; instead, we put it in a property, and
	// read it back from the property once the timer fires. This gives us the
	// chance to set the property to nil when cancelling the timer, thus
	// releasing our retain on the block early. dispatch_block_cancel doesn't do
	// this, it retains the block even if you cancel the dispatch until the
	// dispatch time passes. (How this is a good idea escapes me.)
	//
	// From Apple's documentation [1]:
	//
	// > Release of any resources associated with the block object is delayed
	// > until execution of the block object is next attempted (or any execution
	// > already in progress completes).
	//
	// https://developer.apple.com/documentation/dispatch/1431058-dispatch_block_cancel

	__block ARTScheduledBlockHandle *handle = [[ARTScheduledBlockHandle alloc] init];
	handle.wrapped = block;

    handle.scheduled = dispatch_block_create(0, ^{
        dispatch_block_t wrapped = handle.wrapped;
        if (wrapped) {
            wrapped();
        }
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC * seconds)), queue, handle.scheduled);
    return handle;
}

void artDispatchCancel(ARTScheduledBlockHandle *handle) {
    if (handle) {
    	dispatch_block_cancel(handle.scheduled);

    	// Release the block, since it won't be called and dispatch_block_cancel
    	// won't release it until its dispatch time passes.
    	handle.wrapped = nil;
    }
}
