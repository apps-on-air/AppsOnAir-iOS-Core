#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppsOnAirCoreServices : NSObject

/// Initialize SDK
- (void)initialize;

/// App ID
@property(nonatomic, readonly, copy) NSString *appId;

/// Current network connectivity state (NSNumber wrapping BOOL, nil if not yet determined)
@property(nonatomic, readonly, nullable) NSNumber *isNetworkConnected;

/// Listen to network status changes
- (void)networkStatusListenerHandler:(void (^)(BOOL isConnected))handler;

/// Get device info
- (void)getDeviceInfoWithAdditionalInfo:(NSDictionary *)additionalInfo
                             completion:(void (^)(NSDictionary *result))completion;

/// Persistent per-install device identifier. Backed by the same Keychain entry
/// reported as deviceInfo["deviceId"], so both routes return the same value.
@property(class, nonatomic, readonly, copy) NSString *deviceId;

/// Device language as an ISO 639-1 code (e.g. "en").
@property(class, nonatomic, readonly, copy) NSString *language;

/// Cheap, synchronous device facts. Must be called on the main thread —
/// themeMode and fontScale read UIKit singletons. No apiLevel: Android-only.
+ (NSDictionary<NSString *, id> *)getDeviceMetadata;

@end

NS_ASSUME_NONNULL_END
