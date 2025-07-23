import NIOSSL
public import _DNSConnectionPool

/// Configuration for the DNS client
@available(swiftDNS 1.0, *)
public struct DNSClientConfiguration: Sendable {
    public struct ConnectionPoolConfiguration: Sendable {
        /// The minimum number of connections to preserve in the pool.
        ///
        /// If the pool is mostly idle and the remote servers closes
        /// idle connections,
        /// the `ConnectionPool` will initiate new outbound
        /// connections proactively to avoid the number of available
        /// connections dropping below this number.
        public var minimumConnectionCount: Int

        /// Between the `minimumConnectionCount` and
        /// `maximumConnectionSoftLimit` the connection pool creates
        /// _preserved_ connections. Preserved connections are closed
        /// if they have been idle for ``idleTimeout``.
        public var maximumConnectionSoftLimit: Int

        /// The maximum number of connections for this pool, that can
        /// exist at any point in time. The pool can create _overflow_
        /// connections, if all connections are leased, and the
        /// `maximumConnectionHardLimit` > `maximumConnectionSoftLimit `
        /// Overflow connections are closed immediately as soon as they
        /// become idle.
        public var maximumConnectionHardLimit: Int

        /// The time that a _preserved_ idle connection stays in the
        /// pool before it is closed.
        public var idleTimeout: Duration

        /// initializer
        public init(
            minimumConnectionCount: Int = 0,
            maximumConnectionSoftLimit: Int = 16,
            maximumConnectionHardLimit: Int = 16,
            idleTimeout: Duration = .seconds(60)
        ) {
            self.minimumConnectionCount = minimumConnectionCount
            self.maximumConnectionSoftLimit = maximumConnectionSoftLimit
            self.maximumConnectionHardLimit = maximumConnectionHardLimit
            self.idleTimeout = idleTimeout
        }
    }

    /// A keep-alive behavior for DNS connections.
    /// The ``frequency`` defines the keep-alive time amount that SwiftDNS will request from servers.
    /// DNS runs primarily on UDP, where sending keep-alives is not meaningful.
    /// This keep-alive behavior only applies to TCP connections.
    /// SwiftDNS will try to negotiate keeping connection alive through EDNS with the server with
    /// the behavior defined here, but servers are free to not respect SwiftDNS's request.
    /// For more information, see [RFC 7828, The edns-tcp-keepalive EDNS0 Option, April 2016](https://datatracker.ietf.org/doc/html/rfc7828#section-3.2).
    /// Currently unused. Keep-alive is to be implemented in the future.
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

    /// UDP connection configuration
    public var connectionConfiguration: DNSConnectionConfiguration
    /// TCP connection configuration
    public var tcpConnectionConfiguration: DNSConnectionConfiguration
    /// Connection pool configuration
    public var tcpConnectionPoolConfiguration: ConnectionPoolConfiguration
    /// Keep-alive behavior
    public var keepAliveBehavior: KeepAliveBehavior

    ///  Initialize DNSClientConfiguration
    /// - Parameters
    ///   - connectionConfiguration: Connection configuration
    ///   - connectionPool: Connection pool configuration
    ///   - keepAliveBehavior: Connection keep alive behavior
    public init(
        connectionConfiguration: DNSConnectionConfiguration = .init(),
        tcpConnectionConfiguration: DNSConnectionConfiguration = .init(),
        tcpConnectionPoolConfiguration: ConnectionPoolConfiguration = .init(),
        keepAliveBehavior: KeepAliveBehavior = .init()
    ) {
        self.connectionConfiguration = connectionConfiguration
        self.tcpConnectionConfiguration = tcpConnectionConfiguration
        self.tcpConnectionPoolConfiguration = tcpConnectionPoolConfiguration
        self.keepAliveBehavior = keepAliveBehavior
    }
}
