//
//  ARTPushChannel.m
//  Ably
//
//  Created by Ricardo Pereira on 07/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushChannel.h"
#import "ARTHttp.h"
#import "ARTLog.h"
#import "ARTJsonLikeEncoder.h"
#import "ARTRest+Private.h"
#import "ARTClientOptions.h"
#import "ARTPaginatedResult+Private.h"
#import "ARTPushChannelSubscription.h"
#import "ARTChannel+Private.h"
#import "ARTLocalDevice+Private.h"
#import "ARTNSMutableRequest+ARTPush.h"

const NSUInteger ARTDefaultLimit = 100;

@implementation ARTPushChannel {
    __weak ARTRest *_rest;
    __weak ARTLog *_logger;
    __weak ARTChannel *_channel;
}

- (instancetype)init:(ARTRest *)rest withChannel:(ARTChannel *)channel {
    if (self == [super self]) {
        _rest = rest;
        _logger = [rest logger];
        _channel = channel;
        _logger = channel.logger;
    }
    return self;
}

- (void)subscribeDevice {
    [self subscribeDevice:nil];
}

- (void)unsubscribeDevice {
    [self unsubscribeDevice:nil];
}

- (void)subscribeClient {
    [self subscribeClient:nil];
}

- (void)unsubscribeClient {
    [self unsubscribeClient:nil];
}

- (void)subscribeDevice:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback {
    ARTLocalDevice *device = [self getDevice:callback];
    if (![device isRegistered]) {
        return;
    }
    NSString *deviceId = device.id;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[_rest defaultEncoder] encode:@{
        @"deviceId": deviceId,
        @"channel": _channel.name,
    } error:nil];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];
    [request setDeviceAuthentication:deviceId localDevice:device];

    [_logger debug:__FILE__ line:__LINE__ message:@"subscribe notifications for device %@ in channel %@", deviceId, _channel.name];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self->_logger error:@"%@: subscribe notifications for device %@ in channel %@ failed (%@)", NSStringFromClass(self.class), deviceId, self->_channel.name, error.localizedDescription];
        }
        if (callback) callback(error ? [ARTErrorInfo createFromNSError:error] : nil);
    }];
}

- (void)subscribeClient:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback {
    NSString *clientId = [self getClientId:callback];
    if (!clientId) {
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [[_rest defaultEncoder] encode:@{
        @"clientId": clientId,
        @"channel": _channel.name,
    } error:nil];
    [request setValue:[[_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

    [_logger debug:__FILE__ line:__LINE__ message:@"subscribe notifications for clientId %@ in channel %@", clientId, _channel.name];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self->_logger error:@"%@: subscribe notifications for clientId %@ in channel %@ failed (%@)", NSStringFromClass(self.class), clientId, self->_channel.name, error.localizedDescription];
        }
        if (callback) callback(error ? [ARTErrorInfo createFromNSError:error] : nil);
    }];
}

- (void)unsubscribeDevice:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback {
    ARTLocalDevice *device = [self getDevice:callback];
    if (![device isRegistered]) {
        return;
    }
    NSString *deviceId = device.id;

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"deviceId" value:deviceId],
        [NSURLQueryItem queryItemWithName:@"channel" value:_channel.name],
    ];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";
    [request setDeviceAuthentication:deviceId localDevice:device];

    [_logger debug:__FILE__ line:__LINE__ message:@"unsubscribe notifications for device %@ in channel %@", deviceId, _channel.name];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self->_logger error:@"%@: unsubscribe notifications for device %@ in channel %@ failed (%@)", NSStringFromClass(self.class), deviceId, self->_channel.name, error.localizedDescription];
        }
        if (callback) callback(error ? [ARTErrorInfo createFromNSError:error] : nil);
    }];
}

- (void)unsubscribeClient:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback {
    NSString *clientId = [self getClientId:callback];
    if (!clientId) {
        return;
    }

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"clientId" value:clientId],
        [NSURLQueryItem queryItemWithName:@"channel" value:_channel.name],
    ];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"DELETE";

    [_logger debug:__FILE__ line:__LINE__ message:@"unsubscribe notifications for clientId %@ in channel %@", clientId, _channel.name];
    [_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [self->_logger error:@"%@: unsubscribe notifications for clientId %@ in channel %@ failed (%@)", NSStringFromClass(self.class), clientId, self->_channel.name, error.localizedDescription];
        }
        if (callback) callback(error ? [ARTErrorInfo createFromNSError:error] : nil);
    }];
}

- (BOOL)listSubscriptions:(NSDictionary<NSString *, NSString *> *)params callback:(void(^)(ARTPaginatedResult<ARTPushChannelSubscription *> *_Nullable, ARTErrorInfo *_Nullable))callback error:(NSError *_Nullable *_Nullable)errorPtr {
    NSMutableDictionary<NSString *, NSString *> *mutableParams = params ? [NSMutableDictionary dictionaryWithDictionary:params] : [[NSMutableDictionary alloc] init];

    if (!mutableParams[@"deviceId"] && !mutableParams[@"clientId"]) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorMissingRequiredFields
                                        userInfo:@{NSLocalizedDescriptionKey:@"cannot list subscriptions with null device ID or null client ID"}];
        }
        return NO;
    }
    if (mutableParams[@"deviceId"] && mutableParams[@"clientId"]) {
        if (errorPtr) {
            *errorPtr = [NSError errorWithDomain:ARTAblyErrorDomain
                                            code:ARTDataQueryErrorInvalidParameters
                                        userInfo:@{NSLocalizedDescriptionKey:@"cannot list subscriptions with device ID and client ID"}];
        }
        return NO;
    }

    mutableParams[@"concatFilters"] = @"true";

    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:@"/push/channelSubscriptions"] resolvingAgainstBaseURL:NO];
    components.queryItems = [mutableParams asURLQueryItems];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.HTTPMethod = @"GET";

    ARTPaginatedResultResponseProcessor responseProcessor = ^(NSHTTPURLResponse *response, NSData *data, NSError **error) {
        return [self->_rest.encoders[response.MIMEType] decodePushChannelSubscriptions:data error:error];
    };

    [ARTPaginatedResult executePaginated:_rest withRequest:request andResponseProcessor:responseProcessor callback:callback];
    return YES;
}

- (ARTLocalDevice *)getDevice:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback {
    ARTLocalDevice *device = [_channel device];
    if (![device isRegistered]) {
        if (callback) callback([ARTErrorInfo createWithCode:0 message:@"cannot use device before device activation has finished"]);
    }
    return device;
}

- (NSString *)getClientId:(void(^_Nullable)(ARTErrorInfo *_Nullable))callback {
    ARTLocalDevice *device = [self getDevice:callback];
    if (![device isRegistered]) {
        return nil;
    }
    if (!device.clientId) {
        if (callback) callback([ARTErrorInfo createWithCode:0 message:@"cannot subscribe/unsubscribe with null client ID"]);
        return nil;
    }
    return device.clientId;
}

@end
