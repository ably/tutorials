//
//  ARTNSMutableURLRequest+ARTPaginated.h
//  Ably
//
//  Created by Ricardo Pereira on 23/08/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableURLRequest (ARTPaginated)

+ (nullable NSMutableURLRequest *)requestWithPath:(NSString *)path relativeTo:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
