//
//  ARTNSMutableRequest+ARTRest.m
//  Ably
//
//  Created by Ricardo Pereira on 22/03/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

#import "ARTNSMutableRequest+ARTRest.h"

#import "ARTEncoder.h"

@implementation NSMutableURLRequest (ARTRest)

- (void)setAcceptHeader:(id<ARTEncoder>)defaultEncoder encoders:(NSDictionary<NSString *, id<ARTEncoder>> *)encoders {
    NSMutableArray *allEncoders = [NSMutableArray arrayWithArray:[encoders.allValues valueForKeyPath:@"mimeType"]];
    NSString *defaultMimetype = [defaultEncoder mimeType];
    // Make the mime type of the default encoder the first element of the Accept header field
    [allEncoders removeObject:defaultMimetype];
    [allEncoders insertObject:defaultMimetype atIndex:0];
    NSString *accept = [allEncoders componentsJoinedByString:@","];
    [self setValue:accept forHTTPHeaderField:@"Accept"];
}

@end
