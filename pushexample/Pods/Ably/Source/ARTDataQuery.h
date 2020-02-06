//
//  ARTDataQuery.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ARTQueryDirection) {
    ARTQueryDirectionForwards,
    ARTQueryDirectionBackwards
};

@interface ARTDataQuery : NSObject

@property (nonatomic, strong, nullable) NSDate *start;
@property (nonatomic, strong, nullable) NSDate *end;

@property (nonatomic, assign) uint16_t limit;

@property (nonatomic, assign) ARTQueryDirection direction;

@end

@interface ARTRealtimeHistoryQuery : ARTDataQuery

@property (nonatomic, assign) BOOL untilAttach;

@end

NS_ASSUME_NONNULL_END
