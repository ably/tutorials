//
//  ARTSentry.h
//  Ably
//
//  Created by Toni Cárdenas on 04/05/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTSentryBreadcrumb <NSCoding>

- (NSDictionary *)toBreadcrumb;

@end

@interface ARTSentry : NSObject

+ (void)setTags:(NSDictionary *)value;
+ (void)setExtras:(NSString *)key value:(id)value;
+ (void)setBreadcrumbs:(NSString *)key value:(NSArray<id<ARTSentryBreadcrumb>> *)value;
+ (void)setUserInfo:(NSString *)key value:(id)value;
+ (void)setUserInfo:(NSString *)key key:(NSString *)innerKey value:(id)value;
+ (BOOL)setCrashHandler:(NSString *_Nullable)dns;
+ (void)report:(NSString *)message to:(NSString *)dns extra:(NSDictionary *_Nullable)extra breadcrumbs:(NSArray<NSDictionary *> *_Nullable)breadcrumbs tags:(NSDictionary *)tags exception:(NSException *_Nullable)exception;
+ (void)report:(NSString *)message to:(NSString *)dns extra:(NSDictionary *_Nullable)extra breadcrumbs:(NSArray<NSDictionary *> *_Nullable)breadcrumbs tags:(NSDictionary *)tags exception:(NSException *_Nullable)exception callback:(void (^_Nullable)(NSError *_Nullable))callback;
+ (void)report:(NSMutableDictionary *)body to:(NSString *)dns callback:(void (^_Nullable)(NSError *_Nullable))callback;
+ (NSArray<NSDictionary *> *)flattenBreadcrumbs:(NSDictionary<NSString *, NSArray<NSDictionary *> *> *)breadcrumbs;

@end

id ART_orNull(id _Nullable obj);

NS_ASSUME_NONNULL_END
