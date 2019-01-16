//
//  ARTSentry.m
//  Ably
//
//  Created by Toni Cárdenas on 04/05/2017.
//  Copyright © 2017 Ably. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARTSentry.h"
#import "ARTURLSessionServerTrust.h"
#import "ARTNSDate+ARTUtil.h"
#import "ARTDefault.h"
#import "ARTCrypto+Private.h"
#import "ARTNSArray+ARTFunctional.h"

#if COCOAPODS
#import <KSCrashAblyFork/KSCrash.h>
#import <KSCrashAblyFork/KSCrashInstallation+Private.h>
#import <KSCrashAblyFork/KSCrashMonitorType.h>
#import <KSCrashAblyFork/NSData+GZip.h>
#else
// Carthage
#import <KSCrash/KSCrash.h>
#import <KSCrash/KSCrashInstallation+Private.h>
#import <KSCrash/KSCrashMonitorType.h>
#import <KSCrash/NSData+GZip.h>
#endif

NSString* ART_hexMemoryAddress(id addr) {
    if (addr && [addr isKindOfClass:[NSString class]]) {
        return addr;
    }
    if (addr && [addr isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"0x%lx", (unsigned long)[addr unsignedIntegerValue]];
    }
    return nil;
}

void ART_withKSCrash(void (^f)(KSCrash *)) {
    static dispatch_queue_t q;
    static dispatch_once_t t;
    dispatch_once(&t, ^{
        q = dispatch_queue_create("io.ably.sentry.ART_withKSCrash", NULL);
    });
    dispatch_sync(q, ^{
        f([KSCrash sharedInstance]);
    });
}

@interface  ARTKSCrashReportFilter : NSObject<KSCrashReportFilter>
- (instancetype)init:(NSString *)dns;
@end

@implementation ARTKSCrashReportFilter {
    NSString *_dns;
    dispatch_queue_t _queue;
}

- (instancetype)init:(NSString *)dns {
    if (self = [super init]) {
        _dns = dns;
        _queue = dispatch_queue_create("io.ably.sentry", nil);
    }
    return self;
}

- (void)filterReports:(NSArray<NSDictionary *> *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion {
    if (!_dns) {
        // Deactivated; do nothing.
        onCompletion(reports, true, nil);
        return;
    }

    dispatch_sync(_queue, ^{
        NSMutableArray<NSMutableDictionary *> *events = [[NSMutableArray alloc] init];
        for (NSDictionary __strong *report in reports) {
            id recrash = report[@"recrash_report"];
            if (recrash) {
                report = (NSDictionary *)recrash;
            }
            NSArray<NSDictionary<NSString *, id> *> *binaryImagesDicts = (NSArray *)report[@"binary_images"];
            if (!binaryImagesDicts) {
                continue;
            }
            NSDictionary<NSString *, id> *crashDict = (NSDictionary *)report[@"crash"];
            if (!crashDict) {
                continue;
            }
            NSDictionary<NSString *, id> *errorDict = (NSDictionary *)crashDict[@"error"];
            if (!errorDict) {
                continue;
            }
            NSArray<NSDictionary<NSString *, id> *> *threadDicts = (NSArray *)crashDict[@"threads"];
            if (!threadDicts) {
                continue;
            }
            NSDictionary<NSString *, id> *userDict = report[@"user"];
            
            if (![userDict [@"reportToAbly"] boolValue]) {
                continue;
            }

            id eType = errorDict[@"type"];
            id eValue = errorDict[@"reason"];
            if ([eType isEqualToString:@"nsexception"]) {
                eType = errorDict[@"nsexception"][@"name"];
                eValue = errorDict[@"nsexception"][@"reason"];
                if (!eValue) {
                    eValue = errorDict[@"reason"];
                }
            } else if ([eType isEqualToString:@"mach"]) {
                eType = errorDict[@"mach"][@"exception_name"];
                eValue = [NSString stringWithFormat:@"Exception %@, Code %@, Subcode %@", errorDict[@"mach"][@"exception"], errorDict[@"mach"][@"code"], errorDict[@"mach"][@"subcode"]];
            } else if ([eType isEqualToString:@"signal"]) {
                eType = errorDict[@"signal"][@"name"];
                eValue = [NSString stringWithFormat:@"Signal %@, Code %@", errorDict[@"signal"][@"signal"], errorDict[@"signal"][@"code"]];
            } else {
                // Not from Ably.
                continue;
            }

            BOOL isFromAbly = false;
            NSMutableArray *frames = [[NSMutableArray alloc] init];
            NSString *culprit = nil;
            for (NSDictionary *threadDict in threadDicts) {
                if (!([threadDict[@"crashed"] boolValue])) {
                    continue;
                }
                for (NSDictionary *frameDict in (NSArray<NSDictionary *> *)threadDict[@"backtrace"][@"contents"]) {
                    if (!isFromAbly && [(NSString *)frameDict[@"symbol_name"] rangeOfString:@"ART"].location != NSNotFound) {
                        isFromAbly = true;
                    }
                    [frames addObject:@{
                        @"function": ART_orNull(frameDict[@"symbol_name"]),
                        @"instruction_addr": ART_orNull(ART_hexMemoryAddress(frameDict[@"instruction_addr"])),
                        @"symbol_addr": ART_orNull(ART_hexMemoryAddress(frameDict[@"symbol_addr"])),
                    }];
                }
                // TODO: https://github.com/getsentry/sentry-swift/blob/a05094d7727440a28e8f2a9bc5f863d67e1daf19/Sources/Thread.swift#L47
            }

            if (!isFromAbly) {
                continue;
            }

            if (crashDict[@"diagnosis"]) {
                eValue = crashDict[@"diagnosis"];
            }

            [events addObject:[[NSMutableDictionary alloc] initWithDictionary:@{
                @"message": @"",
                @"exception": @{
                    @"type": ART_orNull(eType),
                    @"value": ART_orNull(eValue),
                },
                @"stacktrace": @{
                    @"frames": frames,
                },
                @"timestamp": ART_orNull(report[@"report"][@"timestamp"]),
                @"debug_meta": @{
                    @"images": [binaryImagesDicts artMap:^NSDictionary *(NSDictionary *d) {
                        return @{
                            @"type": @"apple",
                            @"cpu_subtype": ART_orNull(d[@"cpu_subtype"]),
                            @"uuid": ART_orNull(d[@"uuid"]),
                            @"image_vmaddr": ART_orNull(ART_hexMemoryAddress(d[@"image_vmaddr"])),
                            @"image_addr": ART_orNull(ART_hexMemoryAddress(d[@"image_addr"])),
                            @"cpu_type": ART_orNull(d[@"cpu_type"]),
                            @"image_size": ART_orNull(d[@"image_size"]),
                            @"name": ART_orNull(d[@"name"]),
                            @"major_version": ART_orNull(d[@"major_version"]),
                            @"minor_version": ART_orNull(d[@"minor_version"]),
                            @"revision_version": ART_orNull(d[@"revision_version"]),
                        };
                    }],
                },
                @"culprit": ART_orNull(culprit),
                @"breadcrumbs": ART_orNull([ARTSentry flattenBreadcrumbs:userDict[@"sentryBreadcrumbs"]]),
                @"extra": ART_orNull(userDict[@"sentryExtra"]),
                @"tags":ART_orNull(userDict[@"sentryTags"]),
            }]];
        }

        NSLog(@"ARTSentry: sending %lu reports", (unsigned long)[events count]);
        [self sendEvents:events reports:reports success:true onCompletion:onCompletion];
    });
}

- (void)sendEvents:(NSMutableArray<NSMutableDictionary *> *)events reports:(NSArray<NSDictionary *> *)reports success:(BOOL)success onCompletion:(KSCrashReportFilterCompletion)onCompletion {
    NSMutableDictionary *event = [events lastObject];
    if (!event) {
        onCompletion(reports, success, nil);
        return;
    }
    [events removeLastObject];

    [ARTSentry report:event to:_dns callback:^(NSError *e) {
        if (e) {
            NSLog(@"ARTSentry: error sending report: %@", e);
        }
        [self sendEvents:events reports:reports success:success && e == nil onCompletion:onCompletion];
    }];
}

@end

@interface ARTKSCrashInstallation : KSCrashInstallation
- (instancetype)init:(NSString *)dns;
@end

@implementation ARTKSCrashInstallation {
    NSString *_dns;
}

- (instancetype)init:(NSString *)dns {
    if (self = [super initWithRequiredProperties:@[]]) {
        _dns = dns;
    }
    return self;
}

- (id<KSCrashReportFilter>)sink {
    return [[ARTKSCrashReportFilter alloc] init:_dns];
}


- (void)install {
    ART_withKSCrash(^(KSCrash *ksCrash) {
        ksCrash.monitoring = KSCrashMonitorTypeMachException | KSCrashMonitorTypeSignal | KSCrashMonitorTypeSystem | KSCrashMonitorTypeApplicationState;
    });
    [super install];
}
@end

@implementation ARTSentry

+ (BOOL)setCrashHandler:(NSString *_Nullable)dns {
    static ARTKSCrashInstallation *installation;
    __block BOOL installed = false;
    @synchronized (self) {
        installation = [[ARTKSCrashInstallation alloc] init:dns];
        [installation install];
        installed = true;
        [installation sendAllReportsWithCompletion:^(NSArray *reports, BOOL completed, NSError *error) {
            if (error) {
                NSLog(@"ARTSentry: error sending reports: %@", error);
                return;
            }
        }];
    }
    return installed;
}

NSString* ART_uuid() {
    NSMutableData *data = [ARTCrypto generateSecureRandomData:16];
    if (!data) {
        return nil;
    }
    uint8_t *bs = (uint8_t*)[data mutableBytes];
    bs[6] &= 0x0F; // clear version
    bs[6] |= 0x40; // set version to 4 (random uuid)
    bs[8] &= 0x3F; // clear variant
    bs[8] |= 0x80; // set to IETF variant
    NSMutableString *hex = [NSMutableString stringWithCapacity:16];
    for (int i = 0; i < 16; i++) {
        [hex appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)bs[i]]];
    }
    return [NSString stringWithString:hex];
}

+ (void)report:(NSString *)message to:(NSString *)dns extra:(NSDictionary *_Nullable)extra breadcrumbs:(NSArray<NSDictionary *> *_Nullable)breadcrumbs tags:(NSDictionary *)tags exception:(NSException *_Nullable)exception {
    [ARTSentry report:message to:dns extra:extra breadcrumbs:breadcrumbs tags:tags exception:exception callback:nil];
}

+ (void)report:(NSString *)message to:(NSString *)dns extra:(NSDictionary *_Nullable)extra breadcrumbs:(NSArray<NSDictionary *> *_Nullable)breadcrumbs tags:(NSDictionary *)tags exception:(NSException *_Nullable)exception callback:(void (^_Nullable)(NSError *_Nullable))callback {
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    body[@"message"] = message;
    body[@"extra"] = extra;
    body[@"breadcrumbs"] = breadcrumbs;
    body[@"tags"] = tags;

    if (exception) {
        body[@"exception"] = @{
           @"value": ART_orNull(exception.reason),
           @"type": ART_orNull(exception.name),
        };

        NSArray<NSString *> *trace = [exception callStackSymbols];
        NSString *pattern = @"[ \t]*[0-9]+[ \t]*([^ \t]+)[ \t]+([^ \t]+)[ \t]+(.+) \\+ ([0-9]+)";
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        NSMutableArray<NSDictionary *> *frames = [[NSMutableArray alloc] initWithCapacity:trace.count];
        NSString *culprit = nil;
        for (int i = (int)trace.count - 1; i >= 0; i--) {
            NSString *line = trace[i];
            NSTextCheckingResult *match = [regex firstMatchInString:line options:NSMatchingAnchored range:NSMakeRange(0, [line length])];
            if (!match || match.range.length == 0) {
                continue;
            }
            NSString *function = [NSString stringWithFormat:@"%@::%@", [line substringWithRange:[match rangeAtIndex:1]], [line substringWithRange:[match rangeAtIndex:3]]];
            [frames addObject:@{
                @"function": function,
                @"instruction_addr": ART_hexMemoryAddress([line substringWithRange:[match rangeAtIndex:4]]),
                @"symbol_addr": ART_hexMemoryAddress([line substringWithRange:[match rangeAtIndex:2]])
            }];
            if ([[line substringWithRange:[match rangeAtIndex:1]] isEqualToString:@"Ably"]) {
                culprit = function;
            }
        }
        body[@"stacktrace"] = @{@"frames": frames};
        if (culprit) {
            body[@"culprit"] = culprit;
        }
        extra = [[NSMutableDictionary alloc] initWithDictionary:extra];
        ((NSMutableDictionary *)extra)[@"userInfo"] = ART_orNull(exception.userInfo);
    }

    [ARTSentry report:body to:dns callback:callback];
}

+ (void)report:(NSMutableDictionary *)body to:(NSString *)dns callback:(void (^_Nullable)(NSError *_Nullable))callback {
    NSURL *dnsUrl = [NSURL URLWithString:dns];
    if (!dnsUrl) {
        [ARTSentry reportError:callback message:@"ARTSentry: logExceptionReportingUrl (%@) is not a valid URL; crash won't be reported", dns];
        return;
    }
    if (!dnsUrl.user || !dnsUrl.password) {
        [ARTSentry reportError:callback message:@"ARTSentry: logExceptionReportingUrl (%@) doesn't have public and secret key; crash won't be reported", dns];
        return;
    }
    NSString *authHeader = [NSString stringWithFormat:@"Sentry sentry_version=4, sentry_key=%@, sentry_secret=%@", dnsUrl.user, dnsUrl.password];
    NSString *projectID = [dnsUrl lastPathComponent];
    NSString *eventID = ART_uuid();

    body[@"event_id"] = ART_orNull(eventID);
    body[@"project"] = ART_orNull(projectID);
    body[@"timestamp"] = ART_orNull([[NSDate date] toSentryTimestamp]);
    body[@"level"] = @"error";
    body[@"platform"] = @"cocoa";
    body[@"release"] = [ARTDefault libraryVersion];

    body[@"breadcrumbs"] = [ARTSentry removeBreadcrumbSecrets:body[@"breadcrumbs"]];
    body[@"contexts"] = ART_deviceContexts();

    NSData *bodyData = nil;
    id jsonError = nil;
    @try {
        NSError *error = nil;
        bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
        jsonError = error;
    } @catch (NSException *exception) {
        jsonError = exception;
    }
    if (!bodyData) {
        [ARTSentry reportError:callback message:@"ARTSentry: error encoding crash report as JSON: %@", jsonError];
        return;
    }

    bodyData = [bodyData gzippedWithCompressionLevel:-1 error:nil];

    NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
    urlComponents.scheme = dnsUrl.scheme;
    urlComponents.host = dnsUrl.host;
    urlComponents.port = dnsUrl.port;
    urlComponents.path = [NSString stringWithFormat:@"/api/%@/store/", projectID];
    NSURL *url = [urlComponents URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    [request addValue:authHeader forHTTPHeaderField:@"X-Sentry-Auth"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:bodyData];

    if ([[NSProcessInfo processInfo].environment valueForKey:@"ARTUnitTests"]) {
        return;
    }

    ARTURLSessionServerTrust *session = [[ARTURLSessionServerTrust alloc] init];
    [session get:request completion:^(NSHTTPURLResponse *response, NSData *data, NSError *error) {
        if (error || !response) {
            NSLog(@"ARTSentry: error sending crash report: %@", error);
        } else if (response.statusCode >= 400) {
            NSLog(@"ARTSentry: error response from crash report: %ld, body: %@", (long)response.statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else {
            NSLog(@"ARTSentry: crash report sent successfully with ID %@", eventID);
        }
        if (callback) callback(error);
    }];
}

+ (void)reportError:(void (^_Nullable)(NSError *_Nullable))callback message:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    if (callback) {
        callback([NSError errorWithDomain:@"ARTSentry" code:0 userInfo:@{NSLocalizedDescriptionKey: message}]);
    } else {
        NSLog(@"%@", message);
    }
}

+ (void)setTags:(NSDictionary *)value {
    [ARTSentry setUserInfo:@"sentryTags" value:value];
}

+ (void)setExtras:(NSString *)key value:(id)value {
    [ARTSentry setUserInfo:@"sentryExtra" key:key value:ART_orNull(value)];
}

+ (void)setBreadcrumbs:(NSString *)key value:()value {
    // TODO: breadcrumbs are too big and KSCrash rejects them for crashes.
    // We can still use them when handling exceptions though.
    [ARTSentry setUserInfo:@"sentryBreadcrumbs" key:key value:[value artMap:^NSDictionary *(id<ARTSentryBreadcrumb> b) {
        return [b toBreadcrumb];
    }]];
}

+ (void)setUserInfo:(NSString *)key value:(id)value {
    ART_withKSCrash(^(KSCrash *ksCrash) {
        if (!ksCrash.userInfo) {
            ksCrash.userInfo = @{};
        }
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:ksCrash.userInfo];
        info[key] = value;
        ksCrash.userInfo = info;
    });
}

+ (void)setUserInfo:(NSString *)key key:(NSString *)innerKey value:(id)value {
    ART_withKSCrash(^(KSCrash *ksCrash) {
        if (!ksCrash.userInfo) {
            ksCrash.userInfo = @{};
        }
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:ksCrash.userInfo];
        NSMutableDictionary *inner;
        if (info[key]) {
            inner = [NSMutableDictionary dictionaryWithDictionary:info[key]];
        } else {
            inner = [[NSMutableDictionary alloc] init];
        }
        inner[innerKey] = value;
        info[key] = inner;
        ksCrash.userInfo = info;
    });
}

id ART_orNull(id obj) {
    return obj != nil ? obj : [NSNull null];
}

+ (NSArray *)removeBreadcrumbSecrets:(NSArray *)breadcrumbs {
    if (!breadcrumbs || ![breadcrumbs isKindOfClass:[NSArray class]]) {
        return breadcrumbs;
    }
    NSArray<NSRegularExpression *> *regexps = [@[
        @"([a-zA-Z0-9\\-_]+!)[a-zA-Z0-9\\-_]+", // connection key
        @"([a-zA-Z0-9\\-_]+\\.[a-zA-Z0-9\\-_]+:)[a-zA-Z0-9\\-_]+", // key
        @"([a-zA-Z0-9\\-_]+\\.)[a-zA-Z0-9\\-_]{20,}", // token
    ] artMap:^NSRegularExpression *(NSString *p) {
        return [NSRegularExpression regularExpressionWithPattern:p options:0 error:nil];
    }];
    return [breadcrumbs artMap:^NSDictionary *(NSDictionary *breadcrumb) {
        NSMutableDictionary *d = [[NSMutableDictionary alloc] initWithDictionary:breadcrumb];
        for (NSRegularExpression *r in regexps) {
            d[@"message"] = [r stringByReplacingMatchesInString:d[@"message"] options:0 range:NSMakeRange(0, [d[@"message"] length]) withTemplate:@"$1..."];
        }
        return d;
    }];
}

NSDictionary* ART_deviceContexts() {
    NSDictionary __block *info;
    ART_withKSCrash(^(KSCrash *ksCrash) {
        info = [ksCrash systemInfo];
    });

    NSString *model =
        #if TARGET_IPHONE_SIMULATOR
            [[[NSProcessInfo alloc] init] environment][@"SIMULATOR_MODEL_IDENTIFIER"]
        #elif TARGET_OS_MAC
            info[@"model"]
        #else
            info[@"machine"]
        #endif
    ;

    NSString *family = nil;
    if (model) {
        NSString *pattern = @"^\\D+";
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        family = [model substringWithRange:[regex firstMatchInString:model options:0 range:NSMakeRange(0, model.length)].range];
    }

    return @{
        @"os": @{
            @"name": ART_orNull(
                #if TARGET_OS_IOS
                    @"iOS"
                #elif TARGET_OS_TV
                    @"tvOS"
                #elif TARGET_OS_MAC
                    @"macOS"
                #elif TARGET_OS_WATCH
                    @"watchOS"
                #else
                    [NSNull null]
                #endif
            ),
            @"version": ART_orNull(info[@"systemVersion"]),
            @"build": ART_orNull(info[@"osVersion"]),
            @"kernel_version": ART_orNull(info[@"kernelVersion"]),
            @"rooted": ART_orNull(info[@"isJailbroken"]),
        },
        @"device": @{
            @"arch": ART_orNull(info[@"cpuArchitecture"]),
            @"model": ART_orNull(model),
            @"family": ART_orNull(family),
            @"free_memory": ART_orNull(info[@"freeMemory"]),
            @"memory_size": ART_orNull(info[@"memorySize"]),
            @"usable_memory": ART_orNull(info[@"usableMemory"]),
            @"storage_size": ART_orNull(info[@"storageSize"]),
            @"boot_time": ART_orNull(info[@"bootTime"]),
            @"timezone": ART_orNull(info[@"timezone"]),
        },
        @"app": @{
            @"app_start_time": ART_orNull(info[@"appStartTime"]),
            @"device_app_hash": ART_orNull(info[@"deviceAppHash"]),
            @"app_id": ART_orNull(info[@"appID"]),
            @"build_type": ART_orNull(info[@"buildType"]),
            @"app_identifier": ART_orNull(info[@"bundleID"]),
            @"app_name": ART_orNull(info[@"bundleName"]),
            @"app_build": ART_orNull(info[@"bundleVersion"]),
            @"app_version": ART_orNull(info[@"bundleShortVersion"]),
        },
    };
}

+ (NSArray<NSDictionary *> *)flattenBreadcrumbs:(NSDictionary<NSString *, NSArray<NSDictionary *> *> *)breadcrumbs {
    NSMutableArray *flattened = [[NSMutableArray alloc] init];
    for (NSString *k in breadcrumbs) {
        [flattened addObjectsFromArray:breadcrumbs[k]]; 
    }
    return flattened;
}

@end

