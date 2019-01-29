//
//  ARTDataQuery+Private.h
//  ably
//
//  Created by Yavor Georgiev on 20.08.15.
//  Copyright (c) 2015 г. Ably. All rights reserved.
//

#import <Ably/ARTDataQuery.h>
#import <Ably/ARTRealtimeChannel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTDataQuery(Private)

- (NSMutableArray /* <NSURLQueryItem *> */ *)asQueryItems:(NSError *_Nullable *)error;

@end

@interface ARTRealtimeHistoryQuery ()

@property (weak, readwrite) ARTRealtimeChannel *realtimeChannel;

@end

NS_ASSUME_NONNULL_END
