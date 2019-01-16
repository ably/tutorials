//
//  ARTNSHTTPURLResponse+ARTPaginated.h
//  Ably
//
//  Created by Ricardo Pereira on 23/08/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSHTTPURLResponse (ARTPaginated)

- (nullable NSDictionary *)extractLinks;

@end

NS_ASSUME_NONNULL_END
