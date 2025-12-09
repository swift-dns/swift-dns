public import Logging
public import NIOCore
public import NIOPosix

import struct DNSModels.DomainName

#if canImport(Network)
public import Network
public import NIOTransportServices
#endif

@available(swiftDNSApplePlatforms 13, *)
@usableFromInline
package struct DefaultDNSConnectionFactory: Sendable, AnyDNSConnectionFactory {
    @usableFromInline
    let socketAddress: SocketAddress
    @usableFromInline
    let configuration: DNSConnectionConfiguration

    @inlinable
    package init(
        configuration: DNSConnectionConfiguration,
        serverAddress: DNSServerAddress
    ) throws {
        self.configuration = configuration
        self.socketAddress = try serverAddress.asSocketAddress()
    }

    @inlinable
    package func makeUDPConnection(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> DNSConnection {
        let (channelFuture, _channelHandler) = self.makeInitializedUDPChannel(
            deadline: eventLoop.now + .seconds(10),
            eventLoop: eventLoop,
            logger: logger,
            isolation: isolation
        )
        let channel = try await channelFuture.get()
        /// FIXME: This is safe but better solution than using nonisolated(unsafe)?
        nonisolated(unsafe) let channelHandler = _channelHandler
        return DNSConnection(
            channel: channel,
            connectionID: connectionID,
            channelHandler: channelHandler,
            configuration: self.configuration,
            logger: logger
        )
    }

    @inlinable
    package func makeTCPConnection(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> DNSConnection {
        let (channelFuture, _channelHandler) = self.makeInitializedTCPChannel(
            address: address,
            connectionID: connectionID,
            eventLoop: eventLoop,
            logger: logger,
            isolation: isolation
        )
        let channel = try await channelFuture.get()
        /// FIXME: This is safe but better solution than using nonisolated(unsafe)?
        nonisolated(unsafe) let channelHandler = _channelHandler
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
@available(swiftDNSApplePlatforms 13, *)
extension DefaultDNSConnectionFactory {
    @inlinable
    func makeUDPBootstrap(
        eventLoop: any EventLoop,
        isolation: isolated (any Actor)?
    ) -> DatagramBootstrap {
        /// FIXME: is this needed?
        // eventLoop.assertInEventLoop()

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

    @inlinable
    func makeUDPChannelHandler(
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)?
    ) -> DNSChannelHandler {
        DNSChannelHandler(
            eventLoop: eventLoop,
            configuration: configuration,
            isOverUDP: true,
            logger: logger
        )
    }

    @inlinable
    func makeInitializedUDPBootstrap(
        /// FXIME: what about deadline?
        deadline: NIODeadline,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)?
    ) -> (DatagramBootstrap, DNSChannelHandler) {
        nonisolated(unsafe) let channelHandler = self.makeUDPChannelHandler(
            eventLoop: eventLoop,
            logger: logger,
            isolation: isolation
        )
        let bootstrap = self.makeUDPBootstrap(
            eventLoop: eventLoop,
            isolation: isolation
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

    @inlinable
    func makeInitializedUDPChannel(
        deadline: NIODeadline,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)?
    ) -> (EventLoopFuture<any Channel>, DNSChannelHandler) {
        let (bootstrap, channelHandler) = self.makeInitializedUDPBootstrap(
            deadline: deadline,
            eventLoop: eventLoop,
            logger: logger,
            isolation: isolation
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
@available(swiftDNSApplePlatforms 13, *)
extension DefaultDNSConnectionFactory {
    @inlinable
    func makeTCPBootstrap(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)?
    ) -> any NIOClientTCPBootstrapProtocol {
        /// FIXME: is this needed?
        // eventLoop.assertInEventLoop()

        #if canImport(Network)
        if let tsBootstrap = self.createTSBootstrap(
            eventLoop: eventLoop,
            tlsOptions: nil,
            isolation: isolation
        ) {
            return tsBootstrap
        } else {
            #if os(iOS) || os(tvOS)
            self.logger.warning(
                "Running BSD sockets on iOS or tvOS is not recommended. Please use NIOTSEventLoopGroup, to run with the Network framework"
            )
            #endif
            return self.createSocketsBootstrap(
                eventLoop: eventLoop,
                isolation: isolation
            )
        }
        #else
        return self.createSocketsBootstrap(
            eventLoop: eventLoop,
            isolation: isolation
        )
        #endif
    }

    /// create a BSD sockets based bootstrap
    @inlinable
    func createSocketsBootstrap(
        eventLoop: any EventLoop,
        isolation: isolated (any Actor)?
    ) -> ClientBootstrap {
        ClientBootstrap(group: eventLoop)
            .channelOption(ChannelOptions.allowRemoteHalfClosure, value: true)
    }

    #if canImport(Network)
    /// create a NIOTransportServices bootstrap using Network.framework
    @inlinable
    func createTSBootstrap(
        eventLoop: any EventLoop,
        tlsOptions: NWProtocolTLS.Options?,
        isolation: isolated (any Actor)?
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

    @inlinable
    func makeTCPChannelHandler(
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)?
    ) -> DNSChannelHandler {
        DNSChannelHandler(
            eventLoop: eventLoop,
            configuration: self.configuration,
            isOverUDP: false,
            logger: logger
        )
    }

    @inlinable
    func makeInitializedTCPBootstrap(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)?
    ) -> (any NIOClientTCPBootstrapProtocol, DNSChannelHandler) {
        nonisolated(unsafe) let channelHandler = self.makeTCPChannelHandler(
            eventLoop: eventLoop,
            logger: logger,
            isolation: isolation
        )
        let bootstrap = self.makeTCPBootstrap(
            address: address,
            connectionID: connectionID,
            eventLoop: eventLoop,
            logger: logger,
            isolation: isolation
        ).channelInitializer { channel in
            channel.eventLoop.makeCompletedFuture {
                try channel.pipeline.syncOperations.addHandler(
                    ByteToMessageHandler(TCPFrameDecoder())
                )
                try channel.pipeline.syncOperations.addHandler(
                    MessageToByteHandler(TCPFrameEncoder())
                )
                try channel.pipeline.syncOperations.addHandler(
                    channelHandler
                )
            }
        }
        return (bootstrap, channelHandler)
    }

    @inlinable
    func makeInitializedTCPChannel(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)?
    ) -> (EventLoopFuture<any Channel>, DNSChannelHandler) {
        let (bootstrap, channelHandler) = self.makeInitializedTCPBootstrap(
            address: address,
            connectionID: connectionID,
            eventLoop: eventLoop,
            logger: logger,
            isolation: isolation
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
@available(swiftDNSApplePlatforms 10.15, *)
extension NIOClientTCPBootstrapProtocol {
    func connect(target: DNSServerAddress) -> EventLoopFuture<any Channel> {
        switch target {
        case .ipAddress(_, let socketAddress):
            return self.connect(to: socketAddress)
        case .domain(let domain, let port):
            return self.connect(host: domain.description(format: .ascii), port: Int(port))
        case .unixSocket(let path):
            return self.connect(unixDomainSocketPath: path)
        }
    }
}
