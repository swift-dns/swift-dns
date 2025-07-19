import NIOSSL
public import _DNSConnectionPool

/// Configuration for the DNS client
@available(swiftDNS 1.0, *)
public struct DNSClientConfiguration: Sendable {
    /// A keep-alive behavior for DNS connections. The ``frequency`` defines after which time an idle
    /// connection shall run a keep-alive ``DNSConnectionProtocol/ping(message:)``.
    public struct KeepAliveBehavior: Sendable {
        /// The amount of time that shall pass before an idle connection runs a keep-alive query.
        public var frequency: Duration

        /// Create a new `KeepAliveBehavior`.
        /// - Parameters:
        ///   - frequency: The amount of time that shall pass before an idle connection runs a keep-alive.
        ///                Defaults to `30` seconds.
        public init(frequency: Duration = .seconds(30)) {
            self.frequency = frequency
        }
    }

    /// Connection configuration
    public var connectionConfiguration: DNSConnectionConfiguration
    /// Connection pool configuration
    public var connectionPool: ConnectionPoolConfiguration
    /// Keep-alive behavior
    public var keepAliveBehavior: KeepAliveBehavior

    ///  Initialize DNSClientConfiguration
    /// - Parameters
    ///   - connectionConfiguration: Connection configuration
    ///   - connectionPool: Connection pool configuration
    ///   - keepAliveBehavior: Connection keep alive behavior
    public init(
        connectionConfiguration: DNSConnectionConfiguration = .init(),
        connectionPool: ConnectionPoolConfiguration = .init(),
        keepAliveBehavior: KeepAliveBehavior = .init(),
        queryTimeout: Duration = .seconds(30)
    ) {
        self.connectionConfiguration = connectionConfiguration
        self.connectionPool = connectionPool
        self.keepAliveBehavior = keepAliveBehavior
    }
}
