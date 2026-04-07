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

@end

NS_ASSUME_NONNULL_END
