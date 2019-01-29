//
//  ARTRestPresence.m
//  ably
//
//  Created by Ricardo Pereira on 12/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import "ARTRestPresence+Private.h"

#import "ARTPresence+Private.h"
#import "ARTRest+Private.h"
#import "ARTRestChannel+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDataQuery+Private.h"
#import "ARTJsonEncoder.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTChannel+Private.h"
#import "ARTBaseMessage+Private.h"

#import "ARTChannel.h"
#import "ARTDataQuery.h"

@implementation ARTPresenceQuery

- (instancetype)init {
    return [self initWithClientId:nil connectionId:nil];
}

- (instancetype)initWithClientId:(NSString *)clientId connectionId:(NSString *)connectionId {
    return [self initWithLimit:100 clientId:clientId connectionId:connectionId];
}

- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *)clientId connectionId:(NSString *)connectionId {
    self = [super init];
    if (self) {
        _limit = limit;
        _clientId = clientId;
        _connectionId = connectionId;
    }
    return self;
}

- (NSMutableArray *)asQueryItems {
    NSMutableArray *items = [NSMutableArray array];

    if (self.clientId) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"clientId" value:self.clientId]];
    }
    if (self.connectionId) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"connectionId" value:self.connectionId]];
    }

    [items addObject:[NSURLQueryItem queryItemWithName:@"limit" value:[NSString stringWithFormat:@"%lu", (unsigned long)self.limit]]];

    return items;
}

@end

@implementation ARTRestPresence {
    __weak ARTRestChannel *_channel;
    dispatch_queue_t _userQueue;
    dispatch_queue_t _queue;
}

- (instancetype)initWithChannel:(ARTRestChannel *)channel {
ART_TRY_OR_REPORT_CRASH_START(channel.rest) {
    if (self = [super init]) {
        _channel = channel;
        _userQueue = channel.rest.userQueue;
        _queue = channel.rest.queue;
    }
    return self;
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)get:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *result, ARTErrorInfo *error))callback {
ART_TRY_OR_REPORT_CRASH_START(_channel.rest) {
    [self get:[[ARTPresenceQuery alloc] init] callback:callback error:nil];
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)get:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *result, ARTErrorInfo *error))callback error:(NSError **)errorPtr {
ART_TRY_OR_REPORT_CRASH_START(_channel.rest) {
    return [self get:[[ARTPresenceQuery alloc] init] callback:callback error:errorPtr];
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)get:(ARTPresenceQuery *)query callback:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> *, ARTErrorInfo *))callback error:(NSError **)errorPtr {
ART_TRY_OR_REPORT_CRASH_START(_channel.rest) {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult<ARTPresenceMessage *> *, ARTErrorInfo *) = callback;
        callback = ^(ARTPaginatedResult<ARTPresenceMessage *> *m, ARTErrorInfo *e) {
            ART_EXITING_ABLY_CODE(self->_channel.rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(m, e);
            });
        };
    }

    if (query.limit > 1000) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorLimit
                                        userInfo:@{NSLocalizedDescriptionKey:@"Limit supports up to 1000 results only"}];
        }
        return NO;
    }

    NSURLComponents *requestUrl = [NSURLComponents componentsWithString:[_channel.basePath stringByAppendingPathComponent:@"presence"]];
    requestUrl.queryItems = [query asQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl.URL];

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **errorPtr) {
        id<ARTEncoder> encoder = [self->_channel.rest.encoders objectForKey:response.MIMEType];
        return [[encoder decodePresenceMessages:data error:errorPtr] artMap:^(ARTPresenceMessage *message) {
            // FIXME: This should be refactored to be done by ART{Json,...}Encoder.
            // The ART{Json,...}Encoder should take a ARTDataEncoder and use it every
            // time it is enc/decoding a message. This also applies for REST and Realtime
            // ARTMessages.
            message = [message decodeWithEncoder:self->_channel.dataEncoder error:nil];
            return message;
        }];
    };

dispatch_async(_queue, ^{
    [ARTPaginatedResult executePaginated:self->_channel.rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
});
    return YES;
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *, ARTErrorInfo *))callback {
ART_TRY_OR_REPORT_CRASH_START(_channel.rest) {
    [self history:[[ARTDataQuery alloc] init] callback:callback error:nil];
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)history:(ARTDataQuery *)query callback:(void(^)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *result, ARTErrorInfo *error))callback error:(NSError **)errorPtr {
ART_TRY_OR_REPORT_CRASH_START(_channel.rest) {
    if (callback) {
        void (^userCallback)(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *result, ARTErrorInfo *error) = callback;
        callback = ^(__GENERIC(ARTPaginatedResult, ARTPresenceMessage *) *result, ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(self->_channel.rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

    if (query.limit > 1000) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorLimit
                                        userInfo:@{NSLocalizedDescriptionKey:@"Limit supports up to 1000 results only"}];
        }
        return NO;
    }
    if ([query.start compare:query.end] == NSOrderedDescending) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorTimestampRange
                                        userInfo:@{NSLocalizedDescriptionKey:@"Start must be equal to or less than end"}];
        }
        return NO;
    }

    NSURLComponents *requestUrl = [NSURLComponents componentsWithString:[_channel.basePath stringByAppendingPathComponent:@"presence/history"]];
    NSError *error = nil;
    requestUrl.queryItems = [query asQueryItems:&error];
    if (error) {
        if (errorPtr) {
            *errorPtr = error;
        }
        return NO;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl.URL];

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **errorPtr) {
        id<ARTEncoder> encoder = [self->_channel.rest.encoders objectForKey:response.MIMEType];
        return [[encoder decodePresenceMessages:data error:errorPtr] artMap:^(ARTPresenceMessage *message) {
            NSError *error = nil;
            message = [message decodeWithEncoder:self->_channel.dataEncoder error:&error];
            if (error != nil) {
                ARTErrorInfo *errorInfo = [ARTErrorInfo wrap:[ARTErrorInfo createFromNSError:error] prepend:@"Failed to decode data: "];
                [self->_channel.logger error:@"RS:%p %@", self->_channel.rest, errorInfo.message];
            }
            return message;
        }];
    };

dispatch_async(_queue, ^{
    [ARTPaginatedResult executePaginated:self->_channel.rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
});
    return YES;
} ART_TRY_OR_REPORT_CRASH_END
}

@end
