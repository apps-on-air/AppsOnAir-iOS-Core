#if canImport(UIKit)
    import UIKit
    import AVFoundation

    @objc public class AppsOnAirCoreServices: NSObject, NetworkServiceDelegate {

        //MARK: - Declarations
        private var window: UIWindow?

        /// help to provide AppID in other AppsOnAir's SDKs [ForceUpdate | Feedback | DeepLink]
        //  private var appId: String = ""
        private var _appId: String = ""

        // Computed property with getter and setter for appId
        public var appId: String {
            get {
                return _appId
            }
            set {
                _appId = newValue
            }
        }

        /// initialize network connectivity service.
        var networkService: NetworkService = ReachabilityNetworkService()

        // Closure type for network status change handler
        public typealias NetworkStatusChangeHandler = (Bool) -> Void

        private var networkStatusChangeHandler: NetworkStatusChangeHandler?

        /// provide flags for internet connectivity
        public var isNetworkConnected: Bool? = nil

        /// display message while developer forgot to add AppId in project info.plist file
        private var errorMessage: String =
            "AppsOnAir AppId is Not initialized for more details: https://documentation.appsonair.com/MobileQuickstart/GettingStarted"  // !!!: Developer Guideline URL

        //MARK: - Methods
        /// initialize AppsOnAir basic services.
        @objc public func initialize() {
            // To initialize the network services delegate
            networkService.delegate = self
            networkService.startMonitoring()
            fetchAppId()
        }

        /// Fetch AppId from project's info.plist
        @objc private func fetchAppId() {
            // Method to fetch appId from the info.plist
            self._appId =
                Bundle.main.infoDictionary?["AppsonairAppId"] as? String ?? Bundle.main
                .infoDictionary?["AppsOnAirAPIKey"] as? String ?? ""
            if self._appId.isEmpty {
                #if DEBUG
                    // In debug mode or during development, the developer will get a crash if the AppId is not set up in the Info.plist file.
                    Logger.throwError(message: errorMessage)
                    exit(-1)
                #else
                    Logger.throwError(message: errorMessage)
                    self._appId = ""  // Clear the appId in release mode
                #endif
            }
        }

        ///get device information
        @objc public func getDeviceInfo(
            additionalInfo: [String: Any] = [:], completion: @escaping ([String: Any]) -> Void
        ) {
            DispatchQueue.main.async {
                let deviceInfo = DeviceInfoService()
                deviceInfo.getDeviceInfo(additionalInfo: additionalInfo) { deviceInfo in
                    completion(deviceInfo)
                }
            }
        }

        /// Persistent per-install device identifier.
        ///
        /// Static and synchronous by design: unlike `getDeviceInfo(additionalInfo:completion:)`,
        /// which must wait on a network-path callback before its dictionary is complete, this
        /// value comes from Keychain/UserDefaults reads only and is available immediately.
        /// Callers that assemble a payload synchronously depend on that. Being static also
        /// avoids constructing an `AppsOnAirCoreServices` instance, which starts a Reachability
        /// observer as a side effect.
        ///
        /// Backed by the same `DeviceUID` entry reported as `deviceInfo["deviceId"]`, so both
        /// routes always return the same value.
        @objc public static var deviceId: String { DeviceUID.uid() }

        /// Device language as an ISO 639-1 code (e.g. "en").
        ///
        /// Static and synchronous for the same reason as `deviceId` — callers that build a
        /// payload synchronously cannot wait on `getDeviceInfo`'s completion. Reports the same
        /// value as `deviceInfo["language"]`.
        @objc public static var language: String { DeviceInfoService().getDeviceLanguage() }

        /// Cheap, synchronous device facts, bundled for callers that need several at once —
        /// everything the Push and AppRemark SDKs need from Core: `deviceId`, `language`,
        /// `locale`, `regionCode`, `osVersion`, `platform`, `timezone`, `deviceModel`,
        /// `manufacturer`, `appVersion`, `buildVersionNumber`, `themeMode`, `fontScale`,
        /// `isSimulator`, `firstInstallTime` and `installVendor`.
        ///
        /// Must be called on the main thread — `themeMode` and `fontScale` read UIKit
        /// singletons. No `apiLevel`: Android-only.
        ///
        /// Static and synchronous by design: `getDeviceInfo(additionalInfo:completion:)` must
        /// wait on a network-path callback for `networkType`, so a caller assembling a payload
        /// synchronously cannot use it. Nothing here touches storage, memory, battery or the
        /// network. Individual fields are also available via `deviceId` and `language`.
        ///
        /// No `apiLevel` — Android-only. Intended for the Push and AppRemark SDKs.
        @objc public static func getDeviceMetadata() -> [String: Any] {
            DeviceInfoService().getDeviceMetadata()
        }

        /// helps to listen internet connectivity state
        @objc internal func networkStatusDidChange(status: Bool) {
            if isNetworkConnected != status {
                isNetworkConnected = status
                networkStatusChangeHandler?(status)
            }
        }
        /// Method to set the network status change handler
        @objc public func networkStatusListenerHandler(
            _ handler: @escaping NetworkStatusChangeHandler
        ) {
            networkStatusChangeHandler = handler
        }
    }
#endif
