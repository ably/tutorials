//
//  ARTClientOptions+Private.h
//  ably
//
//  Created by Toni Cárdenas on 24/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTClientOptions.h>

@interface ARTClientOptions ()

+ (void)setDefaultEnvironment:(NSString *_Nullable)environment;
+ (BOOL)getDefaultIdempotentRestPublishingForVersion:(NSString *_Nonnull)version;
- (NSURLComponents *_Nonnull)restUrlComponents;

@end
