//
//  ARTMessage.h
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTMessage : ARTBaseMessage

/// The event name, if available
@property (nullable, readwrite, strong, nonatomic) NSString *name;

- (instancetype)initWithName:(nullable NSString *)name data:(id)data;
- (instancetype)initWithName:(nullable NSString *)name data:(id)data clientId:(NSString *)clientId;

@end

NS_ASSUME_NONNULL_END
