import _DNSConnectionPool

@available(swiftDNSApplePlatforms 13, *)
public struct DNSConnectionPoolConfiguration: Sendable {
    /// The minimum number of connections to preserve in the pool.
    ///
    /// If the pool is mostly idle and the remote servers closes idle connections, the
    /// `ConnectionPool` will initiate new outbound connections proactively to avoid the number
    /// of available connections dropping below this number.
    public var minimumConnectionCount: Int

    /// Between the `minimumConnectionCount` and `maximumConnectionSoftLimit` the connection pool
    /// creates _preserved_ connections. Preserved connections are closed if
    /// they have been idle for ``idleTimeout``.
    public var maximumConnectionSoftLimit: Int

    /// The maximum number of connections for this pool, that can exist at any point in time.
    /// The pool can create _overflow_ connections, if all connections are leased, and the
    /// `maximumConnectionHardLimit` > `maximumConnectionSoftLimit `.
    /// Overflow connections are closed immediately as soon as they become idle.
    public var maximumConnectionHardLimit: Int

    /// The time that a _preserved_ idle connection stays in the pool before it is closed.
    public var idleTimeout: Duration

    /// Configuration options for a connection pool.
    /// - Parameters:
    ///   - minimumConnectionCount: The minimum number of connections to preserve in the pool.
    ///     If the pool is mostly idle and the remote servers closes idle connections, the
    ///     `ConnectionPool` will initiate new outbound connections proactively to avoid the number
    ///     of available connections dropping below this number.
    ///   - maximumConnectionSoftLimit: Between the `minimumConnectionCount` and
    ///     `maximumConnectionSoftLimit` the connection pool creates _preserved_ connections.
    ///     Preserved connections are closed if they have been idle for ``idleTimeout``.
    ///   - maximumConnectionHardLimit: The maximum number of connections for this pool, that can
    ///     exist at any point in time. The pool can create _overflow_ connections, if all connections
    ///     are leased, and the `maximumConnectionHardLimit` > `maximumConnectionSoftLimit `.
    ///     Overflow connections are closed immediately as soon as they become idle.
    ///   - idleTimeout: The time that a _preserved_ idle connection stays in the pool before it is closed.
    public init(
        minimumConnectionCount: Int = 4,
        maximumConnectionSoftLimit: Int = 32,
        maximumConnectionHardLimit: Int = 64,
        idleTimeout: Duration = .seconds(30)
    ) {
        self.minimumConnectionCount = minimumConnectionCount
        self.maximumConnectionSoftLimit = maximumConnectionSoftLimit
        self.maximumConnectionHardLimit = maximumConnectionHardLimit
        self.idleTimeout = idleTimeout
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension DNSConnectionPoolConfiguration {
    func toConnectionPoolConfig() -> _DNSConnectionPool.ConnectionPoolConfiguration {
        var config = _DNSConnectionPool.ConnectionPoolConfiguration()
        config.minimumConnectionCount = self.minimumConnectionCount
        config.maximumConnectionSoftLimit = self.maximumConnectionSoftLimit
        config.maximumConnectionHardLimit = self.maximumConnectionHardLimit
        config.idleTimeout = self.idleTimeout
        return config
    }
}
