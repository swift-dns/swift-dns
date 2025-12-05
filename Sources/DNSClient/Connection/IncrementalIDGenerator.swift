import Atomics
public import _DNSConnectionPool

/// Connection id generator for DNS connection pool
@available(swiftDNSApplePlatforms 10.15, *)
@usableFromInline
package final class IncrementalIDGenerator: ConnectionIDGeneratorProtocol {
    private let atomic: ManagedAtomic<Int>

    init() {
        self.atomic = ManagedAtomic(0)
    }

    @usableFromInline
    package func next() -> Int {
        self.atomic.loadThenWrappingIncrement(by: 1, ordering: .relaxed)
    }
}
