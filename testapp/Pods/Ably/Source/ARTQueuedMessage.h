//
//  ARTQueuedMessage.h
//  ably
//
//  Created by Ricardo Pereira on 01/10/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Ably/ARTTypes.h>

@class ARTProtocolMessage;

NS_ASSUME_NONNULL_BEGIN

@interface ARTQueuedMessage : NSObject

@property (readonly, strong, nonatomic) ARTProtocolMessage *msg;
@property (readonly, strong, nonatomic) NSMutableArray *sentCallbacks;
@property (readonly, strong, nonatomic) NSMutableArray *ackCallbacks;

- (instancetype)initWithProtocolMessage:(ARTProtocolMessage *)msg sentCallback:(nullable void (^)(ARTErrorInfo *_Nullable))sentCallback ackCallback:(nullable void (^)(ARTStatus *))ackCallback;

- (BOOL)mergeFrom:(ARTProtocolMessage *)msg sentCallback:(nullable void (^)(ARTErrorInfo *_Nullable))sentCallback ackCallback:(nullable void (^)(ARTStatus *))ackCallback;

- (void (^)(ARTErrorInfo *))sentCallback;
- (void (^)(ARTStatus *))ackCallback;

@end

NS_ASSUME_NONNULL_END
