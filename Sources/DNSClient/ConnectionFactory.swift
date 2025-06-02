import Logging
import NIOCore
import NIOPosix

struct ConnectionFactory {
    let connectionTarget: ConnectionTarget

    func makeChannel(
        queryPool: QueryPool,
        deadline: NIODeadline,
        eventLoop: any EventLoop,
        logger: Logger
    ) -> EventLoopFuture<any Channel> {
        let channelFuture: EventLoopFuture<any Channel> = self.makePlainChannel(
            queryPool: queryPool,
            deadline: deadline,
            eventLoop: eventLoop
        )

        // FIXME: map `ChannelError.connectTimeout` into a `DNSClientError.connectTimeout` or smth
        return channelFuture.flatMapErrorThrowing { error throws -> any Channel in
            // switch error {
            // case ChannelError.connectTimeout:
            //     throw HTTPClientError.connectTimeout
            // default:
            throw error
            // }
        }
    }

    private func makePlainBootstrap(
        queryPool: QueryPool,
        deadline: NIODeadline,
        eventLoop: any EventLoop
    ) -> DatagramBootstrap {

        // FIXME: some things are commented out for now
        #if canImport(Network)
        // FIXME: need to do anything Network specific?
        #endif

        if let datagramBootstrap = DatagramBootstrap(validatingGroup: eventLoop) {
            return
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
                    let socketAddress: SocketAddress
                    do {
                        socketAddress = try self.connectionTarget.asSocketAddress()
                    } catch {
                        return channel.eventLoop.makeFailedFuture(error)
                    }
                    return channel.pipeline.addHandlers(
                        AddressedEnvelopeInboundChannelHandler(),
                        DNSDecoderChannelHandler(queryPool: queryPool),
                        AddressedEnvelopeOutboundChannelHandler(address: socketAddress),
                        DNSEncoderChannelHandler(queryPool: queryPool)
                    )
                }
        }

        preconditionFailure("No matching bootstrap found")
    }

    private func makePlainChannel(
        queryPool: QueryPool,
        deadline: NIODeadline,
        eventLoop: any EventLoop
    ) -> EventLoopFuture<any Channel> {
        // FIXME: some things are commented out for now
        // precondition(!self.key.scheme.usesTLS, "Unexpected scheme")
        let socketAddress: SocketAddress
        do {
            socketAddress = try self.connectionTarget.asSocketAddress()
        } catch {
            return eventLoop.makeFailedFuture(error)
        }
        return self.makePlainBootstrap(
            queryPool: queryPool,
            deadline: deadline,
            eventLoop: eventLoop
        ).connect(to: socketAddress)
    }
}

extension NIOClientTCPBootstrapProtocol {
    func connect(target: ConnectionTarget) -> EventLoopFuture<any Channel> {
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
