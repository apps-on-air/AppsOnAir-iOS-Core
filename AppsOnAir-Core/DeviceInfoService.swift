#if canImport(UIKit)
    import Foundation
    import UIKit
    import Network
    import CoreTelephony
    import StoreKit

    // help to get device information

    internal class DeviceInfoService {

        var appInfo = [String: Any]()
        var deviceInfo = [String: Any]()
        var systemInfo = [String: Any]()

        internal func getDeviceInfo(
            additionalInfo: [String: Any] = [:], completion: @escaping ([String: Any]) -> Void
        ) {
            var appInfo: [String: Any] = [:]
            var deviceInfo: [String: Any] = [:]
            var systemInfo: [String: Any] = [:]

            let dispatchGroup = DispatchGroup()

            // App Info
            if let bundle = Bundle.main.bundleIdentifier {
                appInfo["bundleIdentifier"] = bundle
            }
            appInfo["releaseVersionNumber"] = Bundle.main.releaseVersionNumber ?? ""
            appInfo["buildVersionNumber"] = Bundle.main.buildVersionNumber ?? ""
            appInfo["appsOnAirCoreVersion"] = SdkManager.shared.getVersion(for: "AppsOnAir-Core")
            appInfo["appName"] = Bundle.main.appName ?? ""

            if !additionalInfo.isEmpty {
                appInfo.merge(additionalInfo) { current, _ in current }
            }

            UIDevice.current.isBatteryMonitoringEnabled = true

            // Device Info
            deviceInfo["deviceModel"] = getDeviceModel()
            deviceInfo["deviceOsVersion"] = UIDevice.current.systemVersion
            deviceInfo["deviceId"] = DeviceUID.uid()

            #if targetEnvironment(simulator)
                let batteryLevelString = "100%"
            #else
                let batteryLevelRaw = UIDevice.current.batteryLevel
                let batteryLevelString =
                    batteryLevelRaw < 0 ? "Unknown" : "\(Int(batteryLevelRaw * 100))%"
            #endif

            deviceInfo["deviceBatteryLevel"] = batteryLevelString
            deviceInfo["batteryStatus"] = getCurrentBatteryStatus()
            deviceInfo["deviceMemory"] = getDeviceMemory()
            deviceInfo["appMemoryUsage"] = "\(getAppMemoryUsage())"

            // Region Info
            let region = getDeviceRegion()
            deviceInfo["deviceRegionCode"] = region.code
            deviceInfo["deviceRegionName"] = region.name
            deviceInfo["language"] = getDeviceLanguage()

            // Storage Info
            let storage = getDeviceStorage()
            deviceInfo["deviceTotalStorage"] = storage?.total ?? ""
            deviceInfo["deviceUsedStorage"] = storage?.used ?? ""

            // Screen Size
            let screen = getDeviceScreenSize()
            deviceInfo["deviceScreenSize"] = "\(screen.width)x\(screen.height)"

            // Orientation
            let deviceOrientation: String = {
                if #available(iOS 13.0, *),
                    let orientation =
                        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                        .windows.first?.windowScene?.interfaceOrientation
                {
                    return orientation.isLandscape ? "Landscape" : "Portrait"
                }
                return UIDevice.current.orientation.isLandscape ? "Landscape" : "Portrait"
            }()

            deviceInfo["deviceOrientation"] = deviceOrientation
            deviceInfo["timezone"] = TimeZone.current.identifier
            deviceInfo["networkState"] = currentNetworkState
            deviceInfo["brand"] = "Apple"
            deviceInfo["manufacturer"] = "Apple"
            deviceInfo["platform"] = UIDevice.current.systemName
            deviceInfo["firstInstallTime"] = getAppInstallationDate()
            deviceInfo["isSimulator"] = isSimulator

            // Async network info
            dispatchGroup.enter()
            getNetworkInfo { networkName in
                deviceInfo["networkType"] = networkName
                dispatchGroup.leave()
            }

            // Completion after async calls
            dispatchGroup.notify(queue: .main) {
                systemInfo["deviceInfo"] = deviceInfo
                systemInfo["appInfo"] = appInfo

                Logger.logInternal("Device Info: \(deviceInfo)")
                completion(systemInfo)
            }
        }

        // MARK: - Helper Methods

        /// fetch the current network information like 2G,3G,4G,5G
        internal func getNetworkInfo(completion: @escaping (String) -> Void) {
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "NetworkMonitorQueue")

            monitor.pathUpdateHandler = { path in
                monitor.cancel()

                // No Internet
                guard path.status == .satisfied else {
                    completion("No Connection")
                    return
                }

                #if targetEnvironment(simulator)
                    completion("Unknown")
                #else
                    // Wi-Fi
                    if path.usesInterfaceType(.wifi) {
                        completion("Wi-Fi")
                        return
                    }

                    // Cellular
                    if path.usesInterfaceType(.cellular) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            let info = CTTelephonyNetworkInfo()
                            let radioTech: String?

                            if #available(iOS 12.0, *) {
                                radioTech = info.serviceCurrentRadioAccessTechnology?.values.first
                            } else {
                                radioTech = info.currentRadioAccessTechnology
                            }

                            guard let tech = radioTech else {
                                completion("Cellular (Unknown or No SIM)")
                                return
                            }

                            let networkType: String
                            if #available(iOS 14.1, *),
                                tech == CTRadioAccessTechnologyNR
                                    || tech == CTRadioAccessTechnologyNRNSA
                            {
                                networkType = "5G"
                            } else {
                                networkType =
                                    switch tech {
                                    case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge:
                                        "2G"
                                    case CTRadioAccessTechnologyWCDMA,
                                        CTRadioAccessTechnologyHSDPA,
                                        CTRadioAccessTechnologyHSUPA,
                                        CTRadioAccessTechnologyCDMA1x,
                                        CTRadioAccessTechnologyCDMAEVDORev0,
                                        CTRadioAccessTechnologyCDMAEVDORevA,
                                        CTRadioAccessTechnologyCDMAEVDORevB,
                                        CTRadioAccessTechnologyeHRPD:
                                        "3G"
                                    case CTRadioAccessTechnologyLTE: "4G"
                                    default: "Cellular (Unknown)"
                                    }
                            }

                            completion(networkType)
                        }
                        return
                    }

                    // Default fallback
                    completion("Unknown")
                #endif
            }

            monitor.start(queue: queue)
        }

        ///fetch App is install in Simulator or not
        internal var isSimulator: Bool {
            #if targetEnvironment(simulator)
                return true
            #else
                return false
            #endif
        }

        ///fetch the current power state
        internal func getCurrentBatteryStatus() -> String {
            #if targetEnvironment(simulator)
                return "Not Charging"
            #else
                let batteryStateDescription: String
                switch UIDevice.current.batteryState {
                case .unknown:
                    batteryStateDescription = "Battery state is unknown"
                case .unplugged:
                    batteryStateDescription = "Not Charging"
                case .charging:
                    batteryStateDescription = "Charging"
                case .full:
                    batteryStateDescription = "Fully Charged"
                @unknown default:
                    batteryStateDescription = "Unknown power state"
                }

                return batteryStateDescription
            #endif
        }

        ///fetch App first install DateTime
        internal func formatDateToDeviceTimeZone(_ date: Date) -> String {
            let formatter = DateFormatter()

            // Use device's current timezone
            formatter.timeZone = TimeZone.current

            // Use consistent month abbreviations
            formatter.locale = Locale(identifier: "en_US_POSIX")

            // Force 12-hour format with AM/PM
            formatter.dateFormat = "dd-MMM-yyyy hh:mm:ss a"

            return formatter.string(from: date)
        }

        internal func getAppInstallationDate() -> String {
            if let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                .first?.path
            {
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: docPath)
                    if let installationDate = attributes[.creationDate] as? Date {
                        return formatDateToDeviceTimeZone(installationDate)
                    }
                } catch {
                    return "Unavailable"
                }
            }
            return "Unavailable"
        }

        ///get device model name
        internal func getDeviceNamesByCode() -> [String: String] {
            return [
                "iPhone1,1": "iPhone",  // (Original)
                "iPhone1,2": "iPhone 3G",
                "iPhone2,1": "iPhone 3GS",
                "iPhone3,1": "iPhone 4",  // (GSM)
                "iPhone3,2": "iPhone 4",
                "iPhone3,3": "iPhone 4",  // (CDMA)
                "iPhone4,1": "iPhone 4S",
                "iPhone5,1": "iPhone 5",
                "iPhone5,2": "iPhone 5",
                "iPhone5,3": "iPhone 5c",
                "iPhone5,4": "iPhone 5c",
                "iPhone6,1": "iPhone 5s",
                "iPhone6,2": "iPhone 5s",
                "iPhone7,1": "iPhone 6 Plus",
                "iPhone7,2": "iPhone 6",
                "iPhone8,1": "iPhone 6s",
                "iPhone8,2": "iPhone 6s Plus",
                "iPhone8,4": "iPhone SE",
                "iPhone9,1": "iPhone 7",
                "iPhone9,2": "iPhone 7 Plus",
                "iPhone9,3": "iPhone 7",
                "iPhone9,4": "iPhone 7 Plus",
                "iPhone10,1": "iPhone 8",
                "iPhone10,2": "iPhone 8 Plus",
                "iPhone10,3": "iPhone X",
                "iPhone10,4": "iPhone 8",
                "iPhone10,5": "iPhone 8 Plus",
                "iPhone10,6": "iPhone X",
                "iPhone11,2": "iPhone XS",
                "iPhone11,4": "iPhone XS Max",
                "iPhone11,6": "iPhone XS Max",
                "iPhone11,8": "iPhone XR",
                "iPhone12,1": "iPhone 11",
                "iPhone12,3": "iPhone 11 Pro",
                "iPhone12,5": "iPhone 11 Pro Max",
                "iPhone12,8": "iPhone SE",
                "iPhone13,1": "iPhone 12 mini",
                "iPhone13,2": "iPhone 12",
                "iPhone13,3": "iPhone 12 Pro",
                "iPhone13,4": "iPhone 12 Pro Max",
                "iPhone14,2": "iPhone 13 Pro",
                "iPhone14,3": "iPhone 13 Pro Max",
                "iPhone14,4": "iPhone 13 mini",
                "iPhone14,5": "iPhone 13",
                "iPhone14,6": "iPhone SE",
                "iPhone14,7": "iPhone 14",
                "iPhone14,8": "iPhone 14 Plus",
                "iPhone15,2": "iPhone 14 Pro",
                "iPhone15,3": "iPhone 14 Pro Max",
                "iPhone15,4": "iPhone 15",
                "iPhone15,5": "iPhone 15 Plus",
                "iPhone16,1": "iPhone 15 Pro",
                "iPhone16,2": "iPhone 15 Pro Max",
                "iPhone17,1": "iPhone 16 Pro",
                "iPhone17,2": "iPhone 16 Pro Max",
                "iPhone17,3": "iPhone 16",
                "iPhone17,4": "iPhone 16 Plus",

                "iPod1,1": "iPod Touch",
                "iPod2,1": "iPod Touch",
                "iPod3,1": "iPod Touch",
                "iPod4,1": "iPod Touch",
                "iPod5,1": "iPod Touch",
                "iPod7,1": "iPod Touch",
                "iPod9,1": "iPod Touch",

                "iPad1,1": "iPad",
                "iPad1,2": "iPad 3G",
                "iPad2,1": "iPad 2",
                "iPad2,2": "iPad 2",
                "iPad2,3": "iPad 2",
                "iPad2,4": "iPad 2",
                "iPad3,1": "iPad",
                "iPad3,2": "iPad",
                "iPad3,3": "iPad",
                "iPad2,5": "iPad mini",
                "iPad2,6": "iPad mini",
                "iPad2,7": "iPad mini",
                "iPad3,4": "iPad",
                "iPad3,5": "iPad",
                "iPad3,6": "iPad",
                "iPad4,1": "iPad Air",
                "iPad4,2": "iPad Air",
                "iPad4,3": "iPad Air",
                "iPad4,4": "iPad Mini 2",
                "iPad4,5": "iPad Mini 2",
                "iPad4,6": "iPad Mini 2",
                "iPad4,7": "iPad Mini 3",
                "iPad4,8": "iPad Mini 3",
                "iPad4,9": "iPad Mini 3",
                "iPad5,1": "iPad Mini 4",
                "iPad5,2": "iPad Mini 4",
                "iPad5,3": "iPad Air 2",
                "iPad5,4": "iPad Air 2",
                "iPad6,3": "iPad Pro 9.7-inch",
                "iPad6,4": "iPad Pro 9.7-inch",
                "iPad6,7": "iPad Pro 12.9-inch",
                "iPad6,8": "iPad Pro 12.9-inch",
                "iPad6,11": "iPad (5th generation)",
                "iPad6,12": "iPad (5th generation)",
                "iPad7,1": "iPad Pro 12.9-inch",
                "iPad7,2": "iPad Pro 12.9-inch",
                "iPad7,3": "iPad Pro 10.5-inch",
                "iPad7,4": "iPad Pro 10.5-inch",
                "iPad7,5": "iPad (6th generation)",
                "iPad7,6": "iPad (6th generation)",
                "iPad7,11": "iPad (7th generation)",
                "iPad7,12": "iPad (7th generation)",
                "iPad8,1": "iPad Pro 11-inch (3rd generation)",
                "iPad8,2": "iPad Pro 11-inch (3rd generation)",
                "iPad8,3": "iPad Pro 11-inch (3rd generation)",
                "iPad8,4": "iPad Pro 11-inch (3rd generation)",
                "iPad8,5": "iPad Pro 12.9-inch (3rd generation)",
                "iPad8,6": "iPad Pro 12.9-inch (3rd generation)",
                "iPad8,7": "iPad Pro 12.9-inch (3rd generation)",
                "iPad8,8": "iPad Pro 12.9-inch (3rd generation)",
                "iPad8,9": "iPad Pro 11-inch (4th generation)",
                "iPad8,10": "iPad Pro 11-inch (4th generation)",
                "iPad8,11": "iPad Pro 12.9-inch (4th generation)",
                "iPad8,12": "iPad Pro 12.9-inch (4th generation)",
                "iPad11,1": "iPad Mini 5",
                "iPad11,2": "iPad Mini 5",
                "iPad11,3": "iPad Air 3rd Gen (WiFi)",
                "iPad11,4": "iPad Air (3rd generation)",
                "iPad11,6": "iPad Air (3rd generation)",
                "iPad11,7": "iPad (8th generation)",
                "iPad12,1": "iPad (9th generation)",
                "iPad12,2": "iPad (9th generation)",
                "iPad14,1": "iPad Mini (6th generation)",
                "iPad14,2": "iPad Mini (6th generation)",
                "iPad13,1": "iPad Air (4th generation)",
                "iPad13,2": "iPad Air (4th generation)",
                "iPad13,4": "iPad Pro 11-inch (5th generation)",
                "iPad13,5": "iPad Pro 11-inch (5th generation)",
                "iPad13,6": "iPad Pro 11-inch (5th generation)",
                "iPad13,7": "iPad Pro 11-inch (5th generation)",
                "iPad13,8": "iPad Pro 12.9-inch (5th generation)",
                "iPad13,9": "iPad Pro 11-inch (5th generation)",
                "iPad13,10": "iPad Pro 11-inch (5th generation)",
                "iPad13,11": "iPad Pro 11-inch (5th generation)",
                "iPad13,16": "iPad Air (5th generation)",
                "iPad13,17": "iPad Air (5th generation)",
                "iPad13,18": "iPad (10th generation)",
                "iPad13,19": "iPad (10th generation)",
                "iPad14,3": "iPad Pro 11-inch (4th generation)",
                "iPad14,4": "iPad Pro 11-inch (4th generation)",
                "iPad14,5": "iPad Pro 12.9-inch (6th generation)",
                "iPad14,6": "iPad Pro 12.9-inch (6th generation)",
                "iPad14,8": "iPad Air (6th generation)",
                "iPad14,9": "iPad Air (6th generation)",
                "iPad14,10": "iPad Air (7th generation)",
                "iPad14,11": "iPad Air (7th generation)",
                "iPad16,3": "iPad Pro 11-inch (5th generation)",
                "iPad16,4": "iPad Pro 11-inch (5th generation)",
                "iPad16,5": "iPad Pro 12.9-inch (7th generation)",
                "iPad16,6": "iPad Pro 12.9-inch (7th generation)",

                "AppleTV2,1": "Apple TV",
                "AppleTV3,1": "Apple TV",
                "AppleTV3,2": "Apple TV",
                "AppleTV5,3": "Apple TV",
                "AppleTV6,2": "Apple TV 4K",

                "RealityDevice14,1": "Apple Vision Pro",
            ]
        }

        /// Returns the `uname` machine string (e.g. "iPhone14,5") — a hardware model code,
        /// not a device identifier. Distinct from `deviceId`, which is the persistent
        /// per-install identifier provided by `DeviceUID`.
        internal func getHardwareIdentifier() -> String {
            var systemInfo = utsname()
            uname(&systemInfo)

            var hardwareId = withUnsafePointer(to: &systemInfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    String(validatingUTF8: $0) ?? "unknown"
                }
            }

            #if targetEnvironment(simulator)
                if let simModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]
                {
                    hardwareId = simModelIdentifier
                }
            #endif

            return hardwareId
        }

        internal func getDeviceModel() -> String {
            let hardwareId = getHardwareIdentifier()
            let deviceNamesByCode = getDeviceNamesByCode()
            if let deviceName = deviceNamesByCode[hardwareId] {
                return deviceName
            }

            if hardwareId.hasPrefix("iPod") {
                return "iPod Touch"
            } else if hardwareId.hasPrefix("iPad") {
                return "iPad"
            } else if hardwareId.hasPrefix("iPhone") {
                return "iPhone"
            } else if hardwareId.hasPrefix("AppleTV") {
                return "Apple TV"
            } else if hardwareId.hasPrefix("RealityDevice") {
                return "Apple Vision"
            }

            return "unknown"
        }

        ///get Device Memory
        internal func getDeviceMemory() -> String {
            var size: UInt64 = 0
            var sizeOfSize = MemoryLayout<UInt64>.size
            let result = sysctlbyname("hw.memsize", &size, &sizeOfSize, nil, 0)

            if result == 0 {
                return formatMemorySize(size)  // Convert to readable format (e.g., GB)
            } else {
                return "Unknown"
            }
        }

        ///get Screen Size
        internal func getDeviceScreenSize() -> CGSize {
            return UIScreen.main.bounds.size
        }

        ///Get Region Code and Name
        internal func getDeviceRegion() -> (code: String, name: String) {
            let locale = Locale.autoupdatingCurrent
            var regionCode = ""
            if #available(iOS 16.0, *) {
                regionCode = locale.region?.identifier ?? "Unknown"
            } else {
                regionCode = locale.regionCode ?? "Unknown"
            }
            let regionName = locale.localizedString(forRegionCode: regionCode) ?? "Unknown"
            return (regionCode, regionName)
        }

        /// ISO 639-1 language code (e.g. "en"). Android Core normalizes Java's obsolete
        /// codes ("iw", "in", "ji") so that both platforms report the same value.
        internal func getDeviceLanguage() -> String {
            let locale = Locale.autoupdatingCurrent
            if #available(iOS 16.0, *) {
                return locale.language.languageCode?.identifier ?? "en"
            } else {
                return locale.languageCode ?? "en"
            }
        }

        /// Cheap, synchronous device facts, bundled for callers that need several at once.
        ///
        /// Deliberately excludes anything the async path provides — `networkType` is the only
        /// field in `getDeviceInfo` that needs a callback — so this stays safe to call from a
        /// synchronous payload builder. The non-trivial reads are `firstInstallTime` (a
        /// filesystem stat) and `installVendor` (a bundle lookup).
        ///
        /// IMPORTANT: `themeMode` and `fontScale` read `UIApplication.shared` and
        /// `UIScreen.main`, so this must be called on the main thread. Android Core's
        /// equivalent has no such requirement.
        ///
        /// No `apiLevel`: that field is Android-only.
        /// Primary locale as language_REGION (e.g. "en_IN"). Ported from AppRemark iOS's
        /// `fetchLocaleDetails()`. Overlaps `language` + `regionCode`, the same facts split apart.
        internal func getDeviceLocale() -> String {
            let preferredLocaleIdentifier = Locale.preferredLanguages.first ?? "unknown"
            let preferredLocale = Locale(identifier: preferredLocaleIdentifier)

            let preferredLanguage: String
            let preferredRegion: String

            if #available(iOS 16.0, *) {
                preferredLanguage = preferredLocale.language.languageCode?.identifier ?? "unknown"
                preferredRegion = preferredLocale.region?.identifier ?? "unknown"
            } else {
                preferredLanguage = preferredLocale.languageCode ?? "unknown"
                preferredRegion = preferredLocale.regionCode ?? "unknown"
            }

            return "\(preferredLanguage)_\(preferredRegion)"
        }

        /// Interface style. Ported from AppRemark iOS's `fetchThemeMode()`.
        ///
        /// Reads `UIApplication.shared`, so it must be called on the main thread. Note the
        /// vocabulary differs from Android Core's, which reports "undefined" rather than
        /// "Unspecified" for the unset case.
        internal func getThemeMode() -> String {
            let traitCollection: UITraitCollection?

            if #available(iOS 13.0, *) {
                traitCollection =
                    (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                    .windows.first?.traitCollection
            } else {
                // Scenes do not exist before iOS 13, but `userInterfaceStyle` does (iOS 12+),
                // so the style is still readable through the key window.
                traitCollection = UIApplication.shared.keyWindow?.traitCollection
            }

            switch traitCollection?.userInterfaceStyle {
            case .dark:
                return "dark"
            case .light:
                return "light"
            default:
                return "Unspecified"
            }
        }

        /// Font scale, 1.0 being the default. Ported from AppRemark iOS's `fetchFontScale()`,
        /// which maps the content-size category onto Android's numeric scale.
        ///
        /// Reads `UIScreen.main`, so it must be called on the main thread.
        internal func getFontScale() -> Float {
            var fontScale: Float = 1.0

            #if !os(visionOS)
                let contentSizeCategory = UIScreen.main.traitCollection.preferredContentSizeCategory

                switch contentSizeCategory {
                case .extraSmall: fontScale = 0.82
                case .small: fontScale = 0.88
                case .medium: fontScale = 0.95
                case .large: fontScale = 1.0
                case .extraLarge: fontScale = 1.12
                case .extraExtraLarge: fontScale = 1.23
                case .extraExtraExtraLarge: fontScale = 1.35
                case .accessibilityMedium: fontScale = 1.64
                case .accessibilityLarge: fontScale = 1.95
                case .accessibilityExtraLarge: fontScale = 2.35
                case .accessibilityExtraExtraLarge: fontScale = 2.76
                case .accessibilityExtraExtraExtraLarge: fontScale = 3.12
                default: fontScale = 1.0
                }
            #endif

            // Round to 2 decimal places
            return (fontScale * 100).rounded() / 100
        }

        /// Store or sideload the app was installed from. Ported verbatim from AppRemark iOS's
        /// `fetchInstallVendor()` so the two report identical values. Note the vocabulary is
        /// NOT the same as Android Core's — iOS reports `appStore` / `testFlight` / `other`,
        /// Android reports store display names.
        internal func getInstallVendor() -> String {
            #if targetEnvironment(simulator) || os(macOS) || targetEnvironment(macCatalyst)
                return "other"
            #else
                // An embedded provisioning profile indicates Ad-Hoc / enterprise distribution.
                if hasEmbeddedMobileProvision() {
                    return "other"
                }

                if isAppStoreReceiptSandbox() {
                    return "testFlight"
                }

                return "appStore"
            #endif
        }

        private func hasEmbeddedMobileProvision() -> Bool {
            return Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil
        }

        private func isAppStoreReceiptSandbox() -> Bool {
            #if targetEnvironment(simulator)
                return false
            #else
                guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
                    return false
                }
                return appStoreReceiptURL.lastPathComponent == "sandboxReceipt"
            #endif
        }

        internal func getDeviceMetadata() -> [String: Any] {
            var metadata: [String: Any] = [:]
            metadata["deviceId"] = DeviceUID.uid()
            metadata["language"] = getDeviceLanguage()
            metadata["osVersion"] = UIDevice.current.systemVersion
            metadata["timezone"] = TimeZone.current.identifier
            metadata["regionCode"] = getDeviceRegion().code
            metadata["appVersion"] = Bundle.main.releaseVersionNumber ?? ""
            metadata["buildVersionNumber"] = Bundle.main.buildVersionNumber ?? ""
            metadata["platform"] = UIDevice.current.systemName
            metadata["locale"] = getDeviceLocale()
            metadata["themeMode"] = getThemeMode()
            metadata["fontScale"] = getFontScale()
            metadata["deviceModel"] = getDeviceModel()
            metadata["manufacturer"] = "Apple"
            metadata["installVendor"] = getInstallVendor()
            metadata["isSimulator"] = isSimulator
            metadata["firstInstallTime"] = getAppInstallationDate()
            return metadata
        }

        // convert byte into (GB,KB,MB) according the size
        internal func formatMemorySize(_ sizeInBytes: UInt64) -> String {
            let bytes = Double(sizeInBytes)

            let gb = bytes / 1_000_000_000
            if gb >= 1 {
                return String(format: "%.1f GB", gb)
            }

            let mb = bytes / 1_000_000
            if mb >= 1 {
                return String(format: "%.1f MB", mb)
            }

            let kb = bytes / 1_000
            return String(format: "%.1f KB", kb)
        }

        // help to fetch device storage
        internal func getDeviceStorage() -> (total: String, used: String, free: String)? {
            do {
                // Total size (unchanged)
                let attrs = try FileManager.default.attributesOfFileSystem(
                    forPath: NSHomeDirectory())
                guard let totalSize = attrs[.systemSize] as? UInt64 else { return nil }

                // Free size (matches Settings “Available”)
                let freeSize =
                    try URL(fileURLWithPath: NSHomeDirectory())
                    .resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                    .volumeAvailableCapacityForImportantUsage ?? 0

                let usedSize = totalSize - UInt64(freeSize)

                return (
                    total: formatMemorySize(totalSize),
                    used: formatMemorySize(usedSize),
                    free: formatMemorySize(UInt64(freeSize))
                )
            } catch {
                print("Error fetching storage info: \(error)")
                return nil
            }
        }

        // help to fetch app using memory
        internal func getAppMemoryUsage() -> String {
            var info = task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size) / 4

            // Get memory usage information of the current app
            let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), $0, &count)
                }
            }

            // If successful, format the memory usage values
            if result == KERN_SUCCESS {
                let usedMemory = UInt64(info.resident_size)
                return formatMemorySize(usedMemory)
            } else {
                return "unavailable"
            }
        }
    }
#endif
