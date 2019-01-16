//
//  ARTPushAdmin.m
//  Ably
//
//  Created by Ricardo Pereira on 20/02/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import "ARTPushAdmin.h"
#import "ARTHttp.h"
#import "ARTRest+Private.h"
#import "ARTPushDeviceRegistrations.h"
#import "ARTPushChannelSubscriptions.h"
#import "ARTLog.h"
#import "ARTJsonEncoder.h"
#import "ARTJsonLikeEncoder.h"

@implementation ARTPushAdmin {
    ARTRest *_rest;
    __weak ARTLog *_logger;
    dispatch_queue_t _userQueue;
    dispatch_queue_t _queue;
}

- (instancetype)initWithRest:(ARTRest *)rest {
    if (self = [super init]) {
        _rest = rest;
        _logger = [rest logger];
        _deviceRegistrations = [[ARTPushDeviceRegistrations alloc] initWithRest:rest];
        _channelSubscriptions = [[ARTPushChannelSubscriptions alloc] initWithRest:rest];
        _userQueue = rest.userQueue;
        _queue = rest.queue;
    }
    return self;
}

- (void)publish:(ARTPushRecipient *)recipient data:(ARTJsonObject *)data callback:(nullable void (^)(ARTErrorInfo *_Nullable error))callback {
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
            if (![[recipient allKeys] count]) {
                if (callback) callback([ARTErrorInfo createWithCode:0 message:@"Recipient is missing"]);
                return;
            }

            if (![[data allKeys] count]) {
                if (callback) callback([ARTErrorInfo createWithCode:0 message:@"Data payload is missing"]);
                return;
            }

            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/push/publish"]];
            request.HTTPMethod = @"POST";
            NSMutableDictionary *body = [NSMutableDictionary dictionary];
            [body setObject:recipient forKey:@"recipient"];
            [body addEntriesFromDictionary:data];
            request.HTTPBody = [[self->_rest defaultEncoder] encode:body error:nil];
            [request setValue:[[self->_rest defaultEncoder] mimeType] forHTTPHeaderField:@"Content-Type"];

            [self->_logger debug:__FILE__ line:__LINE__ message:@"push notification to a single device %@", request];
            [self->_rest executeRequest:request withAuthOption:ARTAuthenticationOn completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
                if (error) {
                    [self->_logger error:@"%@: push notification to a single device failed (%@)", NSStringFromClass(self.class), error.localizedDescription];
                    if (callback) callback([ARTErrorInfo createFromNSError:error]);
                    return;
                }
                if (callback) callback(nil);
            }];
        } ART_TRY_OR_REPORT_CRASH_END
    });
}

@end
