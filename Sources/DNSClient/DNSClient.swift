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
        IDGenerator,
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
            idGenerator: IDGenerator(),
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
                eventLoop: eventLoopGroup.next(),
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

    @inlinable
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

extension DNSClient {
    /// Get connection from connection pool and run operation using connection
    ///
    /// - Parameters:
    ///   - isolation: Actor isolation
    ///   - operation: Closure handling DNS connection
    /// - Returns: Value returned by closure
    @usableFromInline
    func withConnection(
        isolation: isolated (any Actor)? = #isolation,
        operation: (DNSConnection) async throws -> Message
    ) async throws -> Message {
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
}

#if ServiceLifecycleSupport
@available(swiftDNS 1.0, *)
extension DNSClient: Service {}
#endif  // ServiceLifecycle
