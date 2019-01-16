//
//  ARTPresenceMap.m
//  ably
//
//  Created by vic on 25/05/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import "ARTPresenceMap.h"
#import "ARTPresenceMessage.h"
#import "ARTPresenceMessage+Private.h"
#import "ARTEventEmitter+Private.h"
#import "ARTLog.h"

typedef NS_ENUM(NSUInteger, ARTPresenceSyncState) {
    ARTPresenceSyncInitialized,
    ARTPresenceSyncStarted, //ItemType: nil
    ARTPresenceSyncEnded, //ItemType: NSArray<ARTPresenceMessage *>*
    ARTPresenceSyncFailed //ItemType: ARTErrorInfo*
};

NSString *ARTPresenceSyncStateToStr(ARTPresenceSyncState state) {
    switch (state) {
        case ARTPresenceSyncInitialized:
            return @"Initialized"; //0
        case ARTPresenceSyncStarted:
            return @"Started"; //1
        case ARTPresenceSyncEnded:
            return @"Ended"; //2
        case ARTPresenceSyncFailed:
            return @"Failed"; //3
    }
}

#pragma mark - ARTEvent

@interface ARTEvent (PresenceSyncState)

- (instancetype)initWithPresenceSyncState:(ARTPresenceSyncState)value;
+ (instancetype)newWithPresenceSyncState:(ARTPresenceSyncState)value;

@end

#pragma mark - ARTPresenceMap

@interface ARTPresenceMap () {
    ARTPresenceSyncState _syncState;
    ARTEventEmitter<ARTEvent * /*ARTSyncState*/, id> *_syncEventEmitter;
    NSMutableDictionary<NSString *, ARTPresenceMessage *> *_members;
    NSMutableSet<ARTPresenceMessage *> *_localMembers;
}

@end

@implementation ARTPresenceMap {
    __weak ARTLog *_logger;
}

- (instancetype)initWithQueue:(_Nonnull dispatch_queue_t)queue logger:(ARTLog *)logger { 
    self = [super init];
    if(self) {
        _logger = logger;
        [self reset];
        _syncSessionId = 0;
        _syncState = ARTPresenceSyncInitialized;
        _syncEventEmitter = [[ARTInternalEventEmitter alloc] initWithQueue:queue];
    }
    return self;
}

- (NSDictionary<NSString *, ARTPresenceMessage *> *)members {
    return _members;
}

- (NSMutableSet<ARTPresenceMessage *> *)localMembers {
    return _localMembers;
}

- (BOOL)add:(ARTPresenceMessage *)message {
    ARTPresenceMessage *latest = [_members objectForKey:message.memberKey];
    if ([self isNewestPresence:message comparingWith:latest]) {
        ARTPresenceMessage *messageCopy = [message copy];
        switch (message.action) {
            case ARTPresenceEnter:
            case ARTPresenceUpdate:
                messageCopy.action = ARTPresencePresent;
                // intentional fallthrough
            case ARTPresencePresent:
                [self internalAdd:messageCopy];
                break;
            case ARTPresenceLeave:
                [self internalRemove:messageCopy];
                break;
            default:
                break;
        }
        return YES;
    }
    latest.syncSessionId = _syncSessionId;
    return NO;
}

- (void)internalAdd:(ARTPresenceMessage *)message {
    [self internalAdd:message withSessionId:_syncSessionId];
}

- (void)internalAdd:(ARTPresenceMessage *)message withSessionId:(NSUInteger)sessionId {
    message.syncSessionId = sessionId;
    [_members setObject:message forKey:message.memberKey];
    // Local member
    if ([message.connectionId isEqualToString:[self.delegate connectionId]]) {
        [_localMembers addObject:message];
        [_logger debug:__FILE__ line:__LINE__ message:@"local member %@ added", message.memberKey];
    }
}

- (void)internalRemove:(ARTPresenceMessage *)message {
    [self internalRemove:message force:false];
}

- (void)internalRemove:(ARTPresenceMessage *)message force:(BOOL)force {
    if (!force && self.syncInProgress) {
        message.action = ARTPresenceAbsent;
        // Should be removed after Sync ends
        [self internalAdd:message withSessionId:message.syncSessionId];
    }
    else {
        [_members removeObjectForKey:message.memberKey];
        [_localMembers removeObject:message];
    }
}

- (BOOL)isNewestPresence:(nonnull ARTPresenceMessage *)received comparingWith:(ARTPresenceMessage *)latest  __attribute__((warn_unused_result)) {
    if (latest == nil) {
        return YES;
    }

    NSArray<NSString *> *receivedMessageIdParts = [received.id componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
    if (receivedMessageIdParts.count != 3) {
        [_logger error:@"Received presence message id is invalid %@", received.id];
        return !received.timestamp ||
            [latest.timestamp timeIntervalSince1970] <= [received.timestamp timeIntervalSince1970];
    }
    NSString *receivedConnectionId = [receivedMessageIdParts objectAtIndex:0];
    NSInteger receivedMsgSerial = [[receivedMessageIdParts objectAtIndex:1] integerValue];
    NSInteger receivedIndex = [[receivedMessageIdParts objectAtIndex:2] integerValue];

    if ([receivedConnectionId isEqualToString:received.connectionId]) {
        NSArray<NSString *> *latestRegisteredIdParts = [latest.id componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
        if (latestRegisteredIdParts.count != 3) {
            [_logger error:@"Latest registered presence message id is invalid %@", latest.id];
            return !received.timestamp ||
                [latest.timestamp timeIntervalSince1970] <= [received.timestamp timeIntervalSince1970];
        }
        NSInteger latestRegisteredMsgSerial = [[latestRegisteredIdParts objectAtIndex:1] integerValue];
        NSInteger latestRegisteredIndex = [[latestRegisteredIdParts objectAtIndex:2] integerValue];

        if (receivedMsgSerial > latestRegisteredMsgSerial) {
            return YES;
        }
        else if (receivedMsgSerial == latestRegisteredMsgSerial && receivedIndex > latestRegisteredIndex) {
            return YES;
        }

        [_logger debug:__FILE__ line:__LINE__ message:@"Presence member \"%@\" with action %@ has been ignored", received.memberKey, ARTPresenceActionToStr(received.action)];
        return NO;
    }

    return !received.timestamp ||
        [latest.timestamp timeIntervalSince1970] <= [received.timestamp timeIntervalSince1970];
}

- (void)cleanUpAbsentMembers {
    NSSet<NSString *> *filteredMembers = [_members keysOfEntriesPassingTest:^BOOL(NSString *key, ARTPresenceMessage *message, BOOL *stop) {
        return message.action == ARTPresenceAbsent;
    }];
    for (NSString *key in filteredMembers) {
        [self internalRemove:[_members objectForKey:key] force:true];
    }
}

- (void)leaveMembersNotPresentInSync {
    for (ARTPresenceMessage *member in [_members allValues]) {
        if (member.syncSessionId != _syncSessionId) {
            // Handle members that have not been added or updated in the PresenceMap during the sync process
            ARTPresenceMessage *leave = [member copy];
            [self internalRemove:member];
            [self.delegate map:self didRemovedMemberNoLongerPresent:leave];
        }
    }
}

- (void)reenterLocalMembersMissingFromSync {
    NSSet *filteredLocalMembers = [_localMembers filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"syncSessionId != %lu", (unsigned long)_syncSessionId]];
    for (ARTPresenceMessage *localMember in filteredLocalMembers) {
        ARTPresenceMessage *reenter = [localMember copy];
        [self internalRemove:localMember];
        [self.delegate map:self shouldReenterLocalMember:reenter];
    }
    [self cleanUpAbsentMembers];
}

- (void)reset {
    _members = [NSMutableDictionary dictionary];
    _localMembers = [NSMutableSet set];
}

- (void)startSync {
    _syncSessionId++;
    _syncState = ARTPresenceSyncStarted;
    [_syncEventEmitter emit:[ARTEvent newWithPresenceSyncState:_syncState] with:nil];
}

- (void)endSync {
    [self cleanUpAbsentMembers];
    [self leaveMembersNotPresentInSync];
    _syncState = ARTPresenceSyncEnded;
    [self reenterLocalMembersMissingFromSync];
    [_syncEventEmitter emit:[ARTEvent newWithPresenceSyncState:ARTPresenceSyncEnded] with:[_members allValues]];
    [_syncEventEmitter off];
}

- (void)failsSync:(ARTErrorInfo *)error {
    [self reset];
    _syncState = ARTPresenceSyncFailed;
    [_syncEventEmitter emit:[ARTEvent newWithPresenceSyncState:ARTPresenceSyncFailed] with:error];
    [_syncEventEmitter off];
}

- (void)onceSyncEnds:(void (^)(NSArray<ARTPresenceMessage *> *))callback {
    if (self.syncInProgress) {
        [_syncEventEmitter once:[ARTEvent newWithPresenceSyncState:ARTPresenceSyncEnded] callback:callback];
    }
    else {
        callback([_members allValues]);
    }
}

- (void)onceSyncFails:(void (^)(ARTErrorInfo *))callback {
    if (self.syncInProgress) {
        [_syncEventEmitter once:[ARTEvent newWithPresenceSyncState:ARTPresenceSyncFailed] callback:callback];
    }
}

- (BOOL)syncComplete {
    return !(_syncState == ARTPresenceSyncInitialized || _syncState == ARTPresenceSyncStarted);
}

- (BOOL)syncInProgress {
    return _syncState == ARTPresenceSyncStarted;
}

#pragma mark private

- (NSString *)memberKey:(ARTPresenceMessage *) message {
    return [NSString stringWithFormat:@"%@:%@", message.connectionId, message.clientId];
}

@end

#pragma mark - ARTEvent

@implementation ARTEvent (PresenceSyncState)

- (instancetype)initWithPresenceSyncState:(ARTPresenceSyncState)value {
    return [self initWithString:[NSString stringWithFormat:@"ARTPresenceSyncState%@", ARTPresenceSyncStateToStr(value)]];
}

+ (instancetype)newWithPresenceSyncState:(ARTPresenceSyncState)value {
    return [[self alloc] initWithPresenceSyncState:value];
}

@end
