import Logging
import NIOCore
import NIOPosix

struct ConnectionFactory {
    let socketAddress: SocketAddress
    let configuration: DNSConnectionConfiguration

    init(configuration: DNSConnectionConfiguration, serverAddress: DNSServerAddress) throws {
        self.configuration = configuration
        self.socketAddress = try serverAddress.asSocketAddress()
    }

    func makeConnection(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger
    ) async throws -> DNSConnection {
        let (channelFuture, channelHandler) = self.makeChannel(
            deadline: .now() + .seconds(10),
            eventLoop: eventLoop,
            logger: logger
        )
        let channel = try await channelFuture.get()
        return DNSConnection(
            channel: channel,
            connectionID: connectionID,
            channelHandler: channelHandler,
            configuration: configuration,
            logger: logger
        )
    }

    func makeChannel(
        deadline: NIODeadline,
        eventLoop: any EventLoop,
        logger: Logger
    ) -> (EventLoopFuture<any Channel>, DNSChannelHandler) {
        var (channelFuture, channelHandler) = self.makePlainChannel(
            deadline: deadline,
            eventLoop: eventLoop,
            logger: logger
        )
        channelFuture = channelFuture.flatMapErrorThrowing { error throws -> any Channel in
            // FIXME: map `ChannelError.connectTimeout` into a `DNSClientError.connectTimeout` or smth

            // switch error {
            // case ChannelError.connectTimeout:
            //     throw HTTPClientError.connectTimeout
            // default:
            throw error
            // }
        }
        return (channelFuture, channelHandler)
    }

    private func makePlainBootstrap(
        /// FXIME: what about deadline?
        deadline: NIODeadline,
        eventLoop: any EventLoop,
        logger: Logger
    ) -> (DatagramBootstrap, DNSChannelHandler) {

        // FIXME: some things are commented out for now
        #if canImport(Network)
        // FIXME: need to do anything Network specific?
        #endif

        if let datagramBootstrap = DatagramBootstrap(validatingGroup: eventLoop) {
            nonisolated(unsafe) let channelHandler = DNSChannelHandler(
                eventLoop: eventLoop,
                configuration: configuration,
                isOverUDP: true,
                logger: logger
            )
            let bootstrap =
                datagramBootstrap
                .channelOption(
                    ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR),
                    value: 1
                )
                .channelOption(
                    ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEPORT),
                    value: 1
                )
                .channelInitializer { channel in
                    channel.eventLoop.makeCompletedFuture {
                        try channel.pipeline.syncOperations.addHandler(
                            AddressedEnvelopeInboundChannelHandler()
                        )
                        try channel.pipeline.syncOperations.addHandler(
                            AddressedEnvelopeOutboundChannelHandler(address: self.socketAddress)
                        )
                        try channel.pipeline.syncOperations.addHandler(
                            channelHandler
                        )
                    }
                }
            return (bootstrap, channelHandler)
        }

        preconditionFailure("No matching bootstrap found")
    }

    private func makePlainChannel(
        deadline: NIODeadline,
        eventLoop: any EventLoop,
        logger: Logger
    ) -> (EventLoopFuture<any Channel>, DNSChannelHandler) {
        // FIXME: some things are commented out for now
        // precondition(!self.key.scheme.usesTLS, "Unexpected scheme")
        let (bootstrap, channelHandler) = self.makePlainBootstrap(
            deadline: deadline,
            eventLoop: eventLoop,
            logger: logger
        )
        let channelFuture = bootstrap.connect(to: self.socketAddress)
        return (channelFuture, channelHandler)
    }
}

extension NIOClientTCPBootstrapProtocol {
    func connect(target: DNSServerAddress) -> EventLoopFuture<any Channel> {
        switch target {
        case .ipAddress(_, let socketAddress):
            return self.connect(to: socketAddress)
        case .domain(let domain, let port):
            return self.connect(host: domain, port: port)
        case .unixSocket(let path):
            return self.connect(unixDomainSocketPath: path)
        }
    }
}
