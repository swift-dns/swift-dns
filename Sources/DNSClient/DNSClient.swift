public import DNSModels
import Synchronization
import _DNSConnectionPool

package import struct Logging.Logger
package import protocol NIOCore.EventLoopGroup

#if ServiceLifecycleSupport
public import ServiceLifecycle
#endif

/// FIXME: The module and the type are both named `DNSClient`.
public actor DNSClient {
    typealias Pool = ConnectionPool<
        DNSConnection,
        DNSConnection.ID,
        ConnectionIDGenerator,
        ConnectionRequest<DNSConnection>,
        ConnectionRequest.ID,
        /// DNS uses negotiation mechanisms through EDNS for keeping connections alive.
        NoOpKeepAliveBehavior<DNSConnection>,
        DNSClientMetrics,
        ContinuousClock
    >

    public var serverAddress: DNSServerAddress
    public let configuration: DNSClientConfiguration
    let connectionPool: Pool
    let eventLoopGroup: any EventLoopGroup
    let logger: Logger
    let isRunning: Atomic<Bool>

    package init(
        serverAddress: DNSServerAddress,
        configuration: DNSClientConfiguration = .init(),
        eventLoopGroup: any EventLoopGroup,
        logger: Logger = .noopLogger
    ) throws {
        let connectionFactory = try ConnectionFactory(
            configuration: configuration.connectionConfiguration,
            serverAddress: serverAddress
        )
        self.serverAddress = serverAddress
        self.configuration = configuration
        self.connectionPool = .init(
            configuration: configuration.connectionPool,
            idGenerator: ConnectionIDGenerator(),
            requestType: ConnectionRequest<DNSConnection>.self,
            keepAliveBehavior: NoOpKeepAliveBehavior(connectionType: DNSConnection.self),
            observabilityDelegate: DNSClientMetrics(logger: logger),
            clock: .continuous
        ) { (connectionID, pool) in
            var logger = logger
            logger[metadataKey: "dns_connection_id"] = "\(connectionID)"

            let connection = try await connectionFactory.makeConnection(
                address: serverAddress,
                connectionID: connectionID,
                eventLoop: eventLoopGroup.any(),
                logger: logger
            )

            return ConnectionAndMetadata(connection: connection, maximalStreamsOnConnection: 1)
        }
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
        self.isRunning = Atomic(false)
    }

    /// Run DNSClient connection pool
    public func run() async {
        let (_, old) = self.isRunning.compareExchange(
            expected: false,
            desired: true,
            ordering: .relaxed
        )
        precondition(!old, "DNSClient.run() should just be called once!")
        #if ServiceLifecycleSupport
        await cancelWhenGracefulShutdown {
            await self.connectionPool.run()
        }
        #else
        await self.connectionPool.run()
        #endif
    }

    /// Get connection from connection pool and run operation using connection
    ///
    /// - Parameters:
    ///   - isolation: Actor isolation
    ///   - operation: Closure handling DNS connection
    /// - Returns: Value returned by closure
    public func withConnection<Value>(
        isolation: isolated (any Actor)? = #isolation,
        operation: (DNSConnection) async throws -> sending Value
    ) async throws -> Value {
        let connection = try await self.leaseConnection()

        defer { self.connectionPool.releaseConnection(connection) }

        return try await operation(connection)
    }

    func leaseConnection() async throws -> DNSConnection {
        if !self.isRunning.load(ordering: .relaxed) {
            self.logger.warning(
                "Trying to lease connection from `DNSClient`, but `DNSClient.run()` hasn't been called yet."
            )
        }
        return try await self.connectionPool.leaseConnection()
    }

    public func query(
        message factory: MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions = []
    ) async throws -> Message {
        var factory = factory
        factory.apply(options: options)
        return try await self.withConnection { conn in
            try await conn.send(message: factory.message)
        }
    }
}

#if ServiceLifecycleSupport
@available(swiftDNS 1.0, *)
extension DNSClient: Service {}
#endif  // ServiceLifecycle

extension DNSClient {
    @usableFromInline
    func querySpecialized<RDataType: RDataConvertible>(
        message factory: MessageFactory<RDataType>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<RDataType> {
        try SpecializedMessage(
            message: await query(message: factory, options: options)
        )
    }

    /// FIXME: A lot of these aren't even queryable in practice. Clean those up.

    @inlinable
    public func queryA(
        message factory: MessageFactory<A>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<A> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryAAAA(
        message factory: MessageFactory<AAAA>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<AAAA> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryCAA(
        message factory: MessageFactory<CAA>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CAA> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryCDS(
        message factory: MessageFactory<CDS>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CDS> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryCDNSKEY(
        message factory: MessageFactory<CDNSKEY>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CDNSKEY> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryCERT(
        message factory: MessageFactory<CERT>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CERT> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryCNAME(
        message factory: MessageFactory<CNAME>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CNAME> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryCSYNC(
        message factory: MessageFactory<CSYNC>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<CSYNC> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryDNSKEY(
        message factory: MessageFactory<DNSKEY>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<DNSKEY> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryDS(
        message factory: MessageFactory<DS>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<DS> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryHINFO(
        message factory: MessageFactory<HINFO>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<HINFO> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryHTTPS(
        message factory: MessageFactory<HTTPS>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<HTTPS> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryKEY(
        message factory: MessageFactory<KEY>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<KEY> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryMX(
        message factory: MessageFactory<MX>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<MX> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryNAPTR(
        message factory: MessageFactory<NAPTR>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NAPTR> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryNS(
        message factory: MessageFactory<NS>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NS> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryNSEC(
        message factory: MessageFactory<NSEC>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NSEC> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryNSEC3(
        message factory: MessageFactory<NSEC3>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NSEC3> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryNSEC3PARAM(
        message factory: MessageFactory<NSEC3PARAM>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NSEC3PARAM> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryNULL(
        message factory: MessageFactory<NULL>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<NULL> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryOPENPGPKEY(
        message factory: MessageFactory<OPENPGPKEY>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<OPENPGPKEY> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryOPT(
        message factory: MessageFactory<OPT>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<OPT> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryPTR(
        message factory: MessageFactory<PTR>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<PTR> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryRRSIG(
        message factory: MessageFactory<RRSIG>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<RRSIG> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func querySIG(
        message factory: MessageFactory<SIG>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SIG> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func querySOA(
        message factory: MessageFactory<SOA>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SOA> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func querySRV(
        message factory: MessageFactory<SRV>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SRV> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func querySSHFP(
        message factory: MessageFactory<SSHFP>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SSHFP> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func querySVCB(
        message factory: MessageFactory<SVCB>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<SVCB> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryTLSA(
        message factory: MessageFactory<TLSA>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<TLSA> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryTSIG(
        message factory: MessageFactory<TSIG>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<TSIG> {
        try await self.querySpecialized(message: factory, options: options)
    }

    @inlinable
    public func queryTXT(
        message factory: MessageFactory<TXT>,
        options: DNSRequestOptions = .init()
    ) async throws -> SpecializedMessage<TXT> {
        try await self.querySpecialized(message: factory, options: options)
    }
}
