//
//  ARTReachability.h
//  Ably
//
//  Created by Toni Cárdenas on 2/5/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTLog.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTReachability <NSObject>

- (instancetype)initWithLogger:(ARTLog *)logger queue:(dispatch_queue_t)queue;

- (void)listenForHost:(NSString *)host callback:(void (^)(BOOL))callback;
- (void)off;

@end

NS_ASSUME_NONNULL_END
