import Foundation

public enum LoggerLevel {
    case none
    case developer
    case internalLevel
}

public struct Logger {
    // !!!: TODO
    // Set enum from internal to developer for pod distribution
    // Set the logging level for the application
    public static var logLevel: LoggerLevel = .developer

    // Unified logging method
    private static func log(_ message: String, level: LoggerLevel, prefix: String) {
        if logLevel == .internalLevel || (logLevel == .developer && level == .developer) {
            print("\(prefix): \(message)")
        }
    }

    // Log developer-level information (SDK | Pod users)
    public static func logInfo(_ message: String, prefix: String? = nil) {
        let logInfoPrefix = prefix ?? "AppsOnAirCore"
        log(message, level: .developer, prefix: logInfoPrefix)
    }


    // Log internal-level information (Internal development team)
    public static func logInternal(_ message: String) {
        log(message, level: .internalLevel, prefix: "INTERNAL")
    }
    
    public static func throwError(domainName: String? = nil,message: String? = nil,errorCode: Int? = nil) {
        let domain = domainName ?? "AppsOnAirCoreError"
        let msg = message ?? "Something went wrong"
        let code = errorCode ?? 0
        let throwNSError = NSError.init(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey:msg])
        logInfo("\(throwNSError.localizedDescription)")
    }
}
