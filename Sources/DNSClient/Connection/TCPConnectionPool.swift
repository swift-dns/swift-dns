public import _DNSConnectionPool

@available(SwiftStdlib 5.7, *)
@usableFromInline
typealias TCPConnectionPool = ConnectionPool<
    DNSConnection,
    DNSConnection.ID,
    IncrementalIDGenerator,
    ConnectionRequest<DNSConnection>,
    ConnectionRequest.ID,
    /// DNS uses negotiation mechanisms through EDNS for keeping connections alive.
    NoOpKeepAliveBehavior<DNSConnection>,
    DNSClientMetrics,
    ContinuousClock
>
