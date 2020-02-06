//
//  ARTStats.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTDataQuery.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ARTStatsGranularity) {
    ARTStatsGranularityMinute,
    ARTStatsGranularityHour,
    ARTStatsGranularityDay,
    ARTStatsGranularityMonth
};

@interface ARTStatsQuery : ARTDataQuery

@property (nonatomic, assign) ARTStatsGranularity unit;

@end

@interface ARTStatsMessageCount : NSObject

@property (readonly, assign, nonatomic) NSUInteger count;
@property (readonly, assign, nonatomic) NSUInteger data;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCount:(NSUInteger)count
                         data:(NSUInteger)data;

+ (instancetype)empty;

@end

@interface ARTStatsMessageTypes : NSObject

@property (readonly, strong, nonatomic) ARTStatsMessageCount *all;
@property (readonly, strong, nonatomic) ARTStatsMessageCount *messages;
@property (readonly, strong, nonatomic) ARTStatsMessageCount *presence;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAll:(nullable ARTStatsMessageCount *)all
                   messages:(nullable ARTStatsMessageCount *)messages
                   presence:(nullable ARTStatsMessageCount *)presence;

+ (instancetype)empty;

@end

@interface ARTStatsMessageTraffic : NSObject

@property (readonly, strong, nonatomic) ARTStatsMessageTypes *all;
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *realtime;
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *rest;
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *webhook;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAll:(nullable ARTStatsMessageTypes *)all
                   realtime:(nullable ARTStatsMessageTypes *)realtime
                       rest:(nullable ARTStatsMessageTypes *)rest
                    webhook:(nullable ARTStatsMessageTypes *)webhook;

+ (instancetype)empty;

@end

@interface ARTStatsResourceCount : NSObject

@property (readonly, assign, nonatomic) NSUInteger opened;
@property (readonly, assign, nonatomic) NSUInteger peak;
@property (readonly, assign, nonatomic) NSUInteger mean;
@property (readonly, assign, nonatomic) NSUInteger min;
@property (readonly, assign, nonatomic) NSUInteger refused;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithOpened:(NSUInteger)opened
                          peak:(NSUInteger)peak
                          mean:(NSUInteger)mean
                           min:(NSUInteger)min
                       refused:(NSUInteger)refused;

+ (instancetype)empty;

@end

@interface ARTStatsConnectionTypes : NSObject

@property (readonly, strong, nonatomic) ARTStatsResourceCount *all;
@property (readonly, strong, nonatomic) ARTStatsResourceCount *plain;
@property (readonly, strong, nonatomic) ARTStatsResourceCount *tls;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAll:(nullable ARTStatsResourceCount *)all
                      plain:(nullable ARTStatsResourceCount *)plain
                        tls:(nullable ARTStatsResourceCount *)tls;

+ (instancetype)empty;

@end

@interface ARTStatsRequestCount : NSObject

@property (readonly, assign, nonatomic) NSUInteger succeeded;
@property (readonly, assign, nonatomic) NSUInteger failed;
@property (readonly, assign, nonatomic) NSUInteger refused;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithSucceeded:(NSUInteger)succeeded
                           failed:(NSUInteger)failed
                          refused:(NSUInteger)refused;

+ (instancetype)empty;

@end

@interface ARTStats : NSObject

+ (NSDate *)fromIntervalId:(NSString *)intervalId;
+ (ARTStatsGranularity)granularityFromIntervalId:(NSString *)intervalId;
+ (NSString *)toIntervalId:(NSDate *)time granularity:(ARTStatsGranularity)granularity;

@property (readonly, strong, nonatomic) ARTStatsMessageTypes *all;
@property (readonly, strong, nonatomic) ARTStatsMessageTraffic *inbound;
@property (readonly, strong, nonatomic) ARTStatsMessageTraffic *outbound;
@property (readonly, strong, nonatomic) ARTStatsMessageTypes *persisted;
@property (readonly, strong, nonatomic) ARTStatsConnectionTypes *connections;
@property (readonly, strong, nonatomic) ARTStatsResourceCount *channels;
@property (readonly, strong, nonatomic) ARTStatsRequestCount *apiRequests;
@property (readonly, strong, nonatomic) ARTStatsRequestCount *tokenRequests;
@property (readonly, strong, nonatomic) NSString *intervalId;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithAll:(ARTStatsMessageTypes *)all
                    inbound:(ARTStatsMessageTraffic *)inbound
                   outbound:(ARTStatsMessageTraffic *)outbound
                  persisted:(ARTStatsMessageTypes *)persisted
                connections:(ARTStatsConnectionTypes *)connections
                   channels:(ARTStatsResourceCount *)channels
                apiRequests:(ARTStatsRequestCount *)apiRequests
              tokenRequests:(ARTStatsRequestCount *)tokenRequests
                 intervalId:(NSString *)intervalId;

- (NSDate *)intervalTime;
- (ARTStatsGranularity)intervalGranularity;

@end

NS_ASSUME_NONNULL_END
