//
//  ARTHTTPPaginatedResponse.m
//  Ably
//
//  Created by Ricardo Pereira on 17/08/2018.
//  Copyright © 2018 Ably. All rights reserved.
//

#import "ARTHTTPPaginatedResponse+Private.h"

#import "ARTHttp.h"
#import "ARTAuth.h"
#import "ARTRest+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTNSMutableURLRequest+ARTPaginated.h"
#import "ARTNSHTTPURLResponse+ARTPaginated.h"
#import "ARTEncoder.h"
#import "ARTConstants.h"

@implementation ARTHTTPPaginatedResponse

- (instancetype)initWithResponse:(NSHTTPURLResponse *)response
                           items:(NSArray *)items
                            rest:(ARTRestInternal *)rest
                        relFirst:(NSMutableURLRequest *)relFirst
                      relCurrent:(NSMutableURLRequest *)relCurrent
                         relNext:(NSMutableURLRequest *)relNext
               responseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor {
    self = [super initWithItems:items rest:rest relFirst:relFirst relCurrent:relCurrent relNext:relNext responseProcessor:responseProcessor];
    if (self) {
        _response = response;
    }
    return self;
}

- (NSInteger)statusCode {
    return _response.statusCode;
}

- (BOOL)success {
    return _response.statusCode >= 200 && _response.statusCode < 300;
}

- (NSInteger)errorCode {
    NSString *code = [_response.allHeaderFields valueForKey:ARTHttpHeaderFieldErrorCodeKey];
    return [code integerValue];
}

- (NSString *)errorMessage {
    NSString *message = [_response.allHeaderFields valueForKey:ARTHttpHeaderFieldErrorMessageKey];
    return message;
}

- (NSDictionary<NSString *,NSString *> *)headers {
    return _response.allHeaderFields;
}

- (void)first:(void (^)(ARTHTTPPaginatedResponse *_Nullable result, ARTErrorInfo *_Nullable error))callback {
ART_TRY_OR_REPORT_CRASH_START(self.rest) {
    if (callback) {
        void (^userCallback)(ARTHTTPPaginatedResponse *_Nullable result, ARTErrorInfo *_Nullable error) = callback;
        callback = ^(ARTHTTPPaginatedResponse *_Nullable result, ARTErrorInfo *_Nullable error) {
            ART_EXITING_ABLY_CODE(self.rest);
            dispatch_async(self.userQueue, ^{
                userCallback(result, error);
            });
        };
    }

    [self.class executePaginated:self.rest withRequest:self.relFirst callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)next:(void (^)(ARTHTTPPaginatedResponse *_Nullable result, ARTErrorInfo *_Nullable error))callback {
ART_TRY_OR_REPORT_CRASH_START(self.rest) {
    if (callback) {
        void (^userCallback)(ARTHTTPPaginatedResponse *_Nullable result, ARTErrorInfo *_Nullable error) = callback;
        callback = ^(ARTHTTPPaginatedResponse *_Nullable result, ARTErrorInfo *_Nullable error) {
            ART_EXITING_ABLY_CODE(self.rest);
            dispatch_async(self.userQueue, ^{
                userCallback(result, error);
            });
        };
    }

    if (!self.relNext) {
        // If there is no next page, we can't make a request, so we answer the callback
        // with a nil PaginatedResult. That's why the callback has the result as nullable
        // anyway. (That, and that it can fail.)
        callback(nil, nil);
        return;
    }

    [self.class executePaginated:self.rest withRequest:self.relNext callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
}

+ (void)executePaginated:(ARTRestInternal *)rest withRequest:(NSMutableURLRequest *)request callback:(void (^)(ARTHTTPPaginatedResponse *_Nullable result, ARTErrorInfo *_Nullable error))callback {
ART_TRY_OR_REPORT_CRASH_START(rest) {
    [rest.logger debug:__FILE__ line:__LINE__ message:@"HTTP Paginated request: %@", request];

    [rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error && ![error.domain isEqualToString:ARTAblyErrorDomain]) {
            callback(nil, [ARTErrorInfo createFromNSError:error]);
            return;
        }

        [[rest logger] debug:__FILE__ line:__LINE__ message:@"HTTP Paginated response: %@", response];
        [[rest logger] debug:__FILE__ line:__LINE__ message:@"HTTP Paginated response data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];

        NSError *decodeError = nil;

        ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **errorPtr) {
            id<ARTEncoder> encoder = [rest.encoders objectForKey:response.MIMEType];
            return [encoder decodeToArray:data error:errorPtr];
        };
        NSArray *items = error ? nil : responseProcessor(response, data, &decodeError);

        if (decodeError) {
            callback(nil, [ARTErrorInfo createFromNSError:decodeError]);
            return;
        }

        NSDictionary *links = [response extractLinks];

        NSMutableURLRequest *firstRel = [NSMutableURLRequest requestWithPath:links[@"first"] relativeTo:request];
        NSMutableURLRequest *currentRel = [NSMutableURLRequest requestWithPath:links[@"current"] relativeTo:request];
        NSMutableURLRequest *nextRel = [NSMutableURLRequest requestWithPath:links[@"next"] relativeTo:request];

        ARTHTTPPaginatedResponse *result = [[ARTHTTPPaginatedResponse alloc] initWithResponse:response items:items rest:rest relFirst:firstRel relCurrent:currentRel relNext:nextRel responseProcessor:responseProcessor];

        callback(result, nil);
    }];
} ART_TRY_OR_REPORT_CRASH_END
}

@end
