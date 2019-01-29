//
//  ARTNSMutableURLRequest+ARTPaginated.m
//  Ably
//
//  Created by Ricardo Pereira on 23/08/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

#import "ARTNSMutableURLRequest+ARTPaginated.h"

@implementation NSMutableURLRequest (ARTPaginated)

+ (NSMutableURLRequest *)requestWithPath:(NSString *)path relativeTo:(NSURLRequest *)request {
    if (!path) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:path relativeToURL:request.URL];
    return [NSMutableURLRequest requestWithURL:url];
}

@end
