// ObjC wrapper for AppsOnAir_Core Swift module.
// Uses runtime class lookup to avoid ObjC/Swift name conflict.
#import "AppsOnAir_Core-Swift.h"

@interface AppsOnAirCoreServices ()
// Stored as opaque `id` to avoid importing the Swift module and causing a
// redefinition conflict with the Swift-exported `AppsOnAirCoreServices`.
@property(nonatomic, strong) id swiftService;
@end

// Resolved once and shared by the class methods below. The instance methods keep
// using `swiftService`; the static members must not, because going through an
// instance would construct AppsOnAirCoreServices and start a Reachability observer.
static Class AppsOnAirCoreSwiftClass(void) {
    static Class swiftClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swiftClass = NSClassFromString(@"AppsOnAir_Core.AppsOnAirCoreServices");
        NSCAssert(swiftClass != nil,
                 @"AppsOnAir_Core framework must be linked. "
                 @"Make sure AppsOnAir_Core is added as a dependency.");
    });
    return swiftClass;
}

@implementation AppsOnAirCoreServices

- (instancetype)init {
    self = [super init];
    if (self) {
        // Resolve the Swift class at runtime to avoid a compile-time name conflict.
        Class swiftClass = NSClassFromString(@"AppsOnAir_Core.AppsOnAirCoreServices");
        NSAssert(swiftClass != nil,
                 @"AppsOnAir_Core framework must be linked. "
                 @"Make sure AppsOnAir_Core is added as a dependency.");
        _swiftService = [[swiftClass alloc] init];
    }
    return self;
}

- (void)initialize {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.swiftService performSelector:NSSelectorFromString(@"initialize")];
#pragma clang diagnostic pop
}

- (NSString *)appId {
    id value = [self.swiftService valueForKey:@"appId"];
    return value ?: @"";
}

- (NSNumber *)isNetworkConnected {
    return [self.swiftService valueForKey:@"isNetworkConnected"];
}

- (void)networkStatusListenerHandler:(void (^)(BOOL))handler {
    SEL sel = NSSelectorFromString(@"networkStatusListenerHandler:");
    NSMethodSignature *sig = [self.swiftService methodSignatureForSelector:sel];
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
    [inv setSelector:sel];
    [inv setTarget:self.swiftService];
    id block = ^(BOOL status) {
        if (handler) handler(status);
    };
    [inv setArgument:&block atIndex:2];
    [inv invoke];
}

- (void)getDeviceInfoWithAdditionalInfo:(NSDictionary *)additionalInfo
                             completion:(void (^)(NSDictionary *))completion {
    SEL sel = NSSelectorFromString(@"getDeviceInfoWithAdditionalInfo:completion:");
    NSMethodSignature *sig = [self.swiftService methodSignatureForSelector:sel];
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
    [inv setSelector:sel];
    [inv setTarget:self.swiftService];
    [inv setArgument:&additionalInfo atIndex:2];
    id block = ^(NSDictionary *result) {
        if (completion) completion(result);
    };
    [inv setArgument:&block atIndex:3];
    [inv invoke];
}

+ (NSString *)deviceId {
    Class swiftClass = AppsOnAirCoreSwiftClass();
    SEL sel = NSSelectorFromString(@"deviceId");
    if (![swiftClass respondsToSelector:sel]) return @"";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *value = [swiftClass performSelector:sel];
#pragma clang diagnostic pop
    return value ?: @"";
}

+ (NSString *)language {
    Class swiftClass = AppsOnAirCoreSwiftClass();
    SEL sel = NSSelectorFromString(@"language");
    if (![swiftClass respondsToSelector:sel]) return @"";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *value = [swiftClass performSelector:sel];
#pragma clang diagnostic pop
    return value ?: @"";
}

+ (NSString *)rawDeviceModel {
    Class swiftClass = AppsOnAirCoreSwiftClass();
    SEL sel = NSSelectorFromString(@"rawDeviceModel");
    if (![swiftClass respondsToSelector:sel]) return @"";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *value = [swiftClass performSelector:sel];
#pragma clang diagnostic pop
    return value ?: @"";
}

+ (NSDictionary<NSString *, id> *)getDeviceMetadata {
    Class swiftClass = AppsOnAirCoreSwiftClass();
    SEL sel = NSSelectorFromString(@"getDeviceMetadata");
    if (![swiftClass respondsToSelector:sel]) return @{};
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSDictionary *value = [swiftClass performSelector:sel];
#pragma clang diagnostic pop
    return value ?: @{};
}

@end
