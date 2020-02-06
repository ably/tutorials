//
//  ARTReachability.m
//  Ably
//
//  Created by Toni Cárdenas on 2/5/16.
//  Copyright © 2016 Ably. All rights reserved.
//

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

#import "ARTOSReachability.h"

NSNotificationName const kARTOSReachabilityNetworkIsReachableNotification = @"ARTOSReachabilityNetworkIsReachableNotification";
NSNotificationName const kARTOSReachabilityNetworkIsDownNotification = @"ARTOSReachabilityNetworkIsDownNotification";

/// Global callback for network state changes
static void ARTOSReachability_Callback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    // Post a notification to notify the instance that the network reachability changed.
    BOOL reachable = flags & kSCNetworkReachabilityFlagsReachable;
    if (reachable) {
        [NSNotificationCenter.defaultCenter postNotificationName:kARTOSReachabilityNetworkIsReachableNotification object:nil];
    }
    else {
        [NSNotificationCenter.defaultCenter postNotificationName:kARTOSReachabilityNetworkIsDownNotification object:nil];
    }
}

@implementation ARTOSReachability {
    ARTLog *_logger;
    NSString *_host;
    void (^_callback)(BOOL);
    SCNetworkReachabilityRef _reachabilityRef;
    dispatch_queue_t _queue;
}

- (instancetype)initWithLogger:(ARTLog *)logger queue:(dispatch_queue_t)queue {
    if (self = [super init]) {
        _logger = logger;
        _queue = queue;
    }
    return self;
}

- (void)listenForHost:(NSString *)host callback:(void (^)(BOOL))callback {
    [self off];
    _host = host;
    _callback = callback;

    _reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(networkIsReachable) name:kARTOSReachabilityNetworkIsReachableNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(networkIsDown) name:kARTOSReachabilityNetworkIsDownNotification object:nil];
    if (SCNetworkReachabilitySetCallback(_reachabilityRef, ARTOSReachability_Callback, &context)) {
        if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
            [_logger info:@"Reachability: started listening for host %@", _host];
        }
        else {
            [_logger warn:@"Reachability: failed starting listener for host %@", _host];
        }
    }
    else {
        [NSNotificationCenter.defaultCenter removeObserver:self name:kARTOSReachabilityNetworkIsReachableNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:kARTOSReachabilityNetworkIsDownNotification object:nil];
    }
}

- (void)off {
    if (_reachabilityRef != NULL) {
        [NSNotificationCenter.defaultCenter removeObserver:self name:kARTOSReachabilityNetworkIsReachableNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:kARTOSReachabilityNetworkIsDownNotification object:nil];
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        [_logger info:@"Reachability: stopped listening for host %@", _host];
    }
    _callback = nil;
    _host = nil;
}

- (void)networkIsReachable {
    [self internalCallback:true];
}

- (void)networkIsDown {
    [self internalCallback:false];
}

- (void)internalCallback:(BOOL)reachable {
    [_logger info:@"Reachability: host %@ is reachable: %@", _host, reachable ? @"true" : @"false"];
    dispatch_async(_queue, ^{
        if (self->_callback) self->_callback(reachable);
    });
}

- (void)dealloc {
    [self off];
    if (_reachabilityRef != NULL) {
        CFRelease(_reachabilityRef);
    }
}

@end
