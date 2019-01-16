//
//  ARTPendingMessage.m
//  Ably
//
//  Created by Ricardo Pereira on 20/12/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPendingMessage.h"

@implementation ARTPendingMessage

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg ackCallback:(nullable void (^)(ARTStatus *))ackCallback {
    self = [super initWithProtocolMessage:msg sentCallback:nil ackCallback:ackCallback];
    return self;
}

@end
