//
//  ARTBaseMessage.m
//  ably-ios
//
//  Created by Jason Choy on 08/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTBaseMessage+Private.h"
#import "ARTLog.h"
#import "ARTStatus.h"

@implementation ARTBaseMessage

- (void)setClientId:(NSString *)clientId {
    if(clientId) {
        const char* c = [clientId UTF8String];
        _clientId = [NSString stringWithUTF8String:c];
    }
    else {
        _clientId = nil;
    }
}

- (id)copyWithZone:(NSZone *)zone {
    ARTBaseMessage *message = [[self.class allocWithZone:zone] init];
    message->_id = self.id;
    message->_clientId = self.clientId;
    message->_timestamp = self.timestamp;
    message->_data = [self.data copy];
    message->_connectionId = self.connectionId;
    message->_encoding = self.encoding;
    return message;
}

- (id)decodeWithEncoder:(ARTDataEncoder*)encoder error:(NSError **)error {
    ARTDataEncoderOutput *decoded = [encoder decode:self.data encoding:self.encoding];
    if (decoded.errorInfo && error) {
        *error = [NSError errorWithDomain:ARTAblyErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"decoding failed",
                                                                               NSLocalizedFailureReasonErrorKey: decoded.errorInfo.message}];
    }
    id ret = [self copy];
    ((ARTBaseMessage *)ret).data = decoded.data;
    ((ARTBaseMessage *)ret).encoding = decoded.encoding;
    return ret;
}

- (id)encodeWithEncoder:(ARTDataEncoder*)encoder error:(NSError **)error {
    ARTDataEncoderOutput *encoded = [encoder encode:self.data];
    if (encoded.errorInfo && error) {
        *error = [NSError errorWithDomain:ARTAblyErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"encoding failed",
                                                                               NSLocalizedFailureReasonErrorKey: encoded.errorInfo.message}];
    }
    id ret = [self copy];
    ((ARTBaseMessage *)ret).data = encoded.data;
    ((ARTBaseMessage *)ret).encoding = [NSString artAddEncoding:encoded.encoding toString:self.encoding];
    return ret;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p> {\n", self.class, self];
    [description appendFormat:@" id: %@,\n", self.id];
    [description appendFormat:@" clientId: %@,\n", self.clientId];
    [description appendFormat:@" connectionId: %@,\n", self.connectionId];
    [description appendFormat:@" timestamp: %@,\n", self.timestamp];
    [description appendFormat:@" encoding: %@,\n", self.encoding];
    [description appendFormat:@" data: %@\n", self.data];
    [description appendFormat:@"}"];
    return description;
}

- (NSInteger)messageSize {
    // TO3l8*
    NSInteger finalResult = 0;
    finalResult += [[self.extras toJSONString] lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    finalResult += [self.clientId lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (self.data) {
        if ([self.data isKindOfClass:[NSString class]]) {
            finalResult += [self.data lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([self.data isKindOfClass:[NSData class]]) {
            finalResult += [self.data length];
        } else {
            NSError *error = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.data
                                                               options:NSJSONWritingPrettyPrinted
                                                                 error:&error];
            if (!error) {
                finalResult += [jsonData length];
            }
        }
    }
    return finalResult;
}

@end
