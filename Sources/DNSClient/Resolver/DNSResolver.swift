#if ServiceLifecycleSupport
public import ServiceLifecycle
#endif

@available(swiftDNSApplePlatforms 13, *)
public actor DNSResolver {
    public let client: DNSClient

    public init(client: DNSClient) {
        self.client = client
    }

    @inlinable
    public func run() async throws {
        try await self.client.run()
    }
}

#if ServiceLifecycleSupport
@available(swiftDNSApplePlatforms 13, *)
extension DNSResolver: Service {}
#endif
