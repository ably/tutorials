//
//  ARTAuthDetails.h
//  Ably
//
//  Created by Ricardo Pereira on 19/10/2016.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Used with an AUTH protocol messages to send authentication details
@interface ARTAuthDetails : NSObject<NSCopying>

@property (nonatomic, copy) NSString *accessToken;

- (instancetype)initWithToken:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
