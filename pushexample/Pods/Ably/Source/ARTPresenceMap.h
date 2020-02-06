//
//  ARTPresenceMap.h
//  ably
//
//  Created by vic on 25/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ARTPresenceMap;
@class ARTPresenceMessage;
@class ARTErrorInfo;
@class ARTLog;

NS_ASSUME_NONNULL_BEGIN

/// ARTPresenceMapDelegate
@protocol ARTPresenceMapDelegate <NSObject>
@property (nonatomic, readonly) NSString *connectionId;
- (void)map:(ARTPresenceMap *)map didRemovedMemberNoLongerPresent:(ARTPresenceMessage *)presence;
- (void)map:(ARTPresenceMap *)map shouldReenterLocalMember:(ARTPresenceMessage *)presence;
@end

/// Used to maintain a list of members present on a channel
@interface ARTPresenceMap : NSObject

/// List of members.
/// The key is the memberKey and the value is the latest relevant ARTPresenceMessage for that clientId.
@property (readonly, atomic) NSDictionary<NSString *, ARTPresenceMessage *> *members;

/// List of internal members.
/// The key is the clientId and the value is the latest relevant ARTPresenceMessage for that clientId.
@property (readonly, atomic) NSMutableSet<ARTPresenceMessage *> *localMembers;

@property (nullable, weak) id<ARTPresenceMapDelegate> delegate; // weak because delegates outlive their counterpart

@property (readwrite, nonatomic, assign) int64_t syncMsgSerial;
@property (readwrite, nonatomic, nullable) NSString *syncChannelSerial;
@property (readonly, nonatomic, assign) NSUInteger syncSessionId;
@property (readonly, nonatomic, getter=syncComplete) BOOL syncComplete;
@property (readonly, nonatomic, getter=syncInProgress) BOOL syncInProgress;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithQueue:(_Nonnull dispatch_queue_t)queue logger:(ARTLog *)logger;

- (BOOL)add:(ARTPresenceMessage *)message;
- (void)reset;

- (void)startSync;
- (void)endSync;
- (void)failsSync:(ARTErrorInfo *)error;

- (void)onceSyncEnds:(void (^)(NSArray<ARTPresenceMessage *> *))callback;
- (void)onceSyncFails:(void (^)(ARTErrorInfo *))callback;

- (void)internalAdd:(ARTPresenceMessage *)message;
- (void)internalAdd:(ARTPresenceMessage *)message withSessionId:(NSUInteger)sessionId;

@end

NS_ASSUME_NONNULL_END
