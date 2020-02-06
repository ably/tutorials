//
//  ARTTokenParams+Private.h
//  ably
//
//  Created by Toni Cárdenas on 5/2/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <Ably/ARTTokenParams.h>

@interface ARTTokenParams (Private)

- (ARTTokenRequest *)sign:(NSString *)key;
- (ARTTokenRequest *)sign:(NSString *)key withNonce:(NSString *)nonce;

@end
