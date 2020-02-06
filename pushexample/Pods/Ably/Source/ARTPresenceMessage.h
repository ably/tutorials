//
//  ARTPresenceMessage.h
//  ably-ios
//
//  Created by Jason Choy on 09/12/2014.
//  Copyright (c) 2014 Ably. All rights reserved.
//

#import <Ably/ARTBaseMessage.h>
#import <Ably/ARTEventEmitter.h>

/// Presence action type
typedef NS_ENUM(NSUInteger, ARTPresenceAction) {
    ARTPresenceAbsent,
    ARTPresencePresent,
    ARTPresenceEnter,
    ARTPresenceLeave,
    ARTPresenceUpdate
};

NSString *_Nonnull ARTPresenceActionToStr(ARTPresenceAction action);

NS_ASSUME_NONNULL_BEGIN

/// List of members present on a channel
@interface ARTPresenceMessage : ARTBaseMessage

@property (readwrite, assign, nonatomic) ARTPresenceAction action;

- (nonnull NSString *)memberKey;

- (BOOL)isEqualToPresenceMessage:(nonnull ARTPresenceMessage *)presence;

- (BOOL)isNewerThan:(ARTPresenceMessage *)latest __attribute__((warn_unused_result));

@end

#pragma mark - ARTEvent

@interface ARTEvent (PresenceAction)
- (instancetype)initWithPresenceAction:(ARTPresenceAction)value;
+ (instancetype)newWithPresenceAction:(ARTPresenceAction)value;
@end

NS_ASSUME_NONNULL_END
