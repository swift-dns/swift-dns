public import DNSModels
import Synchronization
import _DNSConnectionPool

public import struct Logging.Logger
public import protocol NIOCore.EventLoopGroup

#if ServiceLifecycleSupport
public import ServiceLifecycle
#endif

/// Configuration for the DNS client
@available(swiftDNSApplePlatforms 26, *)
public actor PreferUDPOrUseTCPDNSClientTransport {
    public struct Configuration: Sendable {
        // FIXME: I don't think the channel handler state machine is ready to handle different
        // query timeouts for different channel kind (udp/tcp).
        // See the comments in the StateMachine file about query timeout assumptions that is made there.

        /// UDP connection configuration
        public var udpConnectionConfiguration: DNSConnectionConfiguration
        /// TCP connection configuration
        public var tcpConnectionConfiguration: DNSConnectionConfiguration
        /// Connection pool configuration
        public var tcpConnectionPoolConfiguration: DNSConnectionPoolConfiguration
        /// Keep-alive behavior
        public var tcpKeepAliveBehavior: KeepAliveBehavior

        ///  Initialize DNSClientConfiguration
        /// - Parameters
        ///   - connectionConfiguration: Connection configuration
        ///   - connectionPool: Connection pool configuration
        ///   - keepAliveBehavior: Connection keep alive behavior
        public init(
            udpConnectionConfiguration: DNSConnectionConfiguration = .init(),
            tcpConnectionConfiguration: DNSConnectionConfiguration = .init(),
            tcpConnectionPoolConfiguration: DNSConnectionPoolConfiguration = .init(),
            tcpKeepAliveBehavior: KeepAliveBehavior = .init()
        ) {
            self.udpConnectionConfiguration = udpConnectionConfiguration
            self.tcpConnectionConfiguration = tcpConnectionConfiguration
            self.tcpConnectionPoolConfiguration = tcpConnectionPoolConfiguration
            self.tcpKeepAliveBehavior = tcpKeepAliveBehavior
        }
    }

    public let serverAddress: DNSServerAddress
    public let configuration: Configuration
    /// FIXME: using DNSConnection for now to have something sendable.
    @usableFromInline
    var _udpConnection: DNSConnection?
    @usableFromInline
    var udpConnection: DNSConnection {
        get async throws {
            if let connection = self._udpConnection {
                return connection
            } else {
                let connection = try await self.makeUDPConnection()
                self._udpConnection = connection
                return connection
            }
        }
    }
    let tcpConnectionPool: TCPConnectionPool
    let udpEventLoopGroup: any EventLoopGroup
    let tcpEventLoopGroup: any EventLoopGroup
    let logger: Logger
    let isRunning: Atomic<Bool>

    public init(
        serverAddress: DNSServerAddress,
        configuration: Configuration = .init(),
        udpEventLoopGroup: any EventLoopGroup = DNSClient.defaultUDPEventLoopGroup,
        tcpEventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        logger: Logger = .noopLogger
    ) throws {
        let tcpConnectionFactory = try ConnectionFactory(
            configuration: configuration.tcpConnectionConfiguration,
            serverAddress: serverAddress
        )
        self.serverAddress = serverAddress
        self.configuration = configuration
        self.tcpConnectionPool = TCPConnectionPool(
            configuration: configuration.tcpConnectionPoolConfiguration.toConnectionPoolConfig(),
            idGenerator: IncrementalIDGenerator(),
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
                eventLoop: tcpEventLoopGroup.next(),
                logger: logger
            )

            return ConnectionAndMetadata(connection: connection, maximalStreamsOnConnection: 1)
        }
        self.udpEventLoopGroup = udpEventLoopGroup
        self.tcpEventLoopGroup = tcpEventLoopGroup
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

    /// Send a query to the DNS server.
    /// - Parameters:
    ///   - factory: The factory to produce a query message with.
    ///   - options: The options for producing the query message.
    ///   - channel: The channel type to send the query on.
    ///   - isolation: The isolation on which the query will be sent.
    ///
    /// - Returns: The query response.
    @usableFromInline
    package func query(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions = [],
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> Message {
        try await self.withConnection(
            message: factory,
            options: options,
            isolation: isolation
        ) { factory, options, conn in
            try await self.query(
                message: factory,
                options: options,
                connection: conn,
                isolation: isolation
            )
        }
    }
}

@available(swiftDNSApplePlatforms 26, *)
extension PreferUDPOrUseTCPDNSClientTransport {
    @usableFromInline
    func query(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions = [],
        connection: DNSConnection,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> Message {
        try await connection.send(
            message: factory,
            options: options
        )
    }

    @usableFromInline
    func withConnection<RData: RDataConvertible>(
        message factory: consuming MessageFactory<RData>,
        options: DNSRequestOptions,
        isolation: isolated (any Actor)? = #isolation,
        operation: (
            consuming MessageFactory<RData>,
            DNSRequestOptions,
            DNSConnection
        ) async throws -> Message
    ) async throws -> Message {
        switch true {
        case true:
            try await operation(
                factory,
                options,
                self.udpConnection
            )
        case false:
            try await self.withTCPConnection(
                message: factory,
                options: options,
                isolation: isolation,
                operation: operation
            )
        }
    }

    /// Get connection from connection pool and run operation using connection
    ///
    /// - Parameters:
    ///   - isolation: Actor isolation
    ///   - operation: Closure handling DNS connection
    /// - Returns: Value returned by closure
    @usableFromInline
    func withTCPConnection<RDataConv: RDataConvertible>(
        message factory: consuming MessageFactory<RDataConv>,
        options: DNSRequestOptions,
        isolation: isolated (any Actor)? = #isolation,
        operation: (
            consuming MessageFactory<RDataConv>,
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
            configuration: configuration.udpConnectionConfiguration,
            serverAddress: serverAddress
        )
        let udpConnection = try await udpConnectionFactory.makeUDPConnection(
            address: serverAddress,
            connectionID: 0,
            eventLoop: self.udpEventLoopGroup.any(),
            logger: logger
        )
        return udpConnection
    }
}

#if ServiceLifecycleSupport
@available(swiftDNSApplePlatforms 26, *)
extension PreferUDPOrUseTCPDNSClientTransport: Service {}
#endif  // ServiceLifecycle
