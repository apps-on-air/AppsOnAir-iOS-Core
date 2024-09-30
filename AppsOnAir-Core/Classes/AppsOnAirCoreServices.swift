

import UIKit
import AVFoundation

public class AppsOnAirCoreServices : NSObject, NetworkServiceDelegate {
    
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
    private var errorMessage:String = "AppsOnAir APIKey is Not initialized for more details: https://documentation.appsonair.com" // !!!: Developer Guideline URL
    
    
    
    //MARK: - Methods
    /// initialize AppsOnAir basic services.
    @objc public func initialize(){
        // To initialize the network services delegate
        networkService.delegate = self
        networkService.startMonitoring()
        fetchAppId()
    }
    
    /// Fetch AppId from project's info.plist
       @objc private func fetchAppId() {
            // Method to fetch appId from the info.plist
           self._appId = Bundle.main.infoDictionary?["AppsOnAirAPIKey"] as? String ?? ""
           if self._appId.isEmpty {
               #if DEBUG
               // In debug mode or during development, the developer will get a crash if the AppId is not set up in the Info.plist file.
               Logger.throwError(message: errorMessage)
               exit(-1)
               #else
               Logger.throwError(message: errorMessage)
               self._appId = "" // Clear the appId in release mode
               #endif
           }
       }
   
    /// helps to check internet connectivity
    @objc public func isConnectedNetwork()-> Bool{
        return (isNetworkConnected ?? false)
    }
    
    /// helps to listen internet connectivity state
    func networkStatusDidChange(status: Bool) {
        if(isNetworkConnected != status){
            networkStatusChangeHandler?(status)
            isNetworkConnected = status
        }
    }
    /// Method to set the network status change handler
    @objc public func networkStatusListenerHandler(_ handler: @escaping NetworkStatusChangeHandler) {
        networkStatusChangeHandler = handler
    }
}
