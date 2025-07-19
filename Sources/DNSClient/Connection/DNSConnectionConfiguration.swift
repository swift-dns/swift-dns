public import class NIOSSL.NIOSSLContext

/// A configuration object that defines how to connect to a DNS server.
///
/// `DNSConnectionConfiguration` allows you to customize various aspects of the connection,
/// including authentication credentials, timeouts, and TLS security settings.
///
/// Example usage:
/// ```swift
/// // Basic configuration
/// let config = DNSConnectionConfiguration()
///
/// // Configuration with authentication
/// let authConfig = DNSConnectionConfiguration(
///     authentication: .init(username: "user", password: "pass"),
///     commandTimeout: .seconds(60)
/// )
///
/// // Configuration with TLS
/// let sslContext = try NIOSSLContext(configuration: .makeClientConfiguration())
/// let secureConfig = DNSConnectionConfiguration(
///     authentication: .init(username: "user", password: "pass"),
///     tls: .enable(sslContext, tlsServerName: "your-dns-server.com")
/// )
/// ```
public struct DNSConnectionConfiguration: Sendable {
    /// Configuration for TLS (Transport Layer Security) encryption.
    ///
    /// This structure allows you to enable or disable encrypted connections to the DNS server.
    /// When enabled, it requires an `NIOSSLContext` and optionally a server name for SNI (Server Name Indication).
    public struct TLS: Sendable {
        enum Base {
            case disable
            case enable(NIOSSLContext, String?)
        }
        let base: Base

        /// Disables TLS for the connection.
        ///
        /// Use this option when connecting to a DNS server that doesn't require encryption.
        public static var disable: Self { .init(base: .disable) }

        /// Enables TLS for the connection.
        ///
        /// - Parameters:
        ///   - sslContext: The SSL context used to establish the secure connection
        ///   - tlsServerName: Optional server name for SNI (Server Name Indication)
        /// - Returns: A configured TLS instance
        public static func enable(
            _ sslContext: NIOSSLContext,
            tlsServerName: String?
        ) throws -> Self {
            .init(base: .enable(sslContext, tlsServerName))
        }
    }

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

    /// TLS configuration for the connection.
    /// Use `.disable` for unencrypted connections or `.enable(...)` for secure connections.
    public var tls: TLS

    /// The maximum time to wait for a response to a query before considering the connection dead.
    ///
    /// This timeout applies to all queries sent to the DNS server.
    /// Default value is 30 seconds.
    public var queryTimeout: Duration

    /// Creates a new DNS connection configuration.
    ///
    /// Use this initializer to create a configuration object that can be used to establish
    /// a connection to a DNS server with the specified parameters.
    ///
    /// - Parameters:
    ///   - authentication: Optional credentials for accessing the DNS server. Set to `nil` for unauthenticated access.
    ///   - commandTimeout: Maximum time to wait for a response to standard commands. Defaults to 30 seconds.
    ///   - blockingCommandTimeout: Maximum time to wait for a response to blocking commands. Defaults to 120 seconds.
    ///   - tls: TLS configuration for secure connections. Defaults to `.disable` for unencrypted connections.
    ///   - clientName: Optional name to identify this client connection on the server. Defaults to `nil`.
    public init(
        queryTimeout: Duration = .seconds(30),
        tls: TLS = .disable
    ) {
        self.queryTimeout = queryTimeout
        self.tls = tls
    }
}
