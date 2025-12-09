public import struct Logging.Logger
public import protocol NIOCore.EventLoopGroup

@available(swiftDNSApplePlatforms 13, *)
public struct DNSClientTransportFactory: Sendable {
    @usableFromInline
    let transport: DNSClient.Transport

    @inlinable
    init(transport: DNSClient.Transport) {
        self.transport = transport
    }

    @inlinable
    package static func `default`(
        serverAddress: DNSServerAddress,
        udpConnectionConfiguration: DNSConnectionConfiguration = .init(),
        udpEventLoopGroup: any EventLoopGroup = DNSClient.defaultUDPEventLoopGroup,
        udpConnectionFactory: DNSConnectionFactory,
        tcpConfiguration: TCPDNSClientTransportConfiguration = .init(),
        tcpEventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        tcpConnectionFactory: DNSConnectionFactory,
        logger: Logger = .noopLogger
    ) throws -> DNSClientTransportFactory {
        DNSClientTransportFactory(
            transport: .preferUDPOrUseTCP(
                try PreferUDPOrUseTCPDNSClientTransport(
                    serverAddress: serverAddress,
                    udpConnectionConfiguration: udpConnectionConfiguration,
                    udpEventLoopGroup: udpEventLoopGroup,
                    udpConnectionFactory: udpConnectionFactory,
                    tcpConfiguration: tcpConfiguration,
                    tcpEventLoopGroup: tcpEventLoopGroup,
                    tcpConnectionFactory: tcpConnectionFactory,
                    logger: logger
                )
            )
        )
    }

    @inlinable
    public static func `default`(
        serverAddress: DNSServerAddress,
        udpConnectionConfiguration: DNSConnectionConfiguration = .init(),
        udpEventLoopGroup: any EventLoopGroup = DNSClient.defaultUDPEventLoopGroup,
        tcpConfiguration: TCPDNSClientTransportConfiguration = .init(),
        tcpEventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        logger: Logger = .noopLogger
    ) throws -> DNSClientTransportFactory {
        let udpConnectionFactory = try DNSConnectionFactory.default(
            configuration: udpConnectionConfiguration,
            serverAddress: serverAddress
        )
        let tcpConnectionFactory = try DNSConnectionFactory.default(
            configuration: tcpConfiguration.connectionConfiguration,
            serverAddress: serverAddress
        )
        return try .default(
            serverAddress: serverAddress,
            udpConnectionConfiguration: udpConnectionConfiguration,
            udpEventLoopGroup: udpEventLoopGroup,
            udpConnectionFactory: udpConnectionFactory,
            tcpConfiguration: tcpConfiguration,
            tcpEventLoopGroup: tcpEventLoopGroup,
            tcpConnectionFactory: tcpConnectionFactory,
            logger: logger
        )
    }

    @inlinable
    package static func preferUDPOrUseTCP(
        serverAddress: DNSServerAddress,
        udpConnectionConfiguration: DNSConnectionConfiguration = .init(),
        udpEventLoopGroup: any EventLoopGroup = DNSClient.defaultUDPEventLoopGroup,
        udpConnectionFactory: DNSConnectionFactory,
        tcpConfiguration: TCPDNSClientTransportConfiguration = .init(),
        tcpEventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        tcpConnectionFactory: DNSConnectionFactory,
        logger: Logger = .noopLogger
    ) throws -> DNSClientTransportFactory {
        DNSClientTransportFactory(
            transport: .preferUDPOrUseTCP(
                try PreferUDPOrUseTCPDNSClientTransport(
                    serverAddress: serverAddress,
                    udpConnectionConfiguration: udpConnectionConfiguration,
                    udpEventLoopGroup: udpEventLoopGroup,
                    udpConnectionFactory: udpConnectionFactory,
                    tcpConfiguration: tcpConfiguration,
                    tcpEventLoopGroup: tcpEventLoopGroup,
                    tcpConnectionFactory: tcpConnectionFactory,
                    logger: logger
                )
            )
        )
    }

    @inlinable
    public static func preferUDPOrUseTCP(
        serverAddress: DNSServerAddress,
        udpConnectionConfiguration: DNSConnectionConfiguration = .init(),
        udpEventLoopGroup: any EventLoopGroup = DNSClient.defaultUDPEventLoopGroup,
        tcpConfiguration: TCPDNSClientTransportConfiguration = .init(),
        tcpEventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        logger: Logger = .noopLogger
    ) throws -> DNSClientTransportFactory {
        let udpConnectionFactory = try DNSConnectionFactory.default(
            configuration: udpConnectionConfiguration,
            serverAddress: serverAddress
        )
        let tcpConnectionFactory = try DNSConnectionFactory.default(
            configuration: tcpConfiguration.connectionConfiguration,
            serverAddress: serverAddress
        )
        return try .preferUDPOrUseTCP(
            serverAddress: serverAddress,
            udpConnectionConfiguration: udpConnectionConfiguration,
            udpEventLoopGroup: udpEventLoopGroup,
            udpConnectionFactory: udpConnectionFactory,
            tcpConfiguration: tcpConfiguration,
            tcpEventLoopGroup: tcpEventLoopGroup,
            tcpConnectionFactory: tcpConnectionFactory,
            logger: logger
        )
    }

    @inlinable
    package static func tcp(
        serverAddress: DNSServerAddress,
        configuration: TCPDNSClientTransportConfiguration = .init(),
        eventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        connectionFactory: DNSConnectionFactory,
        logger: Logger = .noopLogger
    ) throws -> DNSClientTransportFactory {
        DNSClientTransportFactory(
            transport: .tcp(
                try TCPDNSClientTransport(
                    serverAddress: serverAddress,
                    configuration: configuration,
                    eventLoopGroup: eventLoopGroup,
                    connectionFactory: connectionFactory,
                    logger: logger
                )
            )
        )
    }

    @inlinable
    public static func tcp(
        serverAddress: DNSServerAddress,
        configuration: TCPDNSClientTransportConfiguration = .init(),
        eventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        logger: Logger = .noopLogger
    ) throws -> DNSClientTransportFactory {
        let connectionFactory = try DNSConnectionFactory.default(
            configuration: configuration.connectionConfiguration,
            serverAddress: serverAddress
        )
        return try .tcp(
            serverAddress: serverAddress,
            configuration: configuration,
            eventLoopGroup: eventLoopGroup,
            connectionFactory: connectionFactory,
            logger: logger
        )
    }
}
