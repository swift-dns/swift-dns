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
    typealias TCPConnectionPool = ConnectionPool<
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
    /// FIXME: using DNSConnection for now to have something sendable.
    @usableFromInline
    var _udpConnection: DNSConnection?
    @usableFromInline
    var udpConnection: DNSConnection {
        get async throws {
            if let connection = self._udpConnection {
                return connection
            } else {
                self._udpConnection = try await self.makeUDPConnection()
                return self._udpConnection!
            }
        }
    }
    let tcpConnectionPool: TCPConnectionPool
    let eventLoopGroup: any EventLoopGroup
    let logger: Logger
    let isRunning: Atomic<Bool>

    package init(
        serverAddress: DNSServerAddress,
        configuration: DNSClientConfiguration = .init(),
        eventLoopGroup: any EventLoopGroup,
        logger: Logger = .noopLogger
    ) throws {
        let tcpConnectionFactory = try ConnectionFactory(
            configuration: configuration.tcpConnectionConfiguration,
            serverAddress: serverAddress
        )
        self.serverAddress = serverAddress
        self.configuration = configuration
        self.tcpConnectionPool = .init(
            configuration: configuration.tcpConnectionPoolConfiguration,
            idGenerator: IDGenerator(),
            requestType: ConnectionRequest<DNSConnection>.self,
            keepAliveBehavior: NoOpKeepAliveBehavior(connectionType: DNSConnection.self),
            observabilityDelegate: DNSClientMetrics(logger: logger),
            clock: .continuous
        ) { (connectionID, pool) in
            var logger = logger
            logger[metadataKey: "dns_tcp_conn_id"] = "\(connectionID)"

            let connection = try await tcpConnectionFactory.makeTCPConnection(
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
            await self.tcpConnectionPool.run()
        }
        #else
        await self.tcpConnectionPool.run()
        #endif
    }

    @inlinable
    public func query(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions = []
    ) async throws -> Message {
        try await self.udpConnection.send(
            message: factory,
            options: options
        )
    }

    @inlinable
    public func tcpQuery(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions = [],
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> Message {
        try await self.withTCPConnection(
            message: factory,
            options: options
        ) { factory, options, conn in
            try await conn.send(
                message: factory,
                options: options
            )
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
    func withTCPConnection<RData: RDataConvertible>(
        message factory: consuming MessageFactory<RData>,
        options: DNSRequestOptions,
        isolation: isolated (any Actor)? = #isolation,
        operation: (
            consuming MessageFactory<RData>,
            DNSRequestOptions,
            DNSConnection
        ) async throws -> Message
    ) async throws -> Message {
        let connection = try await self.leaseConnection()

        defer { self.tcpConnectionPool.releaseConnection(connection) }

        return try await operation(factory, options, connection)
    }

    func leaseConnection() async throws -> DNSConnection {
        if !self.isRunning.load(ordering: .relaxed) {
            self.logger.warning(
                "Trying to lease connection from `DNSClient`, but `DNSClient.run()` hasn't been called yet."
            )
        }
        return try await self.tcpConnectionPool.leaseConnection()
    }

    func makeUDPConnection() async throws -> DNSConnection {
        let udpConnectionFactory = try ConnectionFactory(
            configuration: configuration.connectionConfiguration,
            serverAddress: serverAddress
        )
        let udpConnection = try await udpConnectionFactory.makeUDPConnection(
            address: serverAddress,
            connectionID: 0,
            eventLoop: eventLoopGroup.any(),
            logger: logger
        )
        return udpConnection
    }

}

#if ServiceLifecycleSupport
@available(swiftDNS 1.0, *)
extension DNSClient: Service {}
#endif  // ServiceLifecycle
