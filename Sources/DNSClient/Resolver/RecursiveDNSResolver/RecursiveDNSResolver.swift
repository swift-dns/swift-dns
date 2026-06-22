#if ServiceLifecycleSupport
public import ServiceLifecycle
#endif

@available(SwiftStdlib 5.7, *)
public struct _RecursiveDNSResolver {
    public let client: DNSClient

    public init(client: DNSClient) {
        self.client = client
    }

    public init(transport transportFactory: DNSClientTransportFactory) {
        self.client = DNSClient(transport: transportFactory)
    }

    @inlinable
    public func run() async throws {
        try await self.client.run()
    }
}

#if ServiceLifecycleSupport
@available(SwiftStdlib 5.7, *)
extension _RecursiveDNSResolver: Service {}
#endif
