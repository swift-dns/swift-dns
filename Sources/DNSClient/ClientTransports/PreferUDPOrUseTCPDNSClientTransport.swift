import Atomics
public import DNSModels
import _DNSConnectionPool

package import struct Logging.Logger
import struct NIOConcurrencyHelpers.NIOLockedValueBox
package import struct NIOCore.ByteBufferAllocator
package import protocol NIOCore.EventLoopGroup

#if ServiceLifecycleSupport
import ServiceLifecycle
#endif

/// Configuration for the DNS client
@available(swiftDNSApplePlatforms 13, *)
@usableFromInline
package actor PreferUDPOrUseTCPDNSClientTransport {
    package let serverAddress: DNSServerAddress
    package let connectionConfiguration: DNSConnectionConfiguration
    /// FIXME: using DNSConnection for now to have something sendable.
    @usableFromInline
    var udpConnection: DNSConnection?
    nonisolated let udpConnectionWaiters = NIOLockedValueBox<
        [CheckedContinuation<DNSConnection, Never>]
    >([])
    let udpEventLoopGroup: any EventLoopGroup
    let tcpTransport: TCPDNSClientTransport
    let logger: Logger
    let allocator: ByteBufferAllocator
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
        self.allocator = ByteBufferAllocator()
    }

    /// Run PreferUDPOrUseTCPDNSClientTransport's TCP connection pool
    @usableFromInline
    package func run() async {
        await self.tcpTransport.run(preRunHook: {
            await self.initializeNewUDPConnection()
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

@available(swiftDNSApplePlatforms 13, *)
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
            options: options,
            allocator: self.allocator
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
            try await self.withUDPConnection(
                message: factory,
                options: options,
                isolation: isolation,
                operation: operation
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

    func withUDPConnection<RData: RDataConvertible>(
        message factory: consuming MessageFactory<RData>,
        options: DNSRequestOptions,
        isolation: isolated (any Actor)? = #isolation,
        operation: (consuming MessageFactory<RData>, DNSRequestOptions, DNSConnection) async throws
            -> Message
    ) async throws -> Message {
        if let connection = await self.udpConnection {
            return try await operation(factory, options, connection)
        } else {
            let connection = await withCheckedContinuation { continuation in
                self.udpConnectionWaiters.withLockedValue {
                    $0.append(continuation)
                }
            }
            return try await operation(factory, options, connection)
        }
    }

    func makeUDPConnection() async throws -> DNSConnection {
        let udpConnectionFactory = try DNSConnectionFactory(
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

    func initializeNewUDPConnection() async {
        /// FIXME: need proper backoff and all
        /// possibly should extract this logic to its own mini-component
        do {
            self.udpConnection = try await self.makeUDPConnection()
            self.udpConnectionWaiters.withLockedValue { continuations in
                for continuation in continuations {
                    continuation.resume(returning: self.udpConnection!)
                }
                continuations.removeAll()
            }
        } catch {
            self.logger.warning(
                "Failed to initialize UDP connection, will retry in 5 seconds",
                metadata: [
                    "error": "\(String(reflecting: error))"
                ]
            )
            do {
                try await Task.sleep(for: .seconds(5))
            } catch {
                self.logger.warning(
                    "Failed to initialize UDP connection, and then noticed cancellation when retrying. Will not make new connection.",
                    metadata: [
                        "error": "\(String(reflecting: error))"
                    ]
                )
                return
            }
            await self.initializeNewUDPConnection()
        }
    }
}
