public import DNSModels

#if ServiceLifecycleSupport
public import ServiceLifecycle
#endif

/// FIXME: The module and the type are both named `DNSClient`.
@available(swiftDNSApplePlatforms 26, *)
public struct DNSClient {
    @usableFromInline
    enum Transport: Sendable {
        case preferUDPOrUseTCP(PreferUDPOrUseTCPDNSClientTransport)
        case tcp(TCPDNSClientTransport)
    }

    @usableFromInline
    let transport: Transport

    /// Public initializers are declared as static functions in the `DNSClient+Transports.swift` files.

    init(transport: consuming Transport) throws {
        self.transport = transport
    }

    /// Run DNSClient connection pool
    public func run() async {
        switch self.transport {
        case .preferUDPOrUseTCP(let transport):
            await transport.run()
        case .tcp(let transport):
            await transport.run()
        }
    }

    /// Send a query to the DNS server.
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
        options: DNSRequestOptions = [],
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> Message {
        switch self.transport {
        case .preferUDPOrUseTCP(let transport):
            try await transport.query(message: factory, options: options, isolation: isolation)
        case .tcp(let transport):
            try await transport.query(message: factory, options: options, isolation: isolation)
        }
    }
}

#if ServiceLifecycleSupport
@available(swiftDNSApplePlatforms 26, *)
extension DNSClient: Service {}
#endif  // ServiceLifecycle
