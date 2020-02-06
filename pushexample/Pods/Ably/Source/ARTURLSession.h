//
//  ARTURLSession.h
//  Ably
//
//  Copyright © 2019 Ably. All rights reserved.
//

#ifndef ARTURLSession_h
#define ARTURLSession_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTURLSession <NSObject>

- (instancetype)init:(dispatch_queue_t)queue;

- (NSObject<ARTCancellable> *)get:(NSURLRequest *)request completion:(void (^)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable))callback;

- (void)finishTasksAndInvalidate;

@end

NS_ASSUME_NONNULL_END

#endif /* ARTURLSession_h */
