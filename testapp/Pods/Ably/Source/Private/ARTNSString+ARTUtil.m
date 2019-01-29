//
//  NSString+ARTNSString.m
//  Ably
//
//  Created by Cesare Rocchi on 28/09/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

#import "ARTNSString+ARTUtil.h"

@implementation NSString (ARTUtil)

+ (NSString *)nilToEmpty:(NSString*)aString {
    if ([aString length] == 0) {
        return @"";
    }
    return aString;
}

@end
