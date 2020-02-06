//
//  ARTChannel.m
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import "ARTChannel+Private.h"

#import "ARTDataEncoder.h"
#import "ARTMessage.h"
#import "ARTChannelOptions.h"
#import "ARTNSArray+ARTFunctional.h"
#import "ARTBaseMessage+Private.h"
#import "ARTDataQuery.h"
#import "ARTRest+Private.h"
#import "ARTDefault.h"

@implementation ARTChannel {
    dispatch_queue_t _queue;
}

- (instancetype)initWithName:(NSString *)name andOptions:(ARTChannelOptions *)options rest:(ARTRestInternal *)rest {
    if (self = [super init]) {
        _name = name;
        _logger = rest.logger;
        _queue = rest.queue;
        [self _setOptions:options];
        NSError *error = nil;
        _dataEncoder = [[ARTDataEncoder alloc] initWithCipherParams:_options.cipher error:&error];
        if (error != nil) {
            [_logger warn:@"creating ARTDataEncoder: %@", error];
            _dataEncoder = [[ARTDataEncoder alloc] initWithCipherParams:nil error:nil];
        }
    }
    return self;
}

- (void)setOptions:(ARTChannelOptions *)options {
    dispatch_sync(_queue, ^{
        [self _setOptions:options];
    });
}

- (void)_setOptions:(ARTChannelOptions *)options {
    if (!options) {
        _options = [[ARTChannelOptions alloc] initWithCipher:nil];
    } else {
        _options = options;
    }
}

- (void)publish:(NSString *)name data:(id)data {
    [self publish:name data:data callback:nil];
}

- (void)publish:(art_nullable NSString *)name data:(art_nullable id)data callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback {
    [self publish:name data:data extras:nil callback:callback];
}

- (void)publish:(NSString *)name data:(id)data extras:(id<ARTJsonCompatible>)extras {
    [self publish:name data:data extras:extras callback:nil];
}

- (void)publish:(art_nullable NSString *)name data:(art_nullable id)data extras:(id<ARTJsonCompatible>)extras callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback {
    [self publish:name message:[[ARTMessage alloc] initWithName:name data:data] extras:extras callback:callback];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId {
    [self publish:name data:data clientId:clientId callback:nil];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId extras:(id<ARTJsonCompatible>)extras {
    [self publish:name data:data clientId:clientId extras:extras callback:nil];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId callback:(void (^)(ARTErrorInfo * _Nullable))callback {
    [self publish:name data:data clientId:(NSString *)clientId extras:nil callback:callback];
}

- (void)publish:(NSString *)name data:(id)data clientId:(NSString *)clientId extras:(id<ARTJsonCompatible>)extras callback:(void (^)(ARTErrorInfo * _Nullable))callback {
    [self publish:name message:[[ARTMessage alloc] initWithName:name data:data clientId:clientId] extras:extras callback:callback];
}

- (void)publish:(NSString *)name message:(ARTMessage *)message extras:(id<ARTJsonCompatible>)extras callback:(void (^)(ARTErrorInfo * _Nullable))callback {
    NSError *error = nil;
    message.extras = extras;
    ARTMessage *messagesWithDataEncoded = [self encodeMessageIfNeeded:message error:&error];
    if (error) {
        if (callback) callback([ARTErrorInfo createFromNSError:error]);
        return;
    }
    
    // Checked after encoding, so that the client can receive callback with encoding errors
    if ([self exceedMaxSize:@[message]]) {
        ARTErrorInfo *sizeError = [ARTErrorInfo createWithCode:40009
                                                       message:@"maximum message length exceeded"];
        if (callback) {
            callback(sizeError);
        }
        return;
    }
    
    [self internalPostMessages:messagesWithDataEncoded callback:callback];
}

- (void)publish:(NSArray<ARTMessage *> *)messages {
    [self publish:messages callback:nil];
}

- (void)publish:(__GENERIC(NSArray, ARTMessage *) *)messages callback:(art_nullable void (^)(ARTErrorInfo *__art_nullable error))callback {
    NSError *error = nil;

    NSMutableArray<ARTMessage *> *messagesWithDataEncoded = [NSMutableArray new];
    for (ARTMessage *message in messages) {
        [messagesWithDataEncoded addObject:[self encodeMessageIfNeeded:message error:&error]];
    }
    if (error) {
        callback([ARTErrorInfo createFromNSError:error]);
        return;
    }
    
    // Checked after encoding, so that the client can receive callback with encoding errors
    if ([self exceedMaxSize:messages]) {
        ARTErrorInfo *sizeError = [ARTErrorInfo createWithCode:40009
                                                       message:@"maximum message length exceeded"];
        if (callback) {
            callback(sizeError);
        }
        return;
    }
    
    [self internalPostMessages:messagesWithDataEncoded callback:callback];
}

- (BOOL)exceedMaxSize:(NSArray<ARTBaseMessage *> *)messages {
    NSInteger size = 0;
    for (ARTMessage *message in messages) {
        size += [message messageSize];
    }
    return size > [ARTDefault maxMessageSize];
}

- (ARTMessage *)encodeMessageIfNeeded:(ARTMessage *)message error:(NSError **)error {
    if (!self.dataEncoder) {
        return message;
    }
    NSError *e = nil;
    message = [message encodeWithEncoder:self.dataEncoder error:&e];
    if (e) {
        [self.logger error:@"ARTChannel: error encoding data: %@", e];
    }
    if (error) {
        *error = e;
    }
    return message;
}

- (void)history:(void (^)(__GENERIC(ARTPaginatedResult, ARTMessage *) *, ARTErrorInfo *))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

- (void)internalPostMessages:(id)data callback:(void (^)(ARTErrorInfo *__art_nullable error))callback {
    NSAssert(false, @"-[%@ %@] should always be overriden.", self.class, NSStringFromSelector(_cmd));
}

@end
