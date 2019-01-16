//
//  ARTPendingMessage.h
//  Ably
//
//  Created by Ricardo Pereira on 20/12/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTQueuedMessage.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTPendingMessage : ARTQueuedMessage

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg sentCallback:(nullable void (^)(ARTErrorInfo *_Nullable))sentCallback ackCallback:(nullable void (^)(ARTStatus *))ackCallback UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg ackCallback:(nullable void (^)(ARTStatus *))ackCallback;

@end

NS_ASSUME_NONNULL_END
