//
//  NSString+ARTNSString.h
//  Ably
//
//  Created by Cesare Rocchi on 28/09/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NSStringFromBOOL(aBOOL) ((aBOOL) ? @"YES" : @"NO")

@interface NSString (ARTUtil)

+ (NSString *)nilToEmpty:(NSString*)aString;

@end
