//
//  ARTHTTPPaginatedResponse+Private.h
//  Ably
//
//  Created by Yavor Georgiev on 28.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Ably/ARTHTTPPaginatedResponse.h>

@class ARTRest;

NS_ASSUME_NONNULL_BEGIN

@interface ARTHTTPPaginatedResponse ()

+ (void)executePaginated:(ARTRest *)rest withRequest:(NSMutableURLRequest *)request andResponseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor callback:(void (^)(ARTPaginatedResult * _Nullable, ARTErrorInfo * _Nullable))callback UNAVAILABLE_ATTRIBUTE;

+ (void)executePaginated:(ARTRest *)rest withRequest:(NSMutableURLRequest *)request callback:(void (^)(ARTHTTPPaginatedResponse *_Nullable result, ARTErrorInfo *_Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
