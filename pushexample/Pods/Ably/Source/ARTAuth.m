//
//  ARTAuth.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTAuth+Private.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "ARTRest+Private.h"
#import "ARTHttp.h"
#import "ARTClientOptions.h"
#import "ARTAuthOptions.h"
#import "ARTTokenDetails.h"
#import "ARTTokenParams+Private.h"
#import "ARTTokenRequest.h"
#import "ARTEncoder.h"
#import "ARTStatus.h"
#import "ARTJsonEncoder.h"
#import "ARTGCD.h"
#import "ARTEventEmitter+Private.h"

@implementation ARTAuth {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTAuthInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (void)internalAsync:(void (^)(ARTAuthInternal * _Nonnull))use {
    dispatch_async(_internal.queue, ^{
        use(self->_internal);
    });
}

- (NSString *)clientId {
    return _internal.clientId;
}

- (ARTTokenDetails *)tokenDetails {
    return _internal.tokenDetails;
}

- (void)requestToken:(nullable ARTTokenParams *)tokenParams withOptions:(nullable ARTAuthOptions *)authOptions
            callback:(void (^)(ARTTokenDetails *_Nullable, NSError *_Nullable))callback {
    [_internal requestToken:tokenParams withOptions:authOptions callback:callback];
}

- (void)requestToken:(void (^)(ARTTokenDetails *_Nullable, NSError *_Nullable))callback {
    [_internal requestToken:callback];
}

- (void)authorize:(nullable ARTTokenParams *)tokenParams options:(nullable ARTAuthOptions *)authOptions
         callback:(void (^)(ARTTokenDetails *_Nullable, NSError *_Nullable))callback {
    [_internal authorize:tokenParams options:authOptions callback:callback];
}

- (void)authorize:(void (^)(ARTTokenDetails *_Nullable, NSError *_Nullable))callback {
    [_internal authorize:callback];
}

- (void)createTokenRequest:(nullable ARTTokenParams *)tokenParams options:(nullable ARTAuthOptions *)options
                  callback:(void (^)(ARTTokenRequest *_Nullable tokenRequest, NSError *_Nullable error))callback {
    [_internal createTokenRequest:tokenParams options:options callback:callback];
}

- (void)createTokenRequest:(void (^)(ARTTokenRequest *_Nullable tokenRequest, NSError *_Nullable error))callback {
    [_internal createTokenRequest:callback];
}

@end

@implementation ARTAuthInternal {
    __weak ARTRestInternal *_rest; // weak because rest owns auth
    dispatch_queue_t _userQueue;
    ARTTokenParams *_tokenParams;
    // Dedicated to Protocol Message
    NSString *_protocolClientId;
    NSInteger _authorizationsCount;
    ARTEventEmitter<ARTEvent *, ARTErrorInfo *> *_cancelationEventEmitter;
}

- (instancetype)init:(ARTRestInternal *)rest withOptions:(ARTClientOptions *)options {
ART_TRY_OR_REPORT_CRASH_START(rest) {
    if (self = [super init]) {
        _rest = rest;
        _userQueue = rest.userQueue;
        _queue = rest.queue;
        _tokenDetails = options.tokenDetails;
        _options = options;
        _logger = rest.logger;
        _protocolClientId = nil;
        _cancelationEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:_rest.queue];
        _tokenParams = options.defaultTokenParams ? : [[ARTTokenParams alloc] initWithOptions:self.options];
        _authorizationsCount = 0;
        [self validate:options];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveCurrentLocaleDidChangeNotification:)
                                                     name:NSCurrentLocaleDidChangeNotification
                                                   object:nil];

        #if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveApplicationSignificantTimeChangeNotification:)
                                                     name:UIApplicationSignificantTimeChangeNotification
                                                   object:nil];
        #else
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveApplicationSignificantTimeChangeNotification:)
                                                     name:NSSystemClockDidChangeNotification
                                                   object:nil];
        #endif
    }
    return self;
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)dealloc {
    [self removeTimeOffsetObserver];
}

- (void)removeTimeOffsetObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSCurrentLocaleDidChangeNotification object:nil];
    #if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationSignificantTimeChangeNotification object:nil];
    #else
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSSystemClockDidChangeNotification object:nil];
    #endif
}

- (void)didReceiveCurrentLocaleDidChangeNotification:(NSNotification *)notification {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p NSCurrentLocaleDidChangeNotification received", _rest];
    [self discardTimeOffset];
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)didReceiveApplicationSignificantTimeChangeNotification:(NSNotification *)notification {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p UIApplicationSignificantTimeChangeNotification received", _rest];
    [self discardTimeOffset];
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)validate:(ARTClientOptions *)options {
    // Only called from constructor, no need to synchronize.
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p validating %@", _rest, options];
    if ([options isBasicAuth]) {
        if (!options.tls) {
            [ARTException raise:@"ARTAuthException" format:@"Basic authentication only connects over HTTPS (tls)."];
        }
        // Basic
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p setting up auth method Basic (anonymous)", _rest];
        _method = ARTAuthMethodBasic;
    } else if (options.tokenDetails) {
        // TokenDetails
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p setting up auth method Token with token details", _rest];
        _method = ARTAuthMethodToken;
    } else if (options.token) {
        // Token
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p setting up auth method Token with supplied token only", _rest];
        _method = ARTAuthMethodToken;
        options.tokenDetails = [[ARTTokenDetails alloc] initWithToken:options.token];
    } else if (options.authUrl && options.authCallback) {
        [ARTException raise:@"ARTAuthException" format:@"Incompatible authentication configuration: please specify either authCallback and authUrl."];
    } else if (options.authUrl) {
        // Authentication url
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p setting up auth method Token with authUrl", _rest];
        _method = ARTAuthMethodToken;
    } else if (options.authCallback) {
        // Authentication callback
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p setting up auth method Token with authCallback", _rest];
        _method = ARTAuthMethodToken;
    } else if (options.key) {
        // Token
        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p setting up auth method Token with key", _rest];
        _method = ARTAuthMethodToken;
    } else {
        [ARTException raise:@"ARTAuthException" format:@"Could not setup authentication method with given options."];
    }
    
    if ([options.clientId isEqual:@"*"]) {
        [ARTException raise:@"ARTAuthException" format:@"Invalid clientId: cannot contain only a wilcard \"*\"."];
    }
} ART_TRY_OR_REPORT_CRASH_END
}

- (ARTAuthOptions *)mergeOptions:(ARTAuthOptions *)customOptions {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return customOptions ? [self.options mergeWith:customOptions] : self.options;
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)storeOptions:(ARTAuthOptions *)customOptions {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    self.options.key = customOptions.key;
    self.options.tokenDetails = [customOptions.tokenDetails copy];
    self.options.authCallback = [customOptions.authCallback copy];
    self.options.authUrl = [customOptions.authUrl copy];
    self.options.authHeaders = [customOptions.authHeaders copy];
    self.options.authMethod = customOptions.authMethod;
    self.options.authParams = [customOptions.authParams copy];
    self.options.useTokenAuth = customOptions.useTokenAuth;
    self.options.queryTime = false;
} ART_TRY_OR_REPORT_CRASH_END
}

- (ARTTokenParams *)mergeParams:(ARTTokenParams *)customParams {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return customParams ? customParams : [[ARTTokenParams alloc] initWithOptions:self.options];
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)storeParams:(ARTTokenParams *)customOptions {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    _options.clientId = customOptions.clientId;
    _options.defaultTokenParams = customOptions;
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSURL *)buildURL:(ARTAuthOptions *)options withParams:(ARTTokenParams *)params {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:options.authUrl resolvingAgainstBaseURL:YES];

    if ([options isMethodGET]) {
        // TokenParams take precedence over any configured authParams when a name conflict occurs
        NSArray *unitedParams = [params toArrayWithUnion:options.authParams];
        // When GET, use query string params
        if (!urlComponents.queryItems) {
            urlComponents.queryItems = @[];
        }
        urlComponents.queryItems = [urlComponents.queryItems arrayByAddingObjectsFromArray:unitedParams];
    }

    urlComponents.queryItems = [urlComponents.queryItems arrayByAddingObjectsFromArray:@[[NSURLQueryItem queryItemWithName:@"format" value:[_rest.defaultEncoder formatAsString]]]];

    // (Known '+' sign pitfall https://developer.apple.com/documentation/foundation/nsurlcomponents/1407752-queryitems?language=objc)
    // Apple's Response:
    // The '+' character is legal in the query component so it does not need to be percent-encoded.
    // Some systems use the '+' as a space and require '+' the plus character to be percent-encoded. However, that kind of two stage encoding (converting plus sign to %2B and then converting space to plus sign) is prone to errors because it easily leads to encoding problems. It also breaks if the URL is normalized (syntax normalization of URLs includes the removal of all unnecessary percent-encoding -- see rfc3986 section 6.2.2.2).
    // So, if you need that behavior because of the server your code is talking to, you'll handle that extra transformation(s) yourself.
    // Reference: "NSURLComponents does not correctly handle "+" usage in query parameters." http://www.openradar.me/24076063
    [urlComponents setPercentEncodedQuery:[[urlComponents percentEncodedQuery]
                                            // manually encode '+' into percent encoding
                                            stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"]];

    return urlComponents.URL;
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSMutableURLRequest *)buildRequest:(ARTAuthOptions *)options withParams:(ARTTokenParams *)params {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSURL *url = [self buildURL:options withParams:params];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = options.authMethod;

    // HTTP Header Fields
    if ([options isMethodPOST]) {
        // TokenParams take precedence over any configured authParams when a name conflict occurs
        NSDictionary *unitedParams = [params toDictionaryWithUnion:options.authParams];
        // When POST, use body of the POST request
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:unitedParams options:0 error:nil];
        request.HTTPBody = bodyData;
        [request setValue:[_rest.defaultEncoder mimeType] forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d", (unsigned int)bodyData.length] forHTTPHeaderField:@"Content-Length"];
    }
    else {
        [request setValue:[_rest.defaultEncoder mimeType] forHTTPHeaderField:@"Accept"];
    }

    for (NSString *key in options.authHeaders) {
        [request setValue:options.authHeaders[key] forHTTPHeaderField:key];
    }

    return request;
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)tokenIsRenewable {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return [self canRenewTokenAutomatically:self.options];
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)canRenewTokenAutomatically:(ARTAuthOptions *)options {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return options.authCallback || options.authUrl || options.key;
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)tokenRemainsValid {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    if (self.tokenDetails && self.tokenDetails.token) {
        if (self.tokenDetails.expires == nil) {
            return YES;
        }
        else if (![self hasTimeOffset] || [self.tokenDetails.expires timeIntervalSinceDate:[self currentDate]] > 0) {
            return YES;
        }
    }
    return NO;
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)requestToken:(void (^)(ARTTokenDetails *, NSError *))callback {
    // If the object arguments are omitted, the client library configured defaults are used
    [self requestToken:_tokenParams withOptions:_options callback:callback];
}

- (void)requestToken:(ARTTokenParams *)tokenParams withOptions:(ARTAuthOptions *)authOptions callback:(void (^)(ARTTokenDetails *, NSError *))callback {
    if (callback) {
        void (^userCallback)(ARTTokenDetails *, NSError *) = callback;
        callback = ^(ARTTokenDetails *t, NSError *e) {
            ART_EXITING_ABLY_CODE(self->_rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(t, e);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(self->_rest) {
    [self _requestToken:tokenParams withOptions:authOptions callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (NSObject<ARTCancellable> *)_requestToken:(ARTTokenParams *)tokenParams withOptions:(ARTAuthOptions *)authOptions callback:(void (^)(ARTTokenDetails *, NSError *))callback {
    // If options, params passed in, they're used instead of stored, don't merge them
    ARTAuthOptions *replacedOptions = authOptions ? authOptions : self.options;
    ARTTokenParams *currentTokenParams = [tokenParams ? tokenParams : _tokenParams copy];
    currentTokenParams.timestamp = [self currentDate];
    __block NSObject<ARTCancellable> *task;

    if (![self canRenewTokenAutomatically:replacedOptions]) {
        callback(nil, [ARTErrorInfo createWithCode:ARTStateRequestTokenFailed message:ARTAblyMessageNoMeansToRenewToken]);
        return nil;
    }

    void (^checkerCallback)(ARTTokenDetails *_Nullable, NSError *_Nullable) = ^(ARTTokenDetails *tokenDetails, NSError *error) {
        if (error) {
            if (error.code == NSURLErrorTimedOut) {
                ARTErrorInfo *ablyError = [ARTErrorInfo createWithCode:40170 message:@"Error in requesting auth token"];
                callback(nil, ablyError);
                return;
            }
            callback(nil, error);
            return;
        }
        if (self.clientId_nosync && tokenDetails.clientId && ![tokenDetails.clientId isEqualToString:@"*"] && ![self.clientId_nosync isEqual:tokenDetails.clientId]) {
            if (callback) callback(nil, [ARTErrorInfo createWithCode:40102 message:@"incompatible credentials"]);
            return;
        }
        callback(tokenDetails, nil);
    };

    if (replacedOptions.authUrl) {
        NSMutableURLRequest *request = [self buildRequest:replacedOptions withParams:currentTokenParams];

        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p using authUrl (%@ %@)", _rest, request.HTTPMethod, request.URL];

        task = [_rest executeRequest:request withAuthOption:ARTAuthenticationOff completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
            if (error) {
                checkerCallback(nil, error);
            } else {
                [self.logger debug:@"RS:%p ARTAuth: authUrl response %@", self->_rest, response];
                [self handleAuthUrlResponse:response withData:data completion:checkerCallback];
            }
        }];
    } else {
        void (^tokenDetailsFactory)(ARTTokenParams *, void(^)(ARTTokenDetails *_Nullable, NSError *_Nullable));
        if (replacedOptions.authCallback) {
            void (^userCallback)(ARTTokenParams *, void(^)(id<ARTTokenDetailsCompatible>, NSError *)) = ^(ARTTokenParams *tokenParams, void(^callback)(id<ARTTokenDetailsCompatible>, NSError *)){
                ART_EXITING_ABLY_CODE(self->_rest);
                dispatch_async(self->_userQueue, ^{
                    replacedOptions.authCallback(tokenParams, callback);
                });
            };

            tokenDetailsFactory = ^(ARTTokenParams *tokenParams, void(^callback)(ARTTokenDetails *_Nullable, NSError *_Nullable)) {
                userCallback(tokenParams, ^(id<ARTTokenDetailsCompatible> tokenDetailsCompat, NSError *error) {
                    dispatch_async(self->_queue, ^{
                    ART_TRY_OR_REPORT_CRASH_START(self->_rest) {
                        if (error) {
                            callback(nil, error);
                        } else {
                            [tokenDetailsCompat toTokenDetails:[self toAuth] callback:callback];
                        }
                    } ART_TRY_OR_REPORT_CRASH_END
                    });
                });
            };
            [self.logger debug:@"RS:%p ARTAuth: using authCallback", _rest];
        } else {
            tokenDetailsFactory = ^(ARTTokenParams *tokenParams, void(^callback)(ARTTokenDetails *_Nullable, NSError *_Nullable)) {
                // Create a TokenRequest and execute it
                NSObject<ARTCancellable> *timeTask;
                timeTask = [self _createTokenRequest:currentTokenParams options:replacedOptions callback:^(ARTTokenRequest *tokenRequest, NSError *error) {
                    if (error) {
                        callback(nil, error);
                    } else {
                        task = [self executeTokenRequest:tokenRequest callback:callback];
                    }
                }];
                if (timeTask) {
                    task = timeTask;
                }
            };
        };

        tokenDetailsFactory(currentTokenParams, checkerCallback);
    }

    return task;
}

- (ARTAuth *)toAuth {
    // This feels hackish, but the alternative would be to change
    // ARTTokenDetailsCompatible to take a ARTAuthProtocol so we can just
    // pass self, but that would
    // break backwards-compatibility for users that have their own
    // ARTTokenDetailsCompatible implementations.
    ARTQueuedDealloc *dealloc = [[ARTQueuedDealloc alloc] init:self->_rest queue: self->_queue];
    return [[ARTAuth alloc] initWithInternal:self queuedDealloc:dealloc];
}

- (void)handleAuthUrlResponse:(NSHTTPURLResponse *)response withData:(NSData *)data completion:(void (^)(ARTTokenDetails *, NSError *))callback {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    // The token retrieved is assumed by the library to be a token string if the response has Content-Type "text/plain", or taken to be a TokenRequest or TokenDetails object if the response has Content-Type "application/json"
    if ([response.MIMEType isEqualToString:@"application/json"]) {
        NSError *decodeError = nil;
        ARTTokenDetails *tokenDetails = [_rest.encoders[@"application/json"] decodeTokenDetails:data error:&decodeError];
        if (decodeError) {
            callback(nil, decodeError);
        } else if (tokenDetails.token == nil) {
            ARTTokenRequest *tokenRequest = [_rest.encoders[@"application/json"] decodeTokenRequest:data error:&decodeError];
            if (decodeError) {
                callback(nil, decodeError);
            } else if (tokenRequest) {
                [tokenRequest toTokenDetails:[self toAuth] callback:callback];
            } else {
                callback(nil, [ARTErrorInfo createWithCode:ARTStateAuthUrlIncompatibleContent message:@"content response cannot be used for token request"]);
            }
        } else {
            callback(tokenDetails, nil);
        }
    }
    else if ([response.MIMEType isEqualToString:@"text/plain"] || [response.MIMEType isEqualToString:@"application/jwt"]) {
        NSString *token = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([token isEqualToString:@""]) {
            callback(nil, [NSError errorWithDomain:ARTAblyErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:@"authUrl: token is empty"}]);
            return;
        }
        ARTTokenDetails *tokenDetails = [[ARTTokenDetails alloc] initWithToken:token];
        callback(tokenDetails, nil);
    }
    else {
        callback(nil, [NSError errorWithDomain:ARTAblyErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:@"authUrl: invalid MIME type"}]);
    }
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSObject<ARTCancellable> *)executeTokenRequest:(ARTTokenRequest *)tokenRequest callback:(void (^)(ARTTokenDetails *, NSError *))callback {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    id<ARTEncoder> encoder = _rest.defaultEncoder;

    NSURL *requestUrl = [NSURL URLWithString:[NSString stringWithFormat:@"/keys/%@/requestToken?format=%@", tokenRequest.keyName, [encoder formatAsString]]
                               relativeToURL:_rest.baseUrl];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    request.HTTPMethod = @"POST";

    NSError *encodeError = nil;
    request.HTTPBody = [encoder encodeTokenRequest:tokenRequest error:&encodeError];
    if (encodeError) {
        callback(nil, encodeError);
        return nil;
    }
    [request setValue:[encoder mimeType] forHTTPHeaderField:@"Accept"];
    [request setValue:[encoder mimeType] forHTTPHeaderField:@"Content-Type"];

    return [_rest executeRequest:request withAuthOption:ARTAuthenticationOff completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            callback(nil, error);
        } else {
            NSError *decodeError = nil;
            ARTTokenDetails *tokenDetails = [encoder decodeTokenDetails:data error:&decodeError];
            if (decodeError) {
                callback(nil, decodeError);
            } else {
                callback(tokenDetails, nil);
            }
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)authorizing {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    __block NSInteger count;
    dispatch_sync(_queue, ^{
        count = self->_authorizationsCount;
    });
    return count > 0;
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)authorizing_nosync {
    return _authorizationsCount > 0;
}

- (void)authorize:(void (^)(ARTTokenDetails *, NSError *))callback {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    [self authorize:_options.defaultTokenParams options:_options callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)authorize:(ARTTokenParams *)tokenParams options:(ARTAuthOptions *)authOptions callback:(void (^)(ARTTokenDetails *, NSError *))callback {
    if (callback) {
        void (^userCallback)(ARTTokenDetails *, NSError *) = callback;
        callback = ^(ARTTokenDetails *t, NSError *e) {
            ART_EXITING_ABLY_CODE(self->_rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(t, e);
            });
        };
    }

dispatch_async(_queue, ^{
    [self _authorize:tokenParams options:authOptions callback:callback];
});
}

- (nullable NSObject<ARTCancellable> *)_authorize:(ARTTokenParams *)tokenParams options:(ARTAuthOptions *)authOptions callback:(void (^)(ARTTokenDetails *, NSError *))callback {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    ARTAuthOptions *replacedOptions = [authOptions copy] ? : [self.options copy];
    [self storeOptions:replacedOptions];

    ARTTokenParams *currentTokenParams = [self mergeParams:tokenParams];
    [self storeParams:currentTokenParams];

    __weak id<ARTAuthDelegate> lastDelegate = self.delegate;

    NSString *authorizeId = [[NSUUID new] UUIDString];
    // Request always a new token
    [self.logger verbose:@"RS:%p ARTAuthInternal [authorize.%@, delegate=%@]: requesting new token", _rest, authorizeId, lastDelegate ? @"YES" : @"NO"];
    NSObject<ARTCancellable> *task;
    self->_authorizationsCount += 1;
    task = [self _requestToken:currentTokenParams withOptions:replacedOptions callback:^(ARTTokenDetails *tokenDetails, NSError *error) {
        self->_authorizationsCount -= 1;

        void (^successBlock)(void) = ^{
            [self.logger verbose:@"RS:%p ARTAuthInternal [authorize.%@]: success callback: %@", self->_rest, authorizeId, tokenDetails];
            if (callback) {
                callback(tokenDetails, nil);
            }
        };

        void (^failureBlock)(NSError *) = ^(NSError *error) {
            [self.logger verbose:@"RS:%p ARTAuthInternal [authorize.%@]: failure callback: %@ with token details %@", self->_rest, authorizeId, error, tokenDetails];
            if (callback) {
                callback(tokenDetails, error);
            }
        };

        if (error) {
            [self.logger debug:@"RS:%p ARTAuthInternal [authorize.%@]: token request failed: %@", self->_rest, authorizeId, error];
            failureBlock(error);
            return;
        }

        [self.logger debug:@"RS:%p ARTAuthInternal [authorize.%@]: token request succeeded: %@", self->_rest, authorizeId, tokenDetails];

        [self setTokenDetails:tokenDetails];
        self->_method = ARTAuthMethodToken;

        if (!tokenDetails) {
            failureBlock([ARTErrorInfo createWithCode:0 message:@"Token details are empty"]);
        }
        else if (lastDelegate) {
            [lastDelegate auth:self didAuthorize:tokenDetails completion:^(ARTAuthorizationState state, ARTErrorInfo *error) {
                switch (state) {
                    case ARTAuthorizationSucceeded:
                        successBlock();
                        [self setTokenDetails:tokenDetails];
                        break;
                    case ARTAuthorizationFailed:
                        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p authorization failed with \"%@\" but the request token has already completed", self->_rest, error];
                        failureBlock(error);
                        [self setTokenDetails:nil];
                        break;
                    case ARTAuthorizationCancelled: {
                        NSError *cancelled = [ARTErrorInfo createWithCode:kCFURLErrorCancelled message:@"Authorization has been cancelled"];
                        [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p authorization cancelled but the request token has already completed", self->_rest];
                        failureBlock(cancelled);
                        [self setTokenDetails:tokenDetails];
                        break;
                    }
                }
            }];
        }
        else {
            successBlock();
        }
    }];

    [_cancelationEventEmitter once:^(ARTErrorInfo * _Nullable error) {
        [task cancel];
    }];

    return task;
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)cancelAuthorization:(nullable ARTErrorInfo *)error {
    [self.logger debug:__FILE__ line:__LINE__ message:@"RS:%p authorization cancelled with %@", self->_rest, error];
    [_cancelationEventEmitter emit:nil with:error];
}

- (void)createTokenRequest:(void (^)(ARTTokenRequest *, NSError *))callback {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    [self createTokenRequest:_tokenParams options:_options callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)createTokenRequest:(ARTTokenParams *)tokenParams options:(ARTAuthOptions *)options callback:(void (^)(ARTTokenRequest *, NSError *))callback {
    if (callback) {
        void (^userCallback)(ARTTokenRequest *, NSError *) = callback;
        callback = ^(ARTTokenRequest *t, NSError *e) {
            ART_EXITING_ABLY_CODE(self->_rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(t, e);
            });
        };
    }

dispatch_async(_queue, ^{
    [self _createTokenRequest:tokenParams options:options callback:callback];
});
}

- (NSObject<ARTCancellable> *)_createTokenRequest:(ARTTokenParams *)tokenParams options:(ARTAuthOptions *)options callback:(void (^)(ARTTokenRequest *, NSError *))callback {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    ARTAuthOptions *replacedOptions = options ? : self.options;
    ARTTokenParams *currentTokenParams = tokenParams ? : [_tokenParams copy]; // copy since _tokenParams should be read-only
    currentTokenParams.timestamp = [self currentDate];

    if (currentTokenParams.capability) {
        // Validate: Capability JSON text
        NSError *errorCapability = nil;
        
        [NSJSONSerialization JSONObjectWithData:[currentTokenParams.capability dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&errorCapability];

        if (errorCapability) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Capability: %@", errorCapability.localizedDescription] };
            callback(nil, [NSError errorWithDomain:ARTAblyErrorDomain code:errorCapability.code userInfo:userInfo]);
            return nil;
        }
    }

    if (replacedOptions.key == nil) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : @"no key provided for signing token requests" };
        callback(nil, [NSError errorWithDomain:ARTAblyErrorDomain code:0 userInfo:userInfo]);
        return nil;
    }

    if ([self hasTimeOffsetWithValue] && !replacedOptions.queryTime) {
        currentTokenParams.timestamp = [self currentDate];
        callback([currentTokenParams sign:replacedOptions.key], nil);
        return nil;
    }
    else {
        if (replacedOptions.queryTime) {
            return [_rest _time:^(NSDate *time, NSError *error) {
                if (error) {
                    callback(nil, error);
                } else {
                    NSDate *serverTime = [self handleServerTime:time];
                    self->_timeOffset = @([serverTime timeIntervalSinceNow]);
                    currentTokenParams.timestamp = serverTime;
                    callback([currentTokenParams sign:replacedOptions.key], nil);
                }
            }];
        } else {
            callback([currentTokenParams sign:replacedOptions.key], nil);
            return nil;
        }
    }
} ART_TRY_OR_REPORT_CRASH_END
}

// For mocking when testing.
- (NSDate *)handleServerTime:(NSDate *)time {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return time;
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)setProtocolClientId:(NSString *)clientId {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    _protocolClientId = clientId;
    #if TARGET_OS_IOS
    [self setLocalDeviceClientId_nosync:_protocolClientId];
    #endif
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSString *)clientId {
    __block NSString *clientId;
dispatch_sync(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(self->_rest) {
    clientId = self.clientId_nosync;
} ART_TRY_OR_REPORT_CRASH_END
});
    return clientId;
}

- (NSString *)clientId_nosync {
    if (_protocolClientId) {
        return _protocolClientId;
    }
    else if (self.tokenDetails && self.tokenDetails.clientId) {
        return self.tokenDetails.clientId;
    }
    else {
        return self.options.clientId;
    }
}

- (NSDate *)currentDate {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    return [[NSDate date] dateByAddingTimeInterval:_timeOffset.doubleValue];
} ART_TRY_OR_REPORT_CRASH_END
}

- (BOOL)hasTimeOffset {
    return _timeOffset != nil;
}

- (BOOL)hasTimeOffsetWithValue {
    return _timeOffset != nil && _timeOffset.doubleValue > 0;
}

- (void)discardTimeOffset {
    // This may run after dealloc has been called in _rest. I've seen this
    // happen when rest.auth is put in a variable, even if (apparently) that
    // variable doesn't outlive rest! See commit 5a354524 for a reproducible
    // example, by running the Auth.swift tests. Instruments reports a memory
    // leak, but I wasn't able to get to why it happens after a full day. So
    // I'm just adding this check.
    if (!_rest) {
        [self removeTimeOffsetObserver];
        return;
    }

// Called from NSNotificationCenter, so must put change in the queue.
dispatch_sync(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(self->_rest) {
    [self clearTimeOffset];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)setTokenDetails:(ARTTokenDetails *)tokenDetails {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    _tokenDetails = tokenDetails;
    #if TARGET_OS_IOS
    [self setLocalDeviceClientId_nosync:tokenDetails.clientId];
    #endif
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)setTimeOffset:(NSTimeInterval)offset {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    _timeOffset = @(offset);
} ART_TRY_OR_REPORT_CRASH_END
}

- (void)clearTimeOffset; {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    _timeOffset = nil;
} ART_TRY_OR_REPORT_CRASH_END
}

- (NSString *_Nullable)appId {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    NSString *s = nil;
    if (_options.key) {
        s = _options.key;
    } else if (_options.token) {
        s = _options.token;
    } else if (_tokenDetails) {
        s = _tokenDetails.token;
    }
    if (!s) {
        return nil;
    }
    NSArray<NSString *> *parts = [s componentsSeparatedByString:@"."];
    if (parts.count < 2) {
        return nil;
    }
    return parts[0];
} ART_TRY_OR_REPORT_CRASH_END
}

#if TARGET_OS_IOS
- (void)setLocalDeviceClientId_nosync:(NSString *)clientId {
ART_TRY_OR_REPORT_CRASH_START(_rest) {
    if (clientId && ![clientId isEqualToString:@"*"]) {
        [_rest.device_nosync setClientId:clientId];
    }
} ART_TRY_OR_REPORT_CRASH_END
}
#endif

@end

@implementation NSString (ARTTokenDetailsCompatible)

- (void)toTokenDetails:(ARTAuth *)auth callback:(void (^)(ARTTokenDetails * _Nullable, NSError * _Nullable))callback {
    callback([[ARTTokenDetails alloc] initWithToken:self], nil);
}

@end

NSString *ARTAuthorizationStateToStr(ARTAuthorizationState state) {
    switch (state) {
        case ARTAuthorizationSucceeded:
            return @"Succeeded"; //0
        case ARTAuthorizationFailed:
            return @"Failed"; //1
        case ARTAuthorizationCancelled:
            return @"Cancelled"; //2
    }
}

#pragma mark - ARTEvent

@implementation ARTEvent (AuthorizationState)

- (instancetype)initWithAuthorizationState:(ARTAuthorizationState)value {
    return [self initWithString:[NSString stringWithFormat:@"ARTAuthorizationState%@", ARTAuthorizationStateToStr(value)]];
}

+ (instancetype)newWithAuthorizationState:(ARTAuthorizationState)value {
    return [[self alloc] initWithAuthorizationState:value];
}

@end
