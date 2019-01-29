//
//  ARTRealtimeChannel.h
//  ably
//
//  Created by Ricardo Pereira on 30/09/2015.
//  Copyright (c) 2015 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Ably/ARTTypes.h>
#import <Ably/ARTLog.h>
#import <Ably/ARTRestChannel.h>
#import <Ably/ARTPresenceMessage.h>
#import <Ably/ARTEventEmitter.h>
#import <Ably/ARTRealtimePresence.h>
#import <Ably/ARTDataQuery.h>

NS_ASSUME_NONNULL_BEGIN

@class ARTRealtimePresence;
#if TARGET_OS_IPHONE
@class ARTPushChannel;
#endif

@interface ARTRealtimeChannel : ARTChannel

@property (readwrite, assign, nonatomic) ARTRealtimeChannelState state;
@property (readonly, strong, nonatomic, nullable) ARTErrorInfo *errorReason;

@property (readonly) ARTRealtimePresence *presence;
#if TARGET_OS_IPHONE
@property (readonly) ARTPushChannel *push;
#endif

- (void)attach;
- (void)attach:(nullable void (^)(ARTErrorInfo *_Nullable))callback;

- (void)detach;
- (void)detach:(nullable void (^)(ARTErrorInfo *_Nullable))callback;

- (ARTEventListener *_Nullable)subscribe:(void (^)(ARTMessage *message))callback;
- (ARTEventListener *_Nullable)subscribeWithAttachCallback:(nullable void (^)(ARTErrorInfo *_Nullable))onAttach callback:(void (^)(ARTMessage *message))cb;
- (ARTEventListener *_Nullable)subscribe:(NSString *)name callback:(void (^)(ARTMessage *message))cb;
- (ARTEventListener *_Nullable)subscribe:(NSString *)name onAttach:(nullable void (^)(ARTErrorInfo *_Nullable))onAttach callback:(void (^)(ARTMessage *message))cb;

- (void)unsubscribe;
- (void)unsubscribe:(ARTEventListener *_Nullable)listener;
- (void)unsubscribe:(NSString *)name listener:(ARTEventListener *_Nullable)listener;

- (BOOL)history:(ARTRealtimeHistoryQuery *_Nullable)query callback:(void(^)(ARTPaginatedResult<ARTMessage *> *_Nullable result, ARTErrorInfo *_Nullable error))callback error:(NSError *_Nullable *_Nullable)errorPtr;

ART_EMBED_INTERFACE_EVENT_EMITTER(ARTChannelEvent, ARTChannelStateChange *)

@end

#pragma mark - ARTEvent

@interface ARTEvent (ChannelEvent)
- (instancetype)initWithChannelEvent:(ARTChannelEvent)value;
+ (instancetype)newWithChannelEvent:(ARTChannelEvent)value;
@end

NS_ASSUME_NONNULL_END
