import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var isCellular: Bool = false

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.teroro.networkmonitor")

    private init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = (path.status == .satisfied)
                self.isCellular = path.isExpensive || path.usesInterfaceType(.cellular)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
