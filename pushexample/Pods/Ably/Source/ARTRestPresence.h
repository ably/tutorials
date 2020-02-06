//
//  ARTRestPresence.h
//  ably
//
//  Created by Ricardo Pereira on 12/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTPresence.h>
#import <Ably/ARTDataQuery.h>

@class ARTRestChannel;

NS_ASSUME_NONNULL_BEGIN

@interface ARTPresenceQuery : NSObject

@property (nonatomic, readwrite) NSUInteger limit;
@property (nullable, nonatomic, strong, readwrite) NSString *clientId;
@property (nullable, nonatomic, strong, readwrite) NSString *connectionId;

- (instancetype)init;
- (instancetype)initWithClientId:(NSString *_Nullable)clientId connectionId:(NSString *_Nullable)connectionId;
- (instancetype)initWithLimit:(NSUInteger)limit clientId:(NSString *_Nullable)clientId connectionId:(NSString *_Nullable)connectionId;

@end

@protocol ARTRestPresenceProtocol

- (void)get:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback;
- (BOOL)get:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback error:(NSError *_Nullable *_Nullable)errorPtr;
- (BOOL)get:(ARTPresenceQuery *)query callback:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (BOOL)history:(nullable ARTDataQuery *)query callback:(void(^)(ARTPaginatedResult<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback error:(NSError *_Nullable *_Nullable)errorPtr;

@end

@interface ARTRestPresence : ARTPresence <ARTRestPresenceProtocol>

- (void)get:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback;
- (BOOL)get:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback error:(NSError *_Nullable *_Nullable)errorPtr;
- (BOOL)get:(ARTPresenceQuery *)query callback:(void (^)(ARTPaginatedResult<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback error:(NSError *_Nullable *_Nullable)errorPtr;

- (BOOL)history:(nullable ARTDataQuery *)query callback:(void(^)(ARTPaginatedResult<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback error:(NSError *_Nullable *_Nullable)errorPtr;

@end

NS_ASSUME_NONNULL_END
