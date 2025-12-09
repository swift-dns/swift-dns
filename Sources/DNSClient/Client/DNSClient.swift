public import DNSModels

#if ServiceLifecycleSupport
public import ServiceLifecycle
#endif

/// FIXME: The module and the type are both named `DNSClient`.
@available(swiftDNSApplePlatforms 13, *)
public struct DNSClient: Sendable {
    @usableFromInline
    enum Transport: Sendable {
        case preferUDPOrUseTCP(PreferUDPOrUseTCPDNSClientTransport)
        case tcp(TCPDNSClientTransport)
    }

    @usableFromInline
    let transport: Transport

    public init(transport transportFactory: DNSClientTransportFactory) {
        self.transport = transportFactory.transport
    }

    /// Run DNSClient connection pool
    /// This is intentionally marked as throws so it can fail in the future if it needs to.
    @inlinable
    public func run() async throws {
        switch self.transport {
        case .preferUDPOrUseTCP(let transport):
            await transport.run()
        case .tcp(let transport):
            await transport.run()
        }
    }

    /// Send a query to the DNS server.
    ///
    /// The convenience query functions are in `DNSClient+Transports.swift`.
    /// Use `queryA`, `queryAAAA`, `queryCNAME` etc... if you want those convenience functions.
    ///
    /// - Parameters:
    ///   - factory: The factory to produce a query message with.
    ///   - options: The options for producing the query message.
    ///   - channel: The channel type to send the query on.
    ///   - isolation: The isolation on which the query will be sent.
    ///
    /// - Returns: The query response.
    @inlinable
    public func query(
        message factory: consuming MessageFactory<some RDataConvertible>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> Message {
        try await self._query(
            message: factory,
            isolation: isolation
        ).response
    }

    @inlinable
    package func _query(
        message factory: consuming MessageFactory<some RDataConvertible>,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> (query: Message, response: Message) {
        switch self.transport {
        case .preferUDPOrUseTCP(let transport):
            try await transport.query(message: factory, isolation: isolation)
        case .tcp(let transport):
            try await transport.query(message: factory, isolation: isolation)
        }
    }
}

#if ServiceLifecycleSupport
@available(swiftDNSApplePlatforms 13, *)
extension DNSClient: Service {}
#endif  // ServiceLifecycle
