//
//  ARTPush+Private.h
//  Ably
//
//  Created by Toni Cárdenas on 07/04/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Ably/ARTPush.h>

@class ARTPushActivationStateMachine;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPush ()

- (instancetype)init:(ARTRest *)rest;

- (ARTPushActivationStateMachine *)activationMachine;

@end

NS_ASSUME_NONNULL_END
