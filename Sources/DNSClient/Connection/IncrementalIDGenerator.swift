import Synchronization
import _DNSConnectionPool

/// Connection id generator for DNS connection pool
@available(swiftDNSApplePlatforms 26, *)
package final class IncrementalIDGenerator: ConnectionIDGeneratorProtocol {
    private let atomic: Atomic<Int>

    init() {
        self.atomic = .init(0)
    }

    package func next() -> Int {
        self.atomic.wrappingAdd(1, ordering: .relaxed).oldValue
    }
}
