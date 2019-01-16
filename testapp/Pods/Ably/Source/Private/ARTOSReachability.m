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
        if (ARTOSReachability_instances == nil) {
            ARTOSReachability_instances = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

NSMutableDictionary *ARTOSReachability_instances;

static void ARTOSReachability_Callback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    id instance;
    @synchronized (ARTOSReachability_instances) {
        instance = ARTOSReachability_instances[[NSValue valueWithPointer:target]];
    }
    if (instance == nil) {
        NSLog(@"ARTOSReachability: instance not found for target %@", [NSValue valueWithPointer:target]);
        return;
    }
    [(ARTOSReachability *)instance internalCallback:flags & kSCNetworkReachabilityFlagsReachable];
}

- (void)listenForHost:(NSString *)host callback:(void (^)(BOOL))callback {
    [self off];
    _host = host;
    _callback = callback;

    _reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};

    @synchronized (ARTOSReachability_instances) {
        [ARTOSReachability_instances setObject:self forKey:[NSValue valueWithPointer:_reachabilityRef]];
        if (SCNetworkReachabilitySetCallback(_reachabilityRef, ARTOSReachability_Callback, &context)) {
            if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
                [_logger info:@"Reachability: started listening for host %@", _host];
            } else {
                [_logger warn:@"Reachability: failed starting listener for host %@", _host];
            }
        } else {
            [ARTOSReachability_instances removeObjectForKey:[NSValue valueWithPointer:_reachabilityRef]];
        }
    }
}

- (void)off {
    if (_reachabilityRef != NULL) {
        @synchronized (ARTOSReachability_instances) {
            [ARTOSReachability_instances removeObjectForKey:[NSValue valueWithPointer:_reachabilityRef]];
        }
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        [_logger info:@"Reachability: stopped listening for host %@", _host];
    }
    _callback = nil;
    _host = nil;
}

- (void)internalCallback:(BOOL)reachable {
    [_logger info:@"Reachability: host %@: %d", _host, reachable];
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
