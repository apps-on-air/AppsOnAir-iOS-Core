import Foundation
import Network

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

/// Implementation of network service using Apple's `NWPathMonitor` (Network framework).
///
/// Replaces the former ReachabilitySwift-based watcher and keeps its behaviour:
/// - the current status is reported once right after `startMonitoring()`, then on every change;
/// - `currentNetworkState` and the delegate are updated on the main queue;
/// - any satisfied non-cellular path (Wi-Fi, wired, simulator) is reported as "Wi-Fi".
internal class PathMonitorNetworkService: NetworkService {
    weak var delegate: NetworkServiceDelegate?

    /// An `NWPathMonitor` can't be restarted once cancelled, so a fresh one is created per start.
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "com.appsonair.core.network-monitor")

    deinit {
        monitor?.cancel()
    }

    /// start network connectivity listener
    internal func startMonitoring() {
        guard monitor == nil else { return }
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            self?.networkChanged(path)
        }
        self.monitor = monitor
        monitor.start(queue: queue)
    }

    /// stop network connectivity listener
    internal func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
    }

    /// call when network state changed
    private func networkChanged(_ path: NWPath) {
        let isConnected = path.status == .satisfied
        let state: String
        if !isConnected {
            state = "Not Connected"
        } else if path.usesInterfaceType(.cellular) {
            state = "Mobile Data"
        } else {
            state = "Wi-Fi"
        }

        //Improvements for React Native platform.
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.001,
            execute: {
                currentNetworkState = state
                self.delegate?.networkStatusDidChange(status: isConnected)
            })

        Logger.logInternal("Network State: \(isConnected)")
    }
}
