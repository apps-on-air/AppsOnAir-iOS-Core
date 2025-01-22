import Foundation
import Reachability

/// Protocol to notify listeners about network state changes
protocol NetworkServiceDelegate: AnyObject {
    func networkStatusDidChange(status: Bool)
}

/// Protocol to define network service functionality
protocol NetworkService {
    var delegate: NetworkServiceDelegate? { get set }
    func startMonitoring()
    func stopMonitoring()
}

///get current network status
var currentNetworkState: String = "Unknown"

/// Implementation of network service using Reachability
class ReachabilityNetworkService: NetworkService {
    private let reachability = try! Reachability()
    weak var delegate: NetworkServiceDelegate?

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(networkChanged(_:)), name: .reachabilityChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: nil)
    }
    
    /// start network connectivity listener
    func startMonitoring() {
        do {
            try reachability.startNotifier()
        } catch {
            Logger.throwError(message: "startMonitoring startMonitoring: \(error)")
        }
    }
    
    /// stop network connectivity listener
    func stopMonitoring() {
        reachability.stopNotifier()
    }
    
    /// call when network state changed
    @objc private func networkChanged(_ notification: Notification) {
        guard let reachability = notification.object as? Reachability else { return }

        let isConnected = reachability.connection != .unavailable
        
        switch reachability.connection {
           case .wifi:
            currentNetworkState = "Wi-Fi"
           case .cellular:
            currentNetworkState = "Mobile Data"
           case .unavailable:
            currentNetworkState = "Not Connected"
        }
        
        delegate?.networkStatusDidChange(status: isConnected)
        Logger.logInternal("Network State: \(isConnected)")
    }
}
