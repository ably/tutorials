//
//  ARTURLSessionSelfSignedCertificate.h
//  ably
//
//  Created by Ricardo Pereira on 20/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTURLSessionServerTrust : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate>

- (instancetype)init:(dispatch_queue_t)queue;

- (void)get:(NSURLRequest *)request completion:(void (^)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable))callback;

- (void)finishTasksAndInvalidate;

@end

NS_ASSUME_NONNULL_END
