public import struct Logging.Logger
public import protocol NIOCore.EventLoopGroup

@available(swiftDNSApplePlatforms 26, *)
extension DNSClient {
    /// The default transport. The same as `preferUDPOrUseTCP`.
    public static func defaultTransport(
        serverAddress: DNSServerAddress,
        udpConnectionConfiguration: DNSConnectionConfiguration = .init(),
        udpEventLoopGroup: any EventLoopGroup = DNSClient.defaultUDPEventLoopGroup,
        tcpConfiguration: TCPDNSClientTransportConfiguration = .init(),
        tcpEventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        logger: Logger = .noopLogger
    ) throws -> DNSClient {
        try .preferUDPOrUseTCPTransport(
            serverAddress: serverAddress,
            udpConnectionConfiguration: udpConnectionConfiguration,
            udpEventLoopGroup: udpEventLoopGroup,
            tcpConfiguration: tcpConfiguration,
            tcpEventLoopGroup: tcpEventLoopGroup,
            logger: logger
        )
    }

    public static func preferUDPOrUseTCPTransport(
        serverAddress: DNSServerAddress,
        udpConnectionConfiguration: DNSConnectionConfiguration = .init(),
        udpEventLoopGroup: any EventLoopGroup = DNSClient.defaultUDPEventLoopGroup,
        tcpConfiguration: TCPDNSClientTransportConfiguration = .init(),
        tcpEventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        logger: Logger = .noopLogger
    ) throws -> DNSClient {
        try DNSClient(
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

    public static func tcpTransport(
        serverAddress: DNSServerAddress,
        configuration: TCPDNSClientTransportConfiguration = .init(),
        eventLoopGroup: any EventLoopGroup = DNSClient.defaultTCPEventLoopGroup,
        logger: Logger = .noopLogger
    ) throws -> DNSClient {
        try DNSClient(
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
