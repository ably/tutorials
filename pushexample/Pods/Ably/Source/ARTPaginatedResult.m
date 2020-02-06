//
//  ARTPaginatedResult.m
//  ably
//
//  Created by Yavor Georgiev on 10.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTPaginatedResult+Private.h"

#import "ARTHttp.h"
#import "ARTAuth.h"
#import "ARTRest+Private.h"
#import "ARTNSMutableURLRequest+ARTPaginated.h"
#import "ARTNSHTTPURLResponse+ARTPaginated.h"

@implementation ARTPaginatedResult {
    ARTRestInternal *_rest;
    dispatch_queue_t _userQueue;
    dispatch_queue_t _queue;
    NSMutableURLRequest *_relFirst;
    NSMutableURLRequest *_relCurrent;
    NSMutableURLRequest *_relNext;
    ARTPaginatedResultResponseProcessor _responseProcessor;
    ARTQueuedDealloc *_dealloc;
}

@synthesize rest = _rest;
@synthesize userQueue = _userQueue;
@synthesize queue = _queue;
@synthesize relFirst = _relFirst;
@synthesize relCurrent = _relCurrent;
@synthesize relNext = _relNext;

- (instancetype)initWithItems:(NSArray *)items
                     rest:(ARTRestInternal *)rest
                     relFirst:(NSMutableURLRequest *)relFirst
                   relCurrent:(NSMutableURLRequest *)relCurrent
                      relNext:(NSMutableURLRequest *)relNext
            responseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor {
    if (self = [super init]) {
        _items = items;
        
        _relFirst = relFirst;
        
        _relCurrent = relCurrent;
        
        _relNext = relNext;
        _hasNext = !!relNext;
        _isLast = !_hasNext;
        
        _rest = rest;
        _userQueue = rest.userQueue;
        _queue = rest.queue;
        _responseProcessor = responseProcessor;

        // ARTPaginatedResult doesn't need a internal counterpart, as other
        // public objects do. It basically acts as a proxy to a
        // strongly-referenced ARTRestInternal, so it can be thought as an
        // alternative public counterpart to ARTRestInternal.
        //
        // So, since it's owned by user code, it should dispatch its release of
        // its ARTRestInternal to the internal queue. We could take the common
        // ARTQueuedDealloc as an argument as other public objects do, but
        // that would just be bookkeeping since we know it will be initialized
        // from the ARTRestInternal we already have access to anyway, so we can
        // make our own.
        _dealloc = [[ARTQueuedDealloc alloc] init:_rest queue:_queue];
    }
    
    return self;
}

- (void)first:(void (^)(ARTPaginatedResult<id> *_Nullable result, ARTErrorInfo *_Nullable error))callback {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult<id> *_Nullable result, ARTErrorInfo *_Nullable error) = callback;
        callback = ^(ARTPaginatedResult<id> *_Nullable result, ARTErrorInfo *_Nullable error) {
            ART_EXITING_ABLY_CODE(self->_rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

    [self.class executePaginated:_rest withRequest:_relFirst andResponseProcessor:_responseProcessor callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)next:(void (^)(ARTPaginatedResult<id> *_Nullable result, ARTErrorInfo *_Nullable error))callback {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult<id> *_Nullable result, ARTErrorInfo *_Nullable error) = callback;
        callback = ^(ARTPaginatedResult<id> *_Nullable result, ARTErrorInfo *_Nullable error) {
            ART_EXITING_ABLY_CODE(self->_rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

    if (!_relNext) {
        // If there is no next page, we can't make a request, so we answer the callback
        // with a nil PaginatedResult. That's why the callback has the result as nullable
        // anyway. (That, and that it can fail.)
        callback(nil, nil);
        return;
    }
    [self.class executePaginated:_rest withRequest:_relNext andResponseProcessor:_responseProcessor callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
}

+ (void)executePaginated:(ARTRestInternal *)rest withRequest:(NSMutableURLRequest *)request andResponseProcessor:(ARTPaginatedResultResponseProcessor)responseProcessor callback:(void (^)(ARTPaginatedResult<id> *_Nullable result, ARTErrorInfo *_Nullable error))callback {
ART_TRY_OR_REPORT_CRASH_START(rest) {
    [rest.logger debug:__FILE__ line:__LINE__ message:@"Paginated request: %@", request];

    [rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            callback(nil, [ARTErrorInfo createFromNSError:error]);
        } else {
            [[rest logger] debug:__FILE__ line:__LINE__ message:@"Paginated response: %@", response];
            [[rest logger] debug:__FILE__ line:__LINE__ message:@"Paginated response data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];

            NSError *decodeError = nil;
            NSArray *items = responseProcessor(response, data, &decodeError);

            if (decodeError) {
                callback(nil, [ARTErrorInfo createFromNSError:decodeError]);
                return;
            }

            NSDictionary *links = [response extractLinks];

            NSMutableURLRequest *firstRel = [NSMutableURLRequest requestWithPath:links[@"first"] relativeTo:request];
            NSMutableURLRequest *currentRel = [NSMutableURLRequest requestWithPath:links[@"current"] relativeTo:request];
            NSMutableURLRequest *nextRel = [NSMutableURLRequest requestWithPath:links[@"next"] relativeTo:request];

            ARTPaginatedResult *result = [[ARTPaginatedResult alloc] initWithItems:items
                                                                              rest:rest
                                                                          relFirst:firstRel
                                                                        relCurrent:currentRel
                                                                           relNext:nextRel
                                                                 responseProcessor:responseProcessor];

            callback(result, nil);
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
}

@end
