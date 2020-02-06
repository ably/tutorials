//
//  ARTPushActivationStateMachine+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 26/01/2018.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Ably/ARTPushActivationStateMachine.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTRestInternal;

extern NSString *const ARTPushActivationCurrentStateKey;
extern NSString *const ARTPushActivationPendingEventsKey;

@interface ARTPushActivationStateMachine ()

@property (nonatomic, strong) ARTRestInternal *rest;
- (instancetype)init:(ARTRestInternal *)rest;
- (instancetype)init:(ARTRestInternal *)rest delegate:(nullable id)delegate;

@property (weak, nonatomic) id delegate; // weak because delegates outlive their counterpart
@property (nonatomic, copy, nullable) void (^transitions)(ARTPushActivationEvent *event, ARTPushActivationState *from, ARTPushActivationState *to);
@property (readonly, nonatomic) ARTPushActivationEvent *lastEvent_nosync;
@property (readonly, nonatomic) ARTPushActivationState *current_nosync;

@end

NS_ASSUME_NONNULL_END
