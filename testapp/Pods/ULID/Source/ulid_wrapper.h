//
//  ulid_wrapper.h
//  ULID
//
//  Created by Ricardo Pereira on 14/02/2017.
//  Copyright © 2017 Whitesmith. All rights reserved.
//

#ifndef ulid_wrapper_h
#define ulid_wrapper_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ULID : NSObject <NSCopying>

/* Create a new autoreleased ULID */
+ (instancetype)ULID;

/* Init with a timestamp and a generator */
- (instancetype)initWithTimestamp:(NSTimeInterval)timestamp generator:(NSUInteger(^)(void))generator;

/* Return a string description of the ULID, such as "0001C7STHC0G2081040G208104" */
@property (nonatomic, readonly) NSString *ulidString;

@end

NS_ASSUME_NONNULL_END

#endif /* ulid_wrapper_h */
