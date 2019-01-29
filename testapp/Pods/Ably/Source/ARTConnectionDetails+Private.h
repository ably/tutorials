//
//  ARTConnectionDetails+Private.h
//  Ably
//
//  Created by Ricardo Pereira on 24/3/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTConnectionDetails.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTConnectionDetails ()

@property (readwrite, strong, nonatomic, nullable) NSString *clientId;
@property (readwrite, strong, nonatomic, nullable) NSString *connectionKey;

- (void)setMaxIdleInterval:(NSTimeInterval)seconds;

@end

NS_ASSUME_NONNULL_END
