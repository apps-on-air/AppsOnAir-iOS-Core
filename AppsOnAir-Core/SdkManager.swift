import Foundation

@objcMembers public final class SdkManager: NSObject {
    
    public static let shared = SdkManager()
    private var cachedVersions = [String: String]()
    
    private override init() {}
    
    public func getVersion(for sdkName: String) -> String {
        if let cached = cachedVersions[sdkName] {
            return cached
        }
        let version = resolveVersion(for: sdkName)
        cachedVersions[sdkName] = version
        return version
    }
    
    private func resolveVersion(for sdkName: String) -> String {
        return getFromCocoaPodsBundle(sdkName: sdkName)
            ?? getFromCurrentBundle(sdkName: sdkName)   
            ?? getFromResourceBundle(sdkName: sdkName)
            ?? getFromAllBundles(sdkName: sdkName)
            ?? getFromVersionFile(sdkName: sdkName)
            ?? "-"
    }
    
    // CocoaPods bundle detection
    private func getFromCocoaPodsBundle(sdkName: String) -> String? {
        Bundle(identifier: "org.cocoapods.\(sdkName)")?
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    // Current SDK bundle detection
    private func getFromCurrentBundle(sdkName: String) -> String? {
        let bundle = Bundle(for: type(of: self))
        guard bundle != .main,
              let bundleId = bundle.bundleIdentifier?.lowercased(),
              bundleId.contains(sdkName.lowercased()) else { return nil }
        
        return bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    // Resource bundle detection 
    private func getFromResourceBundle(sdkName: String) -> String? {
        let variations = [
            sdkName,
            "\(sdkName)-Core",
            "\(sdkName)_Core",
            sdkName.replacingOccurrences(of: "-", with: "_")
        ]
        
        for name in variations {
            if let path = Bundle.main.path(forResource: name, ofType: "bundle"),
               let resourceBundle = Bundle(path: path),
               let version = resourceBundle.infoDictionary?["CFBundleShortVersionString"] as? String {
                return version
            }
        }
        return nil
    }
    
    // Search all loaded bundles
    private func getFromAllBundles(sdkName: String) -> String? {
        let lowercaseSDK = sdkName.lowercased()
        let altName = sdkName.replacingOccurrences(of: "-", with: "_")
        
        for bundle in Bundle.allBundles + Bundle.allFrameworks {
            guard bundle != .main else { continue }
            
            if let bundleId = bundle.bundleIdentifier?.lowercased(),
               (bundleId.contains(lowercaseSDK) || bundleId.contains("org.cocoapods.\(lowercaseSDK)")),
               let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                return version
            }
            
            if bundle.bundlePath.contains(sdkName) || bundle.bundlePath.contains(altName),
               let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String {
                return version
            }
        }
        return nil
    }
    
    // Version file detection
    private func getFromVersionFile(sdkName: String) -> String? {
        let bundles = [Bundle(for: type(of: self)), .main]
        let fileNames = ["\(sdkName)Version", "SDKVersion", "Version"]
        
        for bundle in bundles {
            for fileName in fileNames {
                guard let path = bundle.path(forResource: fileName, ofType: "txt"),
                      let content = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
                
                let version = content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !version.isEmpty && version.count < 20 {
                    return version
                }
            }
        }
        return nil
    }
}
