//
//  ARTPresence.h
//  ably
//
//  Created by Yavor Georgiev on 26.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTPresenceMessage.h>
#import <Ably/ARTPaginatedResult.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTPresence : NSObject

- (void)history:(void(^)(ARTPaginatedResult<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
