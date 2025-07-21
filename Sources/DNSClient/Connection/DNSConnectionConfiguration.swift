public import class NIOSSL.NIOSSLContext

/// A configuration object that defines how to connect to a DNS server.
///
/// `DNSConnectionConfiguration` allows you to customize various aspects of the connection,
/// including timeouts, and TLS security settings.
///
/// Example usage:
/// ```swift
/// // Basic configuration
/// let config = DNSConnectionConfiguration()
///
/// // Configuration with TLS
/// let sslContext = try NIOSSLContext(configuration: .makeClientConfiguration())
/// let secureConfig = DNSConnectionConfiguration(
///     queryTimeout: .seconds(10),
///     tls: .enable(sslContext, tlsServerName: "your-dns-server.com")
/// )
/// ```
public struct DNSConnectionConfiguration: Sendable {
    /// Configuration for TLS (Transport Layer Security) encryption.
    ///
    /// This structure allows you to enable or disable encrypted connections to the DNS server.
    /// When enabled, it requires an `NIOSSLContext` and optionally a server name for SNI (Server Name Indication).
    public enum TLS: Sendable {
        case disable
        /// - Parameters:
        ///   - sslContext: The SSL context used to establish the secure connection
        ///   - tlsServerName: Optional server name for SNI (Server Name Indication)
        case enable(NIOSSLContext, String?)
    }

    /// The maximum time to wait for a response to a query before considering the connection dead.
    ///
    /// This timeout applies to all queries sent to the DNS server.
    /// Default value is 30 seconds.
    public var queryTimeout: Duration

    /// TLS configuration for the connection.
    /// Use `.disable` for unencrypted connections or `.enable(...)` for secure connections.
    public var tls: TLS

    /// Creates a new DNS connection configuration.
    ///
    /// Use this initializer to create a configuration object that can be used to establish
    /// a connection to a DNS server with the specified parameters.
    ///
    /// - Parameters:
    ///   - queryTimeout: Maximum time to wait for a response to a query. Defaults to 10 seconds.
    ///   - tls: TLS configuration for secure connections. Defaults to `.disable` for unencrypted connections.
    public init(
        queryTimeout: Duration = .seconds(10),
        tls: TLS = .disable
    ) {
        self.queryTimeout = queryTimeout
        self.tls = tls
    }
}
