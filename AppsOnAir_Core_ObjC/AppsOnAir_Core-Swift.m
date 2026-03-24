// ObjC wrapper for AppsOnAir_Core Swift module.
// Uses runtime class lookup to avoid ObjC/Swift name conflict.
#import "AppsOnAir_Core-Swift.h"

@interface AppsOnAirCoreServices ()
// Stored as opaque `id` to avoid importing the Swift module and causing a
// redefinition conflict with the Swift-exported `AppsOnAirCoreServices`.
@property(nonatomic, strong) id swiftService;
@end

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

@end
