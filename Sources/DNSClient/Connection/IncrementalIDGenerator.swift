import Synchronization
public import _DNSConnectionPool

/// Connection id generator for DNS connection pool
@available(swiftDNSApplePlatforms 26, *)
@usableFromInline
package final class IncrementalIDGenerator: ConnectionIDGeneratorProtocol {
    private let atomic: Atomic<Int>

    init() {
        self.atomic = .init(0)
    }

    @usableFromInline
    package func next() -> Int {
        self.atomic.wrappingAdd(1, ordering: .relaxed).oldValue
    }
}
