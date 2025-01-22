import Foundation

/// helps to fetch the information from Bundle
extension Bundle {

    // help to get releaseVersionNumber from project's info.plist
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }

    // help to get buildVersionNumber from project's info.plist
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
    // help to get appName from project's info.plist
    var appName : String? {
        return infoDictionary?["CFBundleDisplayName"] as? String
    }
}
