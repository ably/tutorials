//
//  ARTJsonEncoder.m
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import "ARTJsonEncoder.h"

@implementation ARTJsonEncoder

- (NSString *)mimeType {
    return @"application/json";
}

- (ARTEncoderFormat)format {
    return ARTEncoderFormatJson;
}

- (NSString *)formatAsString {
    return @"json";
}

- (id)decode:(NSData *)data error:(NSError **)error {
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
}

- (NSData *)encode:(id)obj error:(NSError **)error {
    @try {
        return [NSJSONSerialization dataWithJSONObject:obj options:0 error:error];
    }
    @catch (NSException *exception) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:ARTAblyErrorDomain code:ARTClientCodeErrorInvalidType userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
        }
        return nil;
    }
}

@end
