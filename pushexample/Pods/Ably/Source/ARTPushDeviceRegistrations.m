//
//  ARTPushDeviceRegistrations.m
//  Ably
//
//  Created by Ricardo Pereira on 20/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushDeviceRegistrations+Private.h"
#import "ARTHttp.h"
#import "ARTLog.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTDeviceDetails.h"
#import "ARTDevicePushDetails.h"
#import "ARTDeviceIdentityTokenDetails.h"
#import "ARTClientOptions.h"
#import "ARTEncoder.h"
#import "ARTRest+Private.h"
#import "ARTLocalDevice.h"
#import "ARTNSMutableRequest+ARTPush.h"

@implementation ARTPushDeviceRegistrations {
    ARTQueuedDealloc *_dealloc;
}

- (instancetype)initWithInternal:(ARTPushDeviceRegistrationsInternal *)internal queuedDealloc:(ARTQueuedDealloc *)dealloc {
    self = [super init];
    if (self) {
        _internal = internal;
        _dealloc = dealloc;
    }
    return self;
}

- (void)save:(ARTDeviceDetails *)deviceDetails callback:(void (^)(ARTErrorInfo *_Nullable))callback {
    [_internal save:deviceDetails callback:callback];
}

- (void)get:(ARTDeviceId *)deviceId callback:(void (^)(ARTDeviceDetails *_Nullable,  ARTErrorInfo *_Nullable))callback {
    [_internal get:deviceId callback:callback];
}

- (void)list:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTPaginatedResult<ARTDeviceDetails *> *_Nullable,  ARTErrorInfo *_Nullable))callback {
    [_internal list:params callback:callback];
}

- (void)remove:(NSString *)deviceId callback:(void (^)(ARTErrorInfo *_Nullable))callback {
    [_internal remove:deviceId callback:callback];
}

- (void)removeWhere:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTErrorInfo *_Nullable))callback {
    [_internal removeWhere:params callback:callback];
}

@end

@implementation ARTPushDeviceRegistrationsInternal {
    __weak ARTRestInternal *_rest; // weak because rest owns self
    ARTLog* _logger;
    dispatch_queue_t _queue;
    dispatch_queue_t _userQueue;
}

- (instancetype)initWithRest:(ARTRestInternal *)rest {
    if (self = [super init]) {
        _rest = rest;
        _logger = [rest logger];
        _queue = rest.queue;
        _userQueue = rest.userQueue;
    }
    return self;
}

- (void)save:(ARTDeviceDetails *)deviceDetails callback:(void (^)(ARTErrorInfo *error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *error) = callback;
        callback = ^(ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(self->_rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

    #if TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device;
    #else
    ARTLocalDevice *local = nil;
    #endif

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(self->_rest) {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[[NSURL URLWithString:@"/push/deviceRegistrations"] URLByAppendingPathComponent:deviceDetails.id] resolvingAgainstBaseURL:NO];
    if (self->_rest.options.pushFullWait) {
        components.queryItems = @[[NSURLQueryItem queryItemWithName:@"fullWait" value:@"true"]];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = [[self->_rest defaultEncoder] encodeDeviceDetails:deviceDetails error:nil];
    [request setValue:[[self->_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];
    [request setDeviceAuthentication:deviceDetails.id localDevice:local logger:self->_logger];

    [self->_logger debug:__FILE__ line:__LINE__ message:@"save device with request %@", request];
    [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            NSError *decodeError = nil;
            ARTDeviceDetails *deviceDetails = [[self->_rest defaultEncoder] decodeDeviceDetails:data error:&decodeError];
            if (decodeError) {
                [self->_logger debug:__FILE__ line:__LINE__ message:@"%@: decode device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
                callback([ARTErrorInfo createFromNSError:decodeError]);
            }
            else {
                [self->_logger debug:__FILE__ line:__LINE__ message:@"%@: successfully saved device %@", NSStringFromClass(self.class), deviceDetails.id];
                callback(nil);
            }
        }
        else if (error) {
            [self->_logger error:@"%@: save device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            callback([ARTErrorInfo createFromNSError:error]);
        }
        else {
            [self->_logger error:@"%@: save device failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
            NSString *plain = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            callback([ARTErrorInfo createWithCode:response.statusCode*100 status:response.statusCode message:[plain shortString]]);
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)get:(ARTDeviceId *)deviceId callback:(void (^)(ARTDeviceDetails *, ARTErrorInfo *))callback {
    if (callback) {
        void (^userCallback)(ARTDeviceDetails *, ARTErrorInfo *error) = callback;
        callback = ^(ARTDeviceDetails *device, ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(self->_rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(device, error);
            });
        };
    }

    #if TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device;
    #else
    ARTLocalDevice *local = nil;
    #endif

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(self->_rest) {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[[NSURL URLWithString:@"/push/deviceRegistrations"] URLByAppendingPathComponent:deviceId]];
    request.HTTPMethod = @"GET";
    [request setDeviceAuthentication:deviceId localDevice:local logger:self->_logger];

    [self->_logger debug:__FILE__ line:__LINE__ message:@"get device with request %@", request];
    [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*OK*/) {
            NSError *decodeError = nil;
            ARTDeviceDetails *device = [self->_rest.encoders[response.MIMEType] decodeDeviceDetails:data error:&decodeError];
            if (decodeError) {
                [self->_logger debug:__FILE__ line:__LINE__ message:@"%@: decode device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
                callback(nil, [ARTErrorInfo createFromNSError:decodeError]);
            }
            else if (device) {
                [self->_logger debug:__FILE__ line:__LINE__ message:@"%@: get device successfully", NSStringFromClass(self.class)];
                callback(device, nil);
            }
            else {
                [self->_logger debug:__FILE__ line:__LINE__ message:@"%@: get device failed with unknown error", NSStringFromClass(self.class)];
                callback(nil, [ARTErrorInfo createUnknownError]);
            }
        }
        else if (error) {
            [self->_logger error:@"%@: get device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            callback(nil, [ARTErrorInfo createFromNSError:error]);
        }
        else {
            [self->_logger error:@"%@: get device failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
            NSString *plain = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            callback(nil, [ARTErrorInfo createWithCode:response.statusCode*100 status:response.statusCode message:[plain shortString]]);
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)list:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTPaginatedResult<ARTDeviceDetails *> *result, ARTErrorInfo *error))callback {
    if (callback) {
        void (^userCallback)(ARTPaginatedResult *, ARTErrorInfo *error) = callback;
        callback = ^(ARTPaginatedResult *result, ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(self->_rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(result, error);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(self->_rest) {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"] resolvingAgainstBaseURL:NO];
    components.queryItems = [params asURLQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"GET";

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **error) {
        return [self->_rest.encoders[response.MIMEType] decodeDevicesDetails:data error:error];
    };
    [ARTPaginatedResult executePaginated:self->_rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)remove:(NSString *)deviceId callback:(void (^)(ARTErrorInfo *error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *error) = callback;
        callback = ^(ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(self->_rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(self->_rest) {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[[NSURL URLWithString:@"/push/deviceRegistrations"] URLByAppendingPathComponent:deviceId] resolvingAgainstBaseURL:NO];
        if (self->_rest.options.pushFullWait) {
        components.queryItems = @[[NSURLQueryItem queryItemWithName:@"fullWait" value:@"true"]];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";
    [request setValue:[[self->_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [self->_logger debug:__FILE__ line:__LINE__ message:@"remove device with request %@", request];
    [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*Ok*/ || response.statusCode == 204 /*not returning any content*/) {
            [self->_logger debug:__FILE__ line:__LINE__ message:@"%@: save device successfully", NSStringFromClass(self.class)];
            callback(nil);
        }
        else if (error) {
            [self->_logger error:@"%@: remove device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            callback([ARTErrorInfo createFromNSError:error]);
        }
        else {
            [self->_logger error:@"%@: remove device failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
            NSString *plain = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            callback([ARTErrorInfo createWithCode:response.statusCode*100 status:response.statusCode message:[plain shortString]]);
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
});
}

- (void)removeWhere:(NSDictionary<NSString *, NSString *> *)params callback:(void (^)(ARTErrorInfo *error))callback {
    if (callback) {
        void (^userCallback)(ARTErrorInfo *error) = callback;
        callback = ^(ARTErrorInfo *error) {
            ART_EXITING_ABLY_CODE(self->_rest);
            dispatch_async(self->_userQueue, ^{
                userCallback(error);
            });
        };
    }

    #if TARGET_OS_IOS
    ARTLocalDevice *local = _rest.device;
    #else
    ARTLocalDevice *local = nil;
    #endif

dispatch_async(_queue, ^{
ART_TRY_OR_REPORT_CRASH_START(self->_rest) {
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/deviceRegistrations"] resolvingAgainstBaseURL:NO];
    components.queryItems = [params asURLQueryItems];
    if (self->_rest.options.pushFullWait) {
        components.queryItems = [components.queryItems arrayByAddingObject:[NSURLQueryItem queryItemWithName:@"fullWait" value:@"true"]];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";
    [request setDeviceAuthentication:[params objectForKey:@"deviceId"] localDevice:local];

    [self->_logger debug:__FILE__ line:__LINE__ message:@"remove devices with request %@", request];
    [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (response.statusCode == 200 /*Ok*/ || response.statusCode == 204 /*not returning any content*/) {
            [self->_logger debug:__FILE__ line:__LINE__ message:@"%@: remove devices successfully", NSStringFromClass(self.class)];
            callback(nil);
        }
        else if (error) {
            [self->_logger error:@"%@: remove devices failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
            callback([ARTErrorInfo createFromNSError:error]);
        }
        else {
            [self->_logger error:@"%@: remove devices failed with status code %ld", NSStringFromClass(self.class), (long)response.statusCode];
            NSString *plain = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            callback([ARTErrorInfo createWithCode:response.statusCode*100 status:response.statusCode message:[plain shortString]]);
        }
    }];
} ART_TRY_OR_REPORT_CRASH_END
});
}

@end
