//
//  ARTNSHTTPURLResponse+ARTPaginated.m
//  Ably
//
//  Created by Ricardo Pereira on 23/08/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

#import "ARTNSHTTPURLResponse+ARTPaginated.h"

@implementation NSHTTPURLResponse (ARTPaginated)

- (NSDictionary *)extractLinks {
    NSString *linkHeader = self.allHeaderFields[@"Link"];
    if (!linkHeader) {
        return nil;
    }

    static NSRegularExpression *linkRegex;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        linkRegex = [NSRegularExpression regularExpressionWithPattern:@"\\s*<([^>]*)>;\\s*rel=\"([^\"]*)\"" options:0 error:nil];
    });

    NSMutableDictionary *links = [NSMutableDictionary dictionary];

    NSArray *matches = [linkRegex matchesInString:linkHeader options:0 range:NSMakeRange(0, linkHeader.length)];
    for (NSTextCheckingResult *match in matches) {
        NSRange linkUrlRange = [match rangeAtIndex:1];
        NSRange linkRelRange = [match rangeAtIndex:2];

        NSString *linkUrl = [linkHeader substringWithRange:linkUrlRange];
        NSString *linkRels = [linkHeader substringWithRange:linkRelRange];

        for (NSString *linkRel in [linkRels componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]) {
            [links setObject:linkUrl forKey:linkRel];
        }
    }

    return links;
}

@end
