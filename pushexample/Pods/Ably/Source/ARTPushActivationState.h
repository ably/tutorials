//
//  ARTPushActivationState.h
//  Ably
//
//  Created by Ricardo Pereira on 22/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTPushActivationStateMachine;
@class ARTPushActivationEvent;

@protocol ARTHTTPAuthenticatedExecutor;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPushActivationState : NSObject <NSSecureCoding>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithMachine:(ARTPushActivationStateMachine *)machine;
+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)newWithMachine:(ARTPushActivationStateMachine *)machine;

@property (atomic, strong, nullable) ARTPushActivationStateMachine *machine;

- (nullable ARTPushActivationState *)transition:(ARTPushActivationEvent *)event;

- (NSData *)archive;
+ (nullable ARTPushActivationState *)unarchive:(NSData *)data;

@end

/// Persistent State
@interface ARTPushActivationPersistentState : ARTPushActivationState
@end

#pragma mark - States

@interface ARTPushActivationStateNotActivated : ARTPushActivationPersistentState
@end

@interface ARTPushActivationStateWaitingForDeviceRegistration : ARTPushActivationState
@end

@interface ARTPushActivationStateWaitingForPushDeviceDetails : ARTPushActivationPersistentState
@end

@interface ARTPushActivationStateWaitingForNewPushDeviceDetails : ARTPushActivationPersistentState
@end

@interface ARTPushActivationStateWaitingForRegistrationUpdate : ARTPushActivationState
@end

@interface ARTPushActivationStateAfterRegistrationUpdateFailed : ARTPushActivationPersistentState
@end

@interface ARTPushActivationStateWaitingForDeregistration : ARTPushActivationState
@end

NS_ASSUME_NONNULL_END
