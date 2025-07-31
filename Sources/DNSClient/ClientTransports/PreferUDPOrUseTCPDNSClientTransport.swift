public import DNSModels
import Synchronization
import _DNSConnectionPool

package import struct Logging.Logger
package import protocol NIOCore.EventLoopGroup

#if ServiceLifecycleSupport
import ServiceLifecycle
#endif

/// Configuration for the DNS client
@available(swiftDNSApplePlatforms 26, *)
@usableFromInline
package actor PreferUDPOrUseTCPDNSClientTransport {
    package let serverAddress: DNSServerAddress
    package let connectionConfiguration: DNSConnectionConfiguration
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
    let udpEventLoopGroup: any EventLoopGroup
    let tcpTransport: TCPDNSClientTransport
    let logger: Logger
    var isRunning: Bool {
        self.tcpTransport.isRunning.load(ordering: .relaxed)
    }

    package init(
        serverAddress: DNSServerAddress,
        udpConnectionConfiguration: DNSConnectionConfiguration = .init(),
        udpEventLoopGroup: any EventLoopGroup = DNSClient.defaultUDPEventLoopGroup,
        tcpConfiguration: TCPDNSClientTransportConfiguration = .init(),
        tcpEventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        logger: Logger = .noopLogger
    ) throws {
        self.serverAddress = serverAddress
        self.connectionConfiguration = udpConnectionConfiguration
        self.tcpTransport = try TCPDNSClientTransport(
            serverAddress: serverAddress,
            configuration: tcpConfiguration,
            eventLoopGroup: tcpEventLoopGroup,
            logger: logger
        )
        self.udpEventLoopGroup = udpEventLoopGroup
        self.logger = logger
    }

    /// Run PreferUDPOrUseTCPDNSClientTransport's TCP connection pool
    @usableFromInline
    package func run() async {
        await self.tcpTransport.run(preRunHook: {
            /// Initiate the UDP connection
        })
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
        /// FIXME: Add logic to choose TCP when it should
        switch true {
        case true:
            try await operation(
                factory,
                options,
                self.udpConnection
            )
        case false:
            try await self.tcpTransport.withConnection(
                message: factory,
                options: options,
                isolation: isolation,
                operation: operation
            )
        }
    }

    func makeUDPConnection() async throws -> DNSConnection {
        let udpConnectionFactory = try ConnectionFactory(
            configuration: self.connectionConfiguration,
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
