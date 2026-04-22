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
        #if SWIFT_PACKAGE
            if let version = getFromSPMBundle(sdkName: sdkName) { return version }
        #endif
        return getFromCocoaPodsBundle(sdkName: sdkName)
            ?? getFromCurrentBundle(sdkName: sdkName)
            ?? getFromResourceBundle(sdkName: sdkName)
            ?? getFromAllBundles(sdkName: sdkName)
            ?? getFromVersionFile(sdkName: sdkName)
            ?? "-"
    }

    // SPM bundle detection
    private func getFromSPMBundle(sdkName: String) -> String? {
        #if SWIFT_PACKAGE
            if let version = version(from: Bundle.module, sdkName: sdkName) { return version }
        #endif

        let spmName = sdkName.replacingOccurrences(of: "-", with: "_")
        let candidates = ["\(sdkName)_\(sdkName)", "\(spmName)_\(spmName)", sdkName, spmName]
        let searchRoots = ([Bundle.main, Bundle(for: type(of: self))] + Bundle.allFrameworks)
            .flatMap { [$0.resourceURL, Optional($0.bundleURL)] }
            .compactMap { $0 }

        for baseURL in searchRoots {
            for name in candidates {
                if let bundle = Bundle(url: baseURL.appendingPathComponent("\(name).bundle")),
                    let version = version(from: bundle, sdkName: sdkName)
                {
                    return version
                }
            }
        }
        return nil
    }

    // Reads version from <sdkName>Info.plist resource, falling back to the bundle's own Info.plist
    private func version(from bundle: Bundle, sdkName: String) -> String? {
        if let url = bundle.url(forResource: "\(sdkName)Info", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil)
                as? [String: Any],
            let version = dict["CFBundleShortVersionString"] as? String,
            !version.isEmpty
        {
            return version
        }
        return bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
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
            bundleId.contains(sdkName.lowercased())
        else { return nil }

        return bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    // Resource bundle detection
    private func getFromResourceBundle(sdkName: String) -> String? {
        let variations = [
            sdkName,
            "\(sdkName)-Core",
            "\(sdkName)_Core",
            sdkName.replacingOccurrences(of: "-", with: "_"),
        ]

        for name in variations {
            if let path = Bundle.main.path(forResource: name, ofType: "bundle"),
                let resourceBundle = Bundle(path: path),
                let version = resourceBundle.infoDictionary?["CFBundleShortVersionString"]
                    as? String
            {
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
                bundleId.contains(lowercaseSDK)
                    || bundleId.contains("org.cocoapods.\(lowercaseSDK)"),
                let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString")
                    as? String
            {
                return version
            }

            if bundle.bundlePath.contains(sdkName) || bundle.bundlePath.contains(altName),
                let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
            {
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
                    let content = try? String(contentsOfFile: path, encoding: .utf8)
                else { continue }

                let version = content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !version.isEmpty && version.count < 20 {
                    return version
                }
            }
        }
        return nil
    }
}
