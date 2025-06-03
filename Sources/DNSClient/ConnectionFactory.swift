import Logging
import NIOCore
import NIOPosix

struct ConnectionFactory {
    let queryPool: QueryPool
    let socketAddress: SocketAddress

    init(queryPool: QueryPool, connectionTarget: ConnectionTarget) throws {
        self.queryPool = queryPool
        self.socketAddress = try connectionTarget.asSocketAddress()
    }

    func makeChannel(
        deadline: NIODeadline,
        eventLoop: any EventLoop,
        logger: Logger
    ) -> EventLoopFuture<any Channel> {
        self.makePlainChannel(
            deadline: deadline,
            eventLoop: eventLoop
        ).flatMapErrorThrowing { error throws -> any Channel in
            // FIXME: map `ChannelError.connectTimeout` into a `DNSClientError.connectTimeout` or smth

            // switch error {
            // case ChannelError.connectTimeout:
            //     throw HTTPClientError.connectTimeout
            // default:
            throw error
            // }
        }
    }

    private func makePlainBootstrap(
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
                    channel.eventLoop.makeCompletedFuture {
                        try channel.pipeline.syncOperations.addHandler(
                            AddressedEnvelopeInboundChannelHandler()
                        )
                        try channel.pipeline.syncOperations.addHandler(
                            AddressedEnvelopeOutboundChannelHandler(address: self.socketAddress)
                        )
                        try channel.pipeline.syncOperations.addHandler(
                            DNSChannelHandler(queryPool: queryPool)
                        )
                    }
                }
        }

        preconditionFailure("No matching bootstrap found")
    }

    private func makePlainChannel(
        deadline: NIODeadline,
        eventLoop: any EventLoop
    ) -> EventLoopFuture<any Channel> {
        // FIXME: some things are commented out for now
        // precondition(!self.key.scheme.usesTLS, "Unexpected scheme")
        self.makePlainBootstrap(
            deadline: deadline,
            eventLoop: eventLoop
        ).connect(to: self.socketAddress)
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
