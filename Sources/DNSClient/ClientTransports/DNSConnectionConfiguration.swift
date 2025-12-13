/// A configuration object that defines how to connect to a DNS server.
///
/// `DNSConnectionConfiguration` allows you to customize various aspects of the connection,
/// including timeouts.
///
/// Example usage:
/// ```swift
/// // Basic configuration
/// let config = DNSConnectionConfiguration()
/// ```
@available(swiftDNSApplePlatforms 13, *)
public struct DNSConnectionConfiguration: Sendable {
    /// The maximum time to wait for a response to a query before considering the connection dead.
    ///
    /// This timeout applies to all queries sent to the DNS server.
    /// Default value is 1 second.
    public var queryTimeout: Duration

    /// Creates a new DNS connection configuration.
    ///
    /// Use this initializer to create a configuration object that can be used to establish
    /// a connection to a DNS server with the specified parameters.
    ///
    /// - Parameters:
    ///   - queryTimeout: Maximum time to wait for a response to a query. Defaults to 1 second.
    public init(queryTimeout: Duration = .seconds(1)) {
        self.queryTimeout = queryTimeout
    }
}
