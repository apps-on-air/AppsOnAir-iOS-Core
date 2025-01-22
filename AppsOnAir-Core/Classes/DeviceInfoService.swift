import Foundation
import UIKit

// help to get device information

class DeviceInfoService {
    
    var appInfo = [String: Any]()
    var deviceInfo = [String: Any]()
    var systemInfo = [String: Any]()
    
    func getDeviceInfo(additionalInfo: [String:Any] = [:])->[String:Any]{

        appInfo["bundleIdentifier"] = Bundle.main.bundleIdentifier
        appInfo["releaseVersionNumber"] = Bundle.main.releaseVersionNumber
        appInfo["buildVersionNumber"] = Bundle.main.buildVersionNumber
        appInfo["appsOnAirCoreVersion"] = self.getPodVersion()
        appInfo["appName"] = Bundle.main.appName ?? ""
        
        // Add additionalInfo in appInfo
        if(additionalInfo.count != 0 ){
            appInfo.merge(additionalInfo) { (current, _) in current } // Merges the dictionaries
        }
        
        //Get Battery Level for necessary to enable
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Device Model
        let deviceModel = UIDevice.current.model
           
        deviceInfo["deviceModel"] = "\(deviceModel)"
        
        // OS Version
        deviceInfo["deviceOsVersion"] = UIDevice.current.systemVersion
            
        // Battery Level
        let batteryLevel = UIDevice.current.batteryLevel * 100
        deviceInfo["deviceBatteryLevel"] =  "\(batteryLevel)%"
           
        // Device Memory
        deviceInfo["deviceMemory"] =  getDeviceMemory()
        
        // Get the used memory by the app
        let usedMemoryInMB = getAppMemoryUsage()
        deviceInfo["appMemoryUsage"] = "\(usedMemoryInMB)"
        
        // Get Region Code and Name
         let countryCode = getDeviceRegion()
        deviceInfo["deviceRegionCode"] = "\(countryCode.code)"
        deviceInfo["deviceRegionName"] = "\(countryCode.name)"
        
        // Get Device Storage
        let storageInfo = getDeviceStorage()
       
        //total storage
        deviceInfo["deviceTotalStorage"] = storageInfo.total
        
        //used storage
        deviceInfo["deviceUsedStorage"] = storageInfo.used
        
        // Screen Size
        let screenMode = getDeviceScreenSize()
        deviceInfo["deviceScreenSize"] = "\(screenMode.width)x\(screenMode.height)"

        // Screen orientation
        var deviceOrientation:String {
            if #available(iOS 13.0, *) {
                if let orientation = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.windowScene?.interfaceOrientation{
                    if orientation == .landscapeLeft || orientation == .landscapeRight {
                        return "Landscape"
                    }else if orientation == .portrait || orientation == .portraitUpsideDown {
                        return "Portrait"
                    }
                }
            }
            return UIDevice.current.orientation.isLandscape ? "Landscape":"Portrait"
        }
       
        deviceInfo["deviceOrientation"] =  deviceOrientation
        
        let timeZone = TimeZone.current.identifier
        
        // Current timezone
        deviceInfo["timezone"] = timeZone
        // Current network status
        deviceInfo["networkState"] = currentNetworkState
        
        systemInfo["deviceInfo"] = deviceInfo
        systemInfo["appInfo"] = appInfo

        Logger.logInternal("\("Device Info:") \(deviceInfo)")
        
        return systemInfo
    }
    
    /// get pod version
    @objc private func getPodVersion() -> String {
        let podVersion = Bundle(for: AppsOnAirCoreServices.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        Logger.logInternal(podVersion)
        return podVersion
    }
    
    ///get Device Memory
    func getDeviceMemory() -> String {
        var size: UInt64 = 0
        var sizeOfSize = MemoryLayout<UInt64>.size
        let result = sysctlbyname("hw.memsize", &size, &sizeOfSize, nil, 0)
        
        if result == 0 {
            return formatMemorySize(size) // Convert to readable format (e.g., GB)
        } else {
            return "Unknown"
        }
    }
    
    ///get Screen Size
    func getDeviceScreenSize() -> CGSize {
        return UIScreen.main.bounds.size
    }

    ///Get Region Code and Name
    func getDeviceRegion() -> (code: String, name: String) {
        let locale = Locale.current
        let regionCode = locale.regionCode ?? "Unknown"
        let regionName = locale.localizedString(forRegionCode: regionCode) ?? "Unknown"
        return (regionCode, regionName)
    }

    // convert byte into (GB,KB,MB) according the size
    func formatMemorySize(_ sizeInBytes: UInt64) -> String {
        if sizeInBytes >= (1024 * 1024 * 1024) {
            let sizeInGB = Double(sizeInBytes) / (1024 * 1024 * 1024)
            return String(format: "%.2f GB", sizeInGB)
        } else if sizeInBytes >= (1024 * 1024) {
            let sizeInMB = Double(sizeInBytes) / (1024 * 1024)
            return String(format: "%.2f MB", sizeInMB)
        } else {
            let sizeInKB = Double(sizeInBytes) / 1024
            return String(format: "%.2f KB", sizeInKB)
        }
    }
    
    // help to fetch device storage
    func getDeviceStorage() -> (total: String, used: String) {
        let fileManager = FileManager.default
        do {
            // Get file system attributes
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let totalSize = attributes[.systemSize] as? UInt64,
               let freeSize = attributes[.systemFreeSize] as? UInt64 {
                let usedSize = totalSize - freeSize

                // Convert and format total size
                let totalFormatted = formatMemorySize(totalSize)
                // Convert and format used size
                let usedFormatted = formatMemorySize(usedSize)

                return (totalFormatted, usedFormatted)
            }
        } catch {
            print("Error fetching storage info: \(error.localizedDescription)")
        }
        return ("Unavailable", "Unavailable")
    }
  
    
    // help to fetch app using memory
    func getAppMemoryUsage() -> String {
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
