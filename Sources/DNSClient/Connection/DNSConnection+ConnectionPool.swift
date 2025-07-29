import DNSModels
import Logging
import NIOCore
public import _DNSConnectionPool

/// Extend DNSConnection so we can use it with the connection pool
@available(swiftDNSApplePlatforms 26.0, *)
extension DNSConnection: PooledConnection {
    // connection id
    public typealias ID = Int
    // on close
    public nonisolated func onClose(_ closure: @escaping @Sendable ((any Error)?) -> Void) {
        self.channel.closeFuture.whenComplete { _ in closure(nil) }
    }
}
