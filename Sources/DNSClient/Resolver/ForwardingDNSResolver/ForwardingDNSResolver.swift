#if ServiceLifecycleSupport
public import ServiceLifecycle
#endif

/// The simplest form of a DNS resolver.
/// This resolver simply asks another server for the answer, through the `DNSClient`.
/// Performs caching of response when possible.
@available(swiftDNSApplePlatforms 13, *)
public struct ForwardingDNSResolver<ClockType: Clock>:
    Sendable
where ClockType.Duration == Duration {
    @usableFromInline
    let client: DNSClient
    @usableFromInline
    let cache: DNSCache<ClockType>

    /// A description
    /// - Parameters:
    ///   - client: The client to forward queries to.
    ///   - cache: The cache to use for caching responses.
    public init(
        client: DNSClient,
        cache: DNSCache<ClockType> = DNSCache<ContinuousClock>()
    ) {
        self.client = client
        self.cache = cache
    }

    /// A description
    /// - Parameters:
    ///   - client: The client to forward queries to.
    ///   - cache: The cache to use for caching responses.
    public init(
        transport transportFactory: DNSClientTransportFactory,
        cache: DNSCache<ClockType> = DNSCache<ContinuousClock>()
    ) {
        self.client = DNSClient(transport: transportFactory)
        self.cache = cache
    }

    @inlinable
    public func run() async throws {
        try await self.client.run()
    }
}

#if ServiceLifecycleSupport
@available(swiftDNSApplePlatforms 13, *)
extension ForwardingDNSResolver: Service {}
#endif
