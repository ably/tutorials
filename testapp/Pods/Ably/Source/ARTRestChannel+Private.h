
//
//  ARTRestChannel+Private.h
//  ably-ios
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Ably/ARTRestChannel.h>

@interface ARTRestChannel ()

- (instancetype)initWithName:(NSString *)name withOptions:(ARTChannelOptions *)options andRest:(ARTRest *)rest;

@property (nonatomic, weak) ARTRest *rest;

@end

@interface ARTRestChannel (Private)

@property (readonly, getter=getBasePath) NSString *basePath;

@end
