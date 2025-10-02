public import struct Logging.Logger
public import protocol NIOCore.EventLoopGroup

@available(swiftDNSApplePlatforms 15, *)
public struct DNSClientTransportFactory: Sendable {
    let transport: DNSClient.Transport

    init(transport: DNSClient.Transport) {
        self.transport = transport
    }

    public static func `default`(
        serverAddress: DNSServerAddress,
        udpConnectionConfiguration: DNSConnectionConfiguration = .init(),
        udpEventLoopGroup: any EventLoopGroup = DNSClient.defaultUDPEventLoopGroup,
        tcpConfiguration: TCPDNSClientTransportConfiguration = .init(),
        tcpEventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        logger: Logger = .noopLogger
    ) throws -> DNSClientTransportFactory {
        DNSClientTransportFactory(
            transport: .preferUDPOrUseTCP(
                try PreferUDPOrUseTCPDNSClientTransport(
                    serverAddress: serverAddress,
                    udpConnectionConfiguration: udpConnectionConfiguration,
                    udpEventLoopGroup: udpEventLoopGroup,
                    tcpConfiguration: tcpConfiguration,
                    tcpEventLoopGroup: tcpEventLoopGroup,
                    logger: logger
                )
            )
        )
    }

    public static func preferUDPOrUseTCP(
        serverAddress: DNSServerAddress,
        udpConnectionConfiguration: DNSConnectionConfiguration = .init(),
        udpEventLoopGroup: any EventLoopGroup = DNSClient.defaultUDPEventLoopGroup,
        tcpConfiguration: TCPDNSClientTransportConfiguration = .init(),
        tcpEventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        logger: Logger = .noopLogger
    ) throws -> DNSClientTransportFactory {
        DNSClientTransportFactory(
            transport: .preferUDPOrUseTCP(
                try PreferUDPOrUseTCPDNSClientTransport(
                    serverAddress: serverAddress,
                    udpConnectionConfiguration: udpConnectionConfiguration,
                    udpEventLoopGroup: udpEventLoopGroup,
                    tcpConfiguration: tcpConfiguration,
                    tcpEventLoopGroup: tcpEventLoopGroup,
                    logger: logger
                )
            )
        )
    }

    public static func tcp(
        serverAddress: DNSServerAddress,
        configuration: TCPDNSClientTransportConfiguration = .init(),
        eventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        logger: Logger = .noopLogger
    ) throws -> DNSClientTransportFactory {
        DNSClientTransportFactory(
            transport: .tcp(
                try TCPDNSClientTransport(
                    serverAddress: serverAddress,
                    configuration: configuration,
                    eventLoopGroup: eventLoopGroup,
                    logger: logger
                )
            )
        )
    }
}
