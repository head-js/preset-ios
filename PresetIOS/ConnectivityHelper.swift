import Foundation
import Network

enum ConnectivityType {
    case wifi, cellular, ethernet, bluetooth, vpn, none

    var label: String {
        switch self {
        case .wifi: return "WIFI"
        case .cellular: return "CELLULAR"
        case .ethernet: return "ETHERNET"
        case .bluetooth: return "BLUETOOTH"
        case .vpn: return "VPN"
        case .none: return "NONE"
        }
    }
}

class ConnectivityHelper {

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.lisitede.preset.connectivity")

    private var onChanged: ((ConnectivityType) -> Void)?
    private var lastType: ConnectivityType = .none

    private(set) var currentConnectivity: ConnectivityType = .none

    func getCurrentConnectivity() -> ConnectivityType {
        return currentConnectivity
    }

    func registerCallback(onChanged: @escaping (ConnectivityType) -> Void) {
        self.onChanged = onChanged
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let type: ConnectivityType
            if path.status != .satisfied {
                type = .none
            } else {
                type = self.transportToType(path)
            }
            self.currentConnectivity = type
            DispatchQueue.main.async {
                onChanged(type)
            }
        }
        monitor.start(queue: queue)
    }

    func unregisterCallback() {
        monitor.cancel()
        onChanged = nil
    }

    private func transportToType(_ path: NWPath) -> ConnectivityType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.usesInterfaceType(.loopback) {
            return .none
        } else {
            return .none
        }
    }
}
