import NIOSSL
public import _DNSConnectionPool

/// Configuration for the DNS client
@available(swiftDNS 1.0, *)
public struct DNSClientConfiguration: Sendable {
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
