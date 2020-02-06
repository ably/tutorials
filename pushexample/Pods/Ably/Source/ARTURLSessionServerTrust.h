//
//  ARTURLSessionSelfSignedCertificate.h
//  ably
//
//  Created by Ricardo Pereira on 20/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTURLSession.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTURLSessionServerTrust : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate, ARTURLSession>

@end

NS_ASSUME_NONNULL_END
