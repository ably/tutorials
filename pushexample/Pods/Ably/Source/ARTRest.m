//
//  ARTRest.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTRest+Private.h"

#import "ARTChannel+Private.h"
#import "ARTRestChannels+Private.h"
#import "ARTDataQuery+Private.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTAuth+Private.h"
#import "ARTHttp.h"
#import "ARTEncoder.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTJsonEncoder.h"
#import "ARTMsgPackEncoder.h"
#import "ARTMessage.h"
#import "ARTPresence.h"
#import "ARTPresenceMessage.h"
#import "ARTHttp.h"
#import "ARTClientOptions+Private.h"
#import "ARTDefault.h"
#import "ARTStats.h"
#import "ARTFallback+Private.h"
#import "ARTNSDictionary+ARTDictionaryUtil.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTRestChannel.h"
#import "ARTTokenParams.h"
#import "ARTTokenDetails.h"
#import "ARTDefault.h"
#import "ARTGCD.h"
#import "ARTLog+Private.h"
#import "ARTRealtime+Private.h"
#import "ARTSentry.h"
#import "ARTPush.h"
#import "ARTPush+Private.h"
#import "ARTLocalDevice+Private.h"
#import "ARTLocalDeviceStorage.h"
#import "ARTNSMutableRequest+ARTRest.h"
#import "ARTHTTPPaginatedResponse+Private.h"
#import <KSCrashAblyFork/KSCrash.h>

@implementation ARTRest {
    ARTQueuedDealloc *_dealloc;
}

- (void)internalAsync:(void (^)(ARTRestInternal * _Nonnull))use {
    dispatch_async(_internal.queue, ^{
        use(self->_internal);
    });
}

- (void)initCommon {
    _dealloc = [[ARTQueuedDealloc alloc] init:_internal queue:_internal.queue];
}

- (instancetype)initWithOptions:(ARTClientOptions *)options {
    self = [super init];
    if (self) {
        _internal = [[ARTRestInternal alloc] initWithOptions:options];
        [self initCommon];
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key {
    self = [super init];
    if (self) {
        _internal = [[ARTRestInternal alloc] initWithKey:key];
        [self initCommon];
    }
    return self;
}

- (instancetype)initWithToken:(NSString *)token {
    self = [super init];
    if (self) {
        _internal = [[ARTRestInternal alloc] initWithToken:token];
        [self initCommon];
    }
    return self;
}

+ (instancetype)createWithOptions:(ARTClientOptions *)options {
    return [[ARTRest alloc] initWithOptions:options];
}

+ (instancetype)createWithKey:(NSString *)key {
    return [[ARTRest alloc] initWithKey:key];
}

+ (instancetype)createWithToken:(NSString *)tokenId {
    return [[ARTRest alloc] initWithToken:tokenId];
}

- (void)time:(void (^)(NSDate *_Nullable, NSError *_Nullable))callback {
    [_internal time:callback];
}

- (BOOL)request:(NSString *)method path:(NSString *)path params:(nullable NSDictionary<NSString *, NSString *> *)params body:(nullable id)body headers:(nullable NSDictionary<NSString *, NSString *> *)headers callback:(void (^)(ARTHTTPPaginatedResponse *_Nullable, ARTErrorInfo *_Nullable))callback error:(NSError *_Nullable *_Nullable)errorPtr {
    return [_internal request:(NSString *)method path:path params:params body:body headers:headers callback:callback error:errorPtr];
}

- (BOOL)stats:(void (^)(ARTPaginatedResult<ARTStats *> *_Nullable, ARTErrorInfo *_Nullable))callback {
    return [_internal stats:callback];
}

- (BOOL)stats:(nullable ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult<ARTStats *> *_Nullable, ARTErrorInfo *_Nullable))callback error:(NSError *_Nullable *_Nullable)errorPtr {
    return [_internal stats:query callback:callback error:errorPtr];
}

- (ARTRestChannels *)channels {
    return [[ARTRestChannels alloc] initWithInternal:_internal.channels queuedDealloc:_dealloc];
}

- (ARTAuth *)auth {
    return [[ARTAuth alloc] initWithInternal:_internal.auth queuedDealloc:_dealloc];
}

- (ARTPush *)push {
    return [[ARTPush alloc] initWithInternal:_internal.push queuedDealloc:_dealloc];
}

#if TARGET_OS_IOS

- (ARTLocalDevice *)device {
    return _internal.device;
}

- (ARTLocalDevice *)device_nosync {
    return _internal.device_nosync;
}

#endif

@end

@interface ARTRestInternal () {
    __block NSUInteger _tokenErrorRetries;
    BOOL _handlingUncaughtExceptions;
}

@end

@implementation ARTRestInternal {
    ARTLog *_logger;
}

@synthesize logger = _logger;

- (instancetype)initWithOptions:(ARTClientOptions *)options {
ART_TRY_OR_REPORT_CRASH_START(self) {
    return [self initWithOptions:options realtime:nil];
} ART_TRY_OR_REPORT_CRASH_END
}

- (instancetype)initWithOptions:(ARTClientOptions *)options realtime:(ARTRealtimeInternal *_Nullable)realtime {
    self = [super init];
    if (self) {
        NSAssert(options, @"ARTRest: No options provided");

        _realtime = realtime;
        _options = [options copy];

        if (options.logHandler) {
            _logger = options.logHandler;
        }
        else {
            _logger = [[ARTLog alloc] init];
        }

        if (options.logLevel != ARTLogLevelNone) {
            _logger.logLevel = options.logLevel;
        }

    ART_TRY_OR_REPORT_CRASH_START(self) {
        _queue = options.internalDispatchQueue;
        _userQueue = options.dispatchQueue;
        _storage = [ARTLocalDeviceStorage newWithLogger:_logger];
        _http = [[ARTHttp alloc] init:_queue logger:_logger];
        [_logger verbose:__FILE__ line:__LINE__ message:@"RS:%p %p alloc HTTP", self, _http];
        _httpExecutor = _http;

        id<ARTEncoder> jsonEncoder = [[ARTJsonLikeEncoder alloc] initWithRest:self delegate:[[ARTJsonEncoder alloc] init]];
        id<ARTEncoder> msgPackEncoder = [[ARTJsonLikeEncoder alloc] initWithRest:self delegate:[[ARTMsgPackEncoder alloc] init]];
        _encoders = @{
            [jsonEncoder mimeType]: jsonEncoder,
            [msgPackEncoder mimeType]: msgPackEncoder
        };
        _defaultEncoding = (_options.useBinaryProtocol ? [msgPackEncoder mimeType] : [jsonEncoder mimeType]);
        _fallbackCount = 0;
        _tokenErrorRetries = 0;

        _auth = [[ARTAuthInternal alloc] init:self withOptions:_options];
        _push = [[ARTPushInternal alloc] init:self];
        _channels = [[ARTRestChannelsInternal alloc] initWithRest:self];
        _handlingUncaughtExceptions = false;

        [self.logger verbose:__FILE__ line:__LINE__ message:@"RS:%p initialized", self];
    } ART_TRY_OR_REPORT_CRASH_END

        NSString *dns = self.options.logExceptionReportingUrl;
        if (dns) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                [ARTSentry setTags:[self sentryTags]];
                BOOL set = [ARTSentry setCrashHandler:dns];
                if (set) {
                    [self->_logger info:@"Ably client library exception reporting enabled. Unhandled failures will be automatically submitted to errors.ably.io to help improve our service. To find out more about this feature, see https://help.ably.io/exceptions"];
                } else {
                    [self->_logger debug:@"couldn't start crash handler"];
                }
            });
        }
    }
    return self;
}

- (instancetype)initWithKey:(NSString *)key {
ART_TRY_OR_REPORT_CRASH_START(self) {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithKey:key]];
} ART_TRY_OR_REPORT_CRASH_END
}

- (instancetype)initWithToken:(NSString *)token {
ART_TRY_OR_REPORT_CRASH_START(self) {
    return [self initWithOptions:[[ARTClientOptions alloc] initWithToken:token]];
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)dealloc {
ART_TRY_OR_REPORT_CRASH_START(self) {
    [self.logger verbose:__FILE__ line:__LINE__ message:@"RS:%p dealloc", self];
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSString *)description {
ART_TRY_OR_REPORT_CRASH_START(self) {
    NSString *info;
    if (self.options.token) {
        info = [NSString stringWithFormat:@"token: %@", self.options.token];
    }
    else if (self.options.authUrl) {
        info = [NSString stringWithFormat:@"authUrl: %@", self.options.authUrl];
    }
    else if (self.options.authCallback) {
        info = [NSString stringWithFormat:@"authCallback: %@", self.options.authCallback];
    }
    else {
        info = [NSString stringWithFormat:@"key: %@", self.options.key];
    }
    return [NSString stringWithFormat:@"%@ - \n\t %@;", [super description], info];
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSObject<ARTCancellable> *)executeRequest:(NSMutableURLRequest *)request withAuthOption:(ARTAuthentication)authOption completion:(void (^)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable))callback {
ART_TRY_OR_REPORT_CRASH_START(self) {
    request.URL = [NSURL URLWithString:request.URL.relativeString relativeToURL:self.baseUrl];
    
    switch (authOption) {
        case ARTAuthenticationOff:
            return [self executeRequest:request completion:callback];
        case ARTAuthenticationOn:
            _tokenErrorRetries = 0;
            return [self executeRequestWithAuthentication:request withMethod:self.auth.method force:NO completion:callback];
        case ARTAuthenticationNewToken:
            _tokenErrorRetries = 0;
            return [self executeRequestWithAuthentication:request withMethod:self.auth.method force:YES completion:callback];
        case ARTAuthenticationTokenRetry:
            _tokenErrorRetries = _tokenErrorRetries + 1;
            return [self executeRequestWithAuthentication:request withMethod:self.auth.method force:YES completion:callback];
        case ARTAuthenticationUseBasic:
            return [self executeRequestWithAuthentication:request withMethod:ARTAuthMethodBasic completion:callback];
    }
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSObject<ARTCancellable> *)executeRequestWithAuthentication:(NSMutableURLRequest *)request withMethod:(ARTAuthMethod)method completion:(void (^)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable))callback {
ART_TRY_OR_REPORT_CRASH_START(self) {
    return [self executeRequestWithAuthentication:request withMethod:method force:NO completion:callback];
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSObject<ARTCancellable> *)executeRequestWithAuthentication:(NSMutableURLRequest *)request withMethod:(ARTAuthMethod)method force:(BOOL)force completion:(void (^)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable))callback {
ART_TRY_OR_REPORT_CRASH_START(self) {
    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p calculating authorization %lu", self, (unsigned long)method];
    __block NSObject<ARTCancellable> *task;

    if (method == ARTAuthMethodBasic) {
        // Basic
        NSString *authorization = [self prepareBasicAuthorisationHeader:self.options.key];
        [request setValue:authorization forHTTPHeaderField:@"Authorization"];
        [self.logger verbose:@"RS:%p ARTRest: %@", self, authorization];
        task = [self executeRequest:request completion:callback];
    }
    else {
        if (!force && [self.auth tokenRemainsValid]) {
            // Reuse token
            NSString *authorization = [self prepareTokenAuthorisationHeader:self.auth.tokenDetails.token];
            [self.logger verbose:@"RS:%p ARTRestInternal reusing token: authorization bearer in Base64 %@", self, authorization];
            [request setValue:authorization forHTTPHeaderField:@"Authorization"];
            task = [self executeRequest:request completion:callback];
        }
        else {
            // New Token
            task = [self.auth _authorize:nil options:self.options callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
                if (error) {
                    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p ARTRestInternal reissuing token failed %@", self, error];
                    if (callback) callback(nil, nil, error);
                    return;
                }
                NSString *authorization = [self prepareTokenAuthorisationHeader:tokenDetails.token];
                [self.logger verbose:@"RS:%p ARTRestInternal reissuing token: authorization bearer in Base64 %@", self, authorization];
                [request setValue:authorization forHTTPHeaderField:@"Authorization"];
                task = [self executeRequest:request completion:callback];
            }];
        }
    }
    return task;
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSObject<ARTCancellable> *)executeRequest:(NSURLRequest *)request completion:(void (^)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable))callback {
ART_TRY_OR_REPORT_CRASH_START(self) {
    return [self executeRequest:request completion:callback fallbacks:nil retries:0];
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSObject<ARTCancellable> *)executeRequest:(NSURLRequest *)request completion:(void (^)(NSHTTPURLResponse *_Nullable, NSData *_Nullable, NSError *_Nullable))callback fallbacks:(ARTFallback *)fallbacks retries:(NSUInteger)retries {
ART_TRY_OR_REPORT_CRASH_START(self) {
    __block ARTFallback *blockFallbacks = fallbacks;

    if ([request isKindOfClass:[NSMutableURLRequest class]]) {
        NSMutableURLRequest *mutableRequest = (NSMutableURLRequest *)request;
        [mutableRequest setAcceptHeader:self.defaultEncoder encoders:self.encoders];
        [mutableRequest setValue:[ARTDefault version] forHTTPHeaderField:@"X-Ably-Version"];
        [mutableRequest setValue:[ARTDefault libraryVersion] forHTTPHeaderField:@"X-Ably-Lib"];
        [mutableRequest setTimeoutInterval:_options.httpRequestTimeout];
    }

    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p executing request %@", self, request];
    __block NSObject<ARTCancellable> *task;
    task = [self.httpExecutor executeRequest:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        // Error messages in plaintext and HTML format (only if the URL request is different than `options.authUrl` and we don't have an error already)
        if (error == nil && data != nil && data.length != 0 && ![request.URL.host isEqualToString:[self.options.authUrl host]]) {
            NSString *contentType = [response.allHeaderFields objectForKey:@"Content-Type"];

            BOOL validContentType = NO;
            for (NSString *mimeType in [self->_encoders.allValues valueForKeyPath:@"mimeType"]) {
                if ([contentType containsString:mimeType]) {
                    validContentType = YES;
                    break;
                }
            }

            if (!validContentType) {
                NSString *plain = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                // Construct artificial error
                error = [ARTErrorInfo createWithCode:response.statusCode * 100 status:response.statusCode message:[plain shortString]];
                data = nil; // Discard data; format is unreliable.
                [self.logger error:@"Request %@ failed with %@", request, error];
            }
        }

        if (response.statusCode >= 400) {
            if (data) {
                NSError *decodeError = nil;
                NSError *dataError = [self->_encoders[response.MIMEType] decodeErrorInfo:data error:&decodeError];
                if ([self shouldRenewToken:&dataError] && [request isKindOfClass:[NSMutableURLRequest class]]) {
                    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p retry request %@", self, request];
                    // Make a single attempt to reissue the token and resend the request
                    if (self->_tokenErrorRetries < 1) {
                        task = [self executeRequest:(NSMutableURLRequest *)request withAuthOption:ARTAuthenticationTokenRetry completion:callback];
                        return;
                    }
                }
                if (dataError) {
                    error = dataError;
                }
                else if (decodeError) {
                    error = decodeError;
                }
            }
            if (!error) {
                // Return error with HTTP StatusCode if ARTErrorStatusCode does not exist
                error = [ARTErrorInfo createWithCode:response.statusCode*100 status:response.statusCode message:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
            }
        }
        if (retries < self->_options.httpMaxRetryCount && [self shouldRetryWithFallback:request response:response error:error]) {
            if (!blockFallbacks && [ARTFallback restShouldFallback:request.URL withOptions:self->_options]) {
                blockFallbacks = [[ARTFallback alloc] initWithOptions:self->_options];
            }
            if (blockFallbacks) {
                NSString *host = [blockFallbacks popFallbackHost];
                if (host != nil) {
                    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p host is down; retrying request at %@", self, host];
                    NSMutableURLRequest *newRequest = [request copy];
                    NSURL *url = request.URL;
                    NSString *urlStr = [NSString stringWithFormat:@"%@://%@:%@%@?%@", url.scheme, host, url.port, url.path, (url.query ? url.query : @"")];
                    newRequest.URL = [NSURL URLWithString:urlStr];
                    task = [self executeRequest:newRequest completion:callback fallbacks:blockFallbacks retries:retries + 1];
                    return;
                }
            }
        }
        if (callback) {
            // Error object that indicates why the request failed
            callback(response, data, error);
        }
    }];

    return task;
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)shouldRenewToken:(NSError **)errorPtr {
ART_TRY_OR_REPORT_CRASH_START(self) {
    if (errorPtr && *errorPtr &&
        (*errorPtr).code >= 40140 && (*errorPtr).code < 40150) {
        if ([self.auth tokenIsRenewable]) {
            return YES;
        }
        *errorPtr = (NSError *)[ARTErrorInfo createWithCode:ARTStateRequestTokenFailed message:ARTAblyMessageNoMeansToRenewToken];
    }
    return NO;
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)shouldRetryWithFallback:(NSURLRequest *)request response:(NSHTTPURLResponse *)response error:(NSError *)error {
ART_TRY_OR_REPORT_CRASH_START(self) {
    if (response.statusCode >= 500 && response.statusCode <= 504) {
        return YES;
    }
    if (error && (error.domain == NSURLErrorDomain && (
        error.code == -1003 || // Unreachable
        error.code == -1001 // timed out
    ))) {
        return YES;
    }
    return NO;
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSString *)currentHost {
ART_TRY_OR_REPORT_CRASH_START(self) {
    if (_prioritizedHost) {
        // Test purpose only
        return _prioritizedHost;
    }
    return self.options.restHost;
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSString *)prepareBasicAuthorisationHeader:(NSString *)key {
ART_TRY_OR_REPORT_CRASH_START(self) {
    // Include key Base64 encoded in an Authorization header (RFC7235)
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSString *keyBase64 = [keyData base64EncodedStringWithOptions:0];
    return [NSString stringWithFormat:@"Basic %@", keyBase64];
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSString *)prepareTokenAuthorisationHeader:(NSString *)token {
ART_TRY_OR_REPORT_CRASH_START(self) {
    NSData *tokenData = [token dataUsingEncoding:NSUTF8StringEncoding];
    NSString *tokenBase64 = [tokenData base64EncodedStringWithOptions:0];
    return [NSString stringWithFormat:@"Bearer %@", tokenBase64];
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)time:(void(^)(NSDate *time, NSError *error))callback {
    if (callback) {
        void (^userCallback)(NSDate *time, NSError *error) = callback;
        callback = ^(NSDate *time, NSError *error) {
            ART_EXITING_ABLY_CODE(self);
            dispatch_async(self->_userQueue, ^{
                userCallback(time, error);
            });
        };
    }
dispatch_async(_queue, ^{
    [self _time:callback];
});
}

- (NSObject<ARTCancellable> *)_time:(void(^)(NSDate *time, NSError *error))callback {
ART_TRY_OR_REPORT_CRASH_START(self) {
    NSURL *requestUrl = [NSURL URLWithString:@"/time" relativeToURL:self.baseUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    request.HTTPMethod = @"GET";
    NSString *accept = [[_encoders.allValues valueForKeyPath:@"mimeType"] componentsJoinedByString:@","];
    [request setValue:accept forHTTPHeaderField:@"Accept"];
    
    return [self executeRequest:request withAuthOption:ARTAuthenticationOff completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            callback(nil, error);
            return;
        }
        NSError *decodeError = nil;
        if (response.statusCode >= 400) {
            ARTErrorInfo *dataError = [self->_encoders[response.MIMEType] decodeErrorInfo:data error:&decodeError];
            callback(nil, dataError ? dataError : decodeError);
        } else {
            NSDate *time = [self->_encoders[response.MIMEType] decodeTime:data error:&decodeError];
            callback(time, decodeError);
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)request:(NSString *)method path:(NSString *)path params:(nullable NSDictionary<NSString *, NSString *> *)params body:(nullable id)body headers:(nullable NSDictionary<NSString *, NSString *> *)headers callback:(void (^)(ARTHTTPPaginatedResponse *_Nullable, ARTErrorInfo *_Nullable))callback error:(NSError *_Nullable *_Nullable)errorPtr {
ART_TRY_OR_REPORT_CRASH_START(self) {
    if (callback) {
        void (^userCallback)(ARTHTTPPaginatedResponse *, ARTErrorInfo *) = callback;
        callback = ^(ARTHTTPPaginatedResponse *r, ARTErrorInfo *e) {
            ART_EXITING_ABLY_CODE(self);
            dispatch_async(self->_userQueue, ^{
                userCallback(r, e);
            });
        };
    }

    if (![[method lowercaseString] isEqualToString:@"get"] &&
        ![[method lowercaseString] isEqualToString:@"post"] &&
        ![[method lowercaseString] isEqualToString:@"patch"] &&
        ![[method lowercaseString] isEqualToString:@"put"]) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTCustomRequestErrorInvalidMethod
                                        userInfo:@{NSLocalizedDescriptionKey:@"Method isn't valid."}];
        }
        return NO;
    }

    if (body &&
        ![body isKindOfClass:[NSDictionary class]] &&
        ![body isKindOfClass:[NSArray class]]) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTCustomRequestErrorInvalidBody
                                        userInfo:@{NSLocalizedDescriptionKey:@"Body should be a Dictionary or an Array."}];
        }
        return NO;
    }

    if ([[path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTCustomRequestErrorInvalidPath
                                        userInfo:@{NSLocalizedDescriptionKey:@"Path cannot be empty."}];
        }
        return NO;
    }

    NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseUrl];
    if (!url) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTCustomRequestErrorInvalidPath
                                        userInfo:@{NSLocalizedDescriptionKey:@"Path isn't valid for an URL."}];
        }
        return NO;
    }

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:YES];
    __block NSMutableArray<NSURLQueryItem *> *queryItems = nil;
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        if (!queryItems) {
            queryItems = [NSMutableArray new];
        }
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
    }];
    components.queryItems = queryItems;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = method;

    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [request addValue:value forHTTPHeaderField:key];
    }];

    NSError *encodeError = nil;
    NSData *bodyData = [self.defaultEncoder encode:body error:&encodeError];

    request.HTTPBody = bodyData;
    [request setValue:[self.defaultEncoder mimeType] forHTTPHeaderField:@"Content-Type"];
    if ([[method lowercaseString] isEqualToString:@"post"]) {
        [request setValue:[NSString stringWithFormat:@"%d", (unsigned int)bodyData.length] forHTTPHeaderField:@"Content-Length"];
    }

    [request setAcceptHeader:self.defaultEncoder encoders:self.encoders];

    [self.logger debug:__FILE__ line:__LINE__ message:@"request %@ %@", method, path];
    dispatch_async(_queue, ^{
        [ARTHTTPPaginatedResponse executePaginated:self withRequest:request  callback:callback];
    });
    return YES;
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSObject<ARTCancellable> *)internetIsUp:(void (^)(BOOL isUp)) cb {
    NSURL *requestUrl = [NSURL URLWithString:@"https://internet-up.ably-realtime.com/is-the-internet-up.txt"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    request.HTTPMethod = @"GET";

    return [_httpExecutor executeRequest:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            cb(NO);
            return;
        }
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        cb(response.statusCode == 200 && str && [str isEqualToString:@"yes\n"]);
    }];
}

- (BOOL)stats:(void (^)(ARTPaginatedResult<ARTStats *> *_Nullable, ARTErrorInfo *_Nullable))callback {
ART_TRY_OR_REPORT_CRASH_START(self) {
    return [self stats:[[ARTStatsQuery alloc] init] callback:callback error:nil];
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)stats:(ARTStatsQuery *)query callback:(void (^)(ARTPaginatedResult<ARTStats *> *, ARTErrorInfo *))callback error:(NSError **)errorPtr {
ART_TRY_OR_REPORT_CRASH_START(self) {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult<ARTStats *> *, ARTErrorInfo *) = callback;
        callback = ^(ARTPaginatedResult<ARTStats *> *r, ARTErrorInfo *e) {
            ART_EXITING_ABLY_CODE(self);
            dispatch_async(self->_userQueue, ^{
                userCallback(r, e);
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

    NSURLComponents *requestUrl = [NSURLComponents componentsWithString:@"/stats"];
    NSError *error = nil;
    requestUrl.queryItems = [query asQueryItems:&error];
    if (error) {
        if (errorPtr) {
            *errorPtr = error;
        }
        return NO;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[requestUrl URLRelativeToURL:self.baseUrl]];
    
    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **errorPtr) {
        return [self.encoders[response.MIMEType] decodeStats:data error:errorPtr];
    };
    
dispatch_async(_queue, ^{
    [ARTPaginatedResult executePaginated:self withRequest:request andResponseProcessor:responseProcessor callback:callback];
});
    return YES;
} ART_TRY_OR_REPORT_CRASH_END
}

- (id<ARTEncoder>)defaultEncoder {
ART_TRY_OR_REPORT_CRASH_START(self) {
    return self.encoders[self.defaultEncoding];
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSURL *)getBaseUrl {
ART_TRY_OR_REPORT_CRASH_START(self) {
    NSURLComponents *components = [_options restUrlComponents];
    NSString *prioritizedHost = self.prioritizedHost; // Important to use the property, not the variable; it's atomic!
    if (prioritizedHost) { 
        components.host = prioritizedHost;
    }
    return components.URL;
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)onUncaughtException:(NSException *)e {
    if ([e isKindOfClass:[ARTException class]]) {
        @throw e;
    }
    if (_realtime) {
        [_realtime onUncaughtException:e];
        return;
    }
    [self reportUncaughtException:e];
}

- (void)reportUncaughtException:(NSException *_Nullable)e {
    if (!_handlingUncaughtExceptions) {
        @throw e;
    }
    NSLog(@"ARTRest: uncaught exception %@\n%@", e, [e callStackSymbols]);
    [self forceReport:@"Uncaught exception" exception:e];
}

- (void)forceReport:(NSString *)message exception:(NSException *_Nullable)e {
    NSString *dns = self.options.logExceptionReportingUrl;
    if (!dns) {
        return;
    }
    [ARTSentry report:message to:dns extra:[self sentryExtra] breadcrumbs:[self sentryBreadcrumbs] tags:[self sentryTags] exception:e];
}

- (NSDictionary *)sentryExtra {
    return [KSCrash sharedInstance].userInfo[@"sentryExtra"];
}

- (NSArray<NSDictionary *> *)sentryBreadcrumbs {
    return [ARTSentry flattenBreadcrumbs:[KSCrash sharedInstance].userInfo[@"sentryBreadcrumbs"]];
}

- (NSDictionary *)sentryTags {
    return @{
        @"appId": ART_orNull(self.auth.appId),
        @"environment": self.options.environment ? self.options.environment : @"production",
    };
}

BOOL ARTstartHandlingUncaughtExceptions(ARTRestInternal *self) {
    if (!self || self->_handlingUncaughtExceptions) {
        return false;
    }
    self->_handlingUncaughtExceptions = true;
    [ARTSentry setUserInfo:@"reportToAbly" value:[NSNumber numberWithBool:true]];
    return true;
}

void ARTstopHandlingUncaughtExceptions(ARTRestInternal *self) {
    if (!self) {
        return;
    }
    self->_handlingUncaughtExceptions = false;
    [ARTSentry setUserInfo:@"reportToAbly" value:[NSNumber numberWithBool:false]];
}

#if TARGET_OS_IOS
- (ARTLocalDevice *)device {
    __block ARTLocalDevice *ret;
    dispatch_sync(_queue, ^{
        ret = [self device_nosync];
    });
    return ret;
}

// Store address of once_token to access it in debug function.
static dispatch_once_t *device_once_token;

- (ARTLocalDevice *)device_nosync {
    // The device is shared in a static variable because it's a reflection
    // of what's persisted. Having a device instance per ARTRest instance
    // could leave some instances in a stale state, if, through another
    // instance, the persisted state is changed.
    //
    // As a side effect, the first instance "wins" at setting the device's
    // client ID.

    static dispatch_once_t once;
    device_once_token = &once;
    static id device;
    dispatch_once(&once, ^{
        device = [ARTLocalDevice load:self.auth.clientId_nosync storage:self.storage];
    });
    return device;
}

- (void)resetDeviceSingleton {
    if (device_once_token) *device_once_token = 0;
}
#endif

@end
