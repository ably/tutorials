//
//  ARTHTTPPaginatedResponse+Private.h
//  Ably
//
//  Created by Yavor Georgiev on 28.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Ably/ARTHTTPPaginatedResponse.h>

#import <Ably/ARTPaginatedResult+Private.h>

@class ARTRestInternal;

NS_ASSUME_NONNULL_BEGIN

@interface ARTHTTPPaginatedResponse ()

@property (nonatomic, strong) NSHTTPURLResponse *response;

+ (void)executePaginated:(ARTRestInternal *)rest withRequest:(NSMutableURLRequest *)request andResponseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor callback:(void (^)(ARTPaginatedResult * _Nullable, ARTErrorInfo * _Nullable))callback UNAVAILABLE_ATTRIBUTE;

+ (void)executePaginated:(ARTRestInternal *)rest withRequest:(NSMutableURLRequest *)request callback:(void (^)(ARTHTTPPaginatedResponse *_Nullable result, ARTErrorInfo *_Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
