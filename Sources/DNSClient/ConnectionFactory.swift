import Logging
import NIOCore
import NIOPosix

#if canImport(Network)
import Network
import NIOTransportServices
#endif

struct ConnectionFactory {
    let socketAddress: SocketAddress
    let configuration: DNSConnectionConfiguration

    init(configuration: DNSConnectionConfiguration, serverAddress: DNSServerAddress) throws {
        self.configuration = configuration
        self.socketAddress = try serverAddress.asSocketAddress()
    }

    func makeUDPConnection(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger
    ) async throws -> DNSConnection {
        let (channelFuture, channelHandler) = self.makeInitializedUDPChannel(
            deadline: .now() + .seconds(10),
            eventLoop: eventLoop,
            logger: logger
        )
        let channel = try await channelFuture.get()
        return DNSConnection(
            channel: channel,
            connectionID: connectionID,
            channelHandler: channelHandler,
            configuration: self.configuration,
            logger: logger
        )
    }

    func makeTCPConnection(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger
    ) async throws -> DNSConnection {
        let (channelFuture, channelHandler) = self.makeInitializedTCPChannel(
            address: address,
            connectionID: connectionID,
            eventLoop: eventLoop,
            logger: logger
        )
        let channel = try await channelFuture.get()
        return DNSConnection(
            channel: channel,
            connectionID: connectionID,
            channelHandler: channelHandler,
            configuration: self.configuration,
            logger: logger
        )
    }
}

// MARK: - UDP
extension ConnectionFactory {
    private func makeUDPBootstrap(eventLoop: any EventLoop) -> DatagramBootstrap {
        DatagramBootstrap(group: eventLoop)
            .channelOption(
                ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR),
                value: 1
            )
            .channelOption(
                ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEPORT),
                value: 1
            )
    }

    private func makeUDPChannelHandler(
        eventLoop: any EventLoop,
        logger: Logger
    ) -> DNSChannelHandler {
        DNSChannelHandler(
            eventLoop: eventLoop,
            configuration: configuration,
            isOverUDP: true,
            logger: logger
        )
    }

    private func makeInitializedUDPBootstrap(
        /// FXIME: what about deadline?
        deadline: NIODeadline,
        eventLoop: any EventLoop,
        logger: Logger
    ) -> (DatagramBootstrap, DNSChannelHandler) {
        nonisolated(unsafe) let channelHandler = self.makeUDPChannelHandler(
            eventLoop: eventLoop,
            logger: logger
        )
        let bootstrap = self.makeUDPBootstrap(
            eventLoop: eventLoop
        ).channelInitializer { channel in
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

    private func makeInitializedUDPChannel(
        deadline: NIODeadline,
        eventLoop: any EventLoop,
        logger: Logger
    ) -> (EventLoopFuture<any Channel>, DNSChannelHandler) {
        // FIXME: some things are commented out for now
        // precondition(!self.key.scheme.usesTLS, "Unexpected scheme")
        let (bootstrap, channelHandler) = self.makeInitializedUDPBootstrap(
            deadline: deadline,
            eventLoop: eventLoop,
            logger: logger
        )
        let channelFuture = bootstrap.connect(to: self.socketAddress).flatMapErrorThrowing {
            error throws -> any Channel in
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
}

// MARK: - TCP
extension ConnectionFactory {
    @inlinable
    func makeTCPBootstrap(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger
    ) -> any NIOClientTCPBootstrapProtocol {
        eventLoop.assertInEventLoop()

        #if canImport(Network)
        if let tsBootstrap = self.createTSBootstrap(eventLoop: eventLoop, tlsOptions: nil) {
            return tsBootstrap
        } else {
            #if os(iOS) || os(tvOS)
            self.logger.warning(
                "Running BSD sockets on iOS or tvOS is not recommended. Please use NIOTSEventLoopGroup, to run with the Network framework"
            )
            #endif
            return self.createSocketsBootstrap(eventLoop: eventLoop)
        }
        #else
        return self.createSocketsBootstrap(eventLoopGroup: eventLoop)
        #endif
    }

    /// create a BSD sockets based bootstrap
    private func createSocketsBootstrap(eventLoop: any EventLoop) -> ClientBootstrap {
        ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
    }

    #if canImport(Network)
    /// create a NIOTransportServices bootstrap using Network.framework
    private func createTSBootstrap(
        eventLoop: any EventLoop,
        tlsOptions: NWProtocolTLS.Options?
    ) -> NIOTSConnectionBootstrap? {
        guard
            let bootstrap = NIOTSConnectionBootstrap(validatingGroup: eventLoop)?
                .channelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
        else {
            return nil
        }
        if let tlsOptions {
            return bootstrap.tlsOptions(tlsOptions)
        }
        return bootstrap
    }
    #endif

    private func makeTCPChannelHandler(
        eventLoop: any EventLoop,
        logger: Logger
    ) -> DNSChannelHandler {
        DNSChannelHandler(
            eventLoop: eventLoop,
            configuration: self.configuration,
            isOverUDP: false,
            logger: logger
        )
    }

    private func makeInitializedTCPBootstrap(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger
    ) -> (any NIOClientTCPBootstrapProtocol, DNSChannelHandler) {
        nonisolated(unsafe) let channelHandler = self.makeTCPChannelHandler(
            eventLoop: eventLoop,
            logger: logger
        )
        let bootstrap = self.makeTCPBootstrap(
            address: address,
            connectionID: connectionID,
            eventLoop: eventLoop,
            logger: logger
        ).channelInitializer { channel in
            channel.eventLoop.makeCompletedFuture {
                try channel.pipeline.syncOperations.addHandler(
                    channelHandler
                )
            }
        }
        return (bootstrap, channelHandler)
    }

    private func makeInitializedTCPChannel(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger
    ) -> (EventLoopFuture<any Channel>, DNSChannelHandler) {
        // FIXME: some things are commented out for now
        // precondition(!self.key.scheme.usesTLS, "Unexpected scheme")
        let (bootstrap, channelHandler) = self.makeInitializedTCPBootstrap(
            address: address,
            connectionID: connectionID,
            eventLoop: eventLoop,
            logger: logger
        )
        let channelFuture = bootstrap.connect(to: self.socketAddress).flatMapErrorThrowing {
            error throws -> any Channel in
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
}

// MARK: - +NIOClientTCPBootstrapProtocol
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
