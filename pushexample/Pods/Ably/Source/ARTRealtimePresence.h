//
//  ARTRealtimePresence.h
//  ably
//
//  Created by Ricardo Pereira on 12/11/15.
//  Copyright © 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTRestPresence.h>
#import <Ably/ARTDataQuery.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTRealtimeChannel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTRealtimePresenceQuery : ARTPresenceQuery

@property (readwrite, nonatomic) BOOL waitForSync;

@end

@protocol ARTRealtimePresenceProtocol

@property (readonly) BOOL syncComplete;

- (void)get:(void (^)(NSArray<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback;
- (void)get:(ARTRealtimePresenceQuery *)query callback:(void (^)(NSArray<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback;

- (void)enter:(id _Nullable)data;
- (void)enter:(id _Nullable)data callback:(nullable void (^)(ARTErrorInfo *_Nullable))cb;

- (void)update:(id _Nullable)data;
- (void)update:(id _Nullable)data callback:(nullable void (^)(ARTErrorInfo *_Nullable))cb;

- (void)leave:(id _Nullable)data;
- (void)leave:(id _Nullable)data callback:(nullable void (^)(ARTErrorInfo *_Nullable))cb;

- (void)enterClient:(NSString *)clientId data:(id _Nullable)data;
- (void)enterClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable void (^)(ARTErrorInfo *_Nullable))cb;

- (void)updateClient:(NSString *)clientId data:(id _Nullable)data;
- (void)updateClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable void (^)(ARTErrorInfo *_Nullable))cb;

- (void)leaveClient:(NSString *)clientId data:(id _Nullable)data;
- (void)leaveClient:(NSString *)clientId data:(id _Nullable)data callback:(nullable void (^)(ARTErrorInfo *_Nullable))cb;

- (ARTEventListener *_Nullable)subscribe:(void (^)(ARTPresenceMessage *message))callback;
- (ARTEventListener *_Nullable)subscribeWithAttachCallback:(nullable void (^)(ARTErrorInfo *_Nullable))onAttach callback:(void (^)(ARTPresenceMessage *message))cb;
- (ARTEventListener *_Nullable)subscribe:(ARTPresenceAction)action callback:(void (^)(ARTPresenceMessage *message))cb;
- (ARTEventListener *_Nullable)subscribe:(ARTPresenceAction)action onAttach:(nullable void (^)(ARTErrorInfo *_Nullable))onAttach callback:(void (^)(ARTPresenceMessage *message))cb;

- (void)unsubscribe;
- (void)unsubscribe:(ARTEventListener *)listener;
- (void)unsubscribe:(ARTPresenceAction)action listener:(ARTEventListener *)listener;

- (void)history:(void(^)(ARTPaginatedResult<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback;
- (BOOL)history:(ARTRealtimeHistoryQuery *_Nullable)query callback:(void(^)(ARTPaginatedResult<ARTPresenceMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback error:(NSError *_Nullable *_Nullable)errorPtr;

@end

@interface ARTRealtimePresence : ARTPresence <ARTRealtimePresenceProtocol>
@end

NS_ASSUME_NONNULL_END
