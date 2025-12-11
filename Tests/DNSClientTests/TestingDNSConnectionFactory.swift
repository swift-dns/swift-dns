import DNSClient
import Logging
import NIOCore
import NIOEmbedded
import Testing

@available(swiftDNSApplePlatforms 10.15, *)
actor TestingDNSConnectionFactory {
    typealias ChannelsKeyPath = ReferenceWritableKeyPath<
        TestingDNSConnectionFactory, [NIOAsyncTestingChannel]
    >

    let udpConnectionConfiguration: DNSConnectionConfiguration
    let tcpConnectionConfiguration: DNSConnectionConfiguration

    var udpChannels: [NIOAsyncTestingChannel] = []
    var tcpChannels: [NIOAsyncTestingChannel] = []

    var udpConfirmations: [Expectation] = []
    var tcpConfirmations: [Expectation] = []

    init(
        udpConnectionConfiguration: DNSConnectionConfiguration = .init(),
        tcpConnectionConfiguration: DNSConnectionConfiguration = .init()
    ) {
        self.udpConnectionConfiguration = udpConnectionConfiguration
        self.tcpConnectionConfiguration = tcpConnectionConfiguration
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension TestingDNSConnectionFactory {
    struct Expectation {
        private let stream: AsyncStream<Void>
        private let continuation: AsyncStream<Void>.Continuation

        init() {
            (self.stream, self.continuation) = AsyncStream.makeStream(of: Void.self)
        }

        func fulfill() {
            self.continuation.finish()
        }

        func waitFulfillment() async {
            for await _ in self.stream {}
        }
    }

    func registerExpectationForNewUDPChannel() -> Expectation {
        let expectation = Expectation()
        self.udpConfirmations.append(expectation)
        return expectation
    }

    func registerExpectationForNewTCPChannel() -> Expectation {
        let expectation = Expectation()
        self.tcpConfirmations.append(expectation)
        return expectation
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension TestingDNSConnectionFactory: AnyDNSConnectionFactory {
    private func appendUDPChannel(_ channel: NIOAsyncTestingChannel) {
        self.udpChannels.append(channel)
        for expectation in self.udpConfirmations {
            expectation.fulfill()
        }
        self.udpConfirmations.removeAll()
    }

    private func appendTCPChannel(_ channel: NIOAsyncTestingChannel) {
        self.tcpChannels.append(channel)
        for expectation in self.tcpConfirmations {
            expectation.fulfill()
        }
        self.tcpConfirmations.removeAll()
    }

    package func makeUDPConnection(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> DNSConnection {
        let (connection, channel) = try await Self.makeTestConnection(
            configuration: self.udpConnectionConfiguration,
            address: address,
            connectionID: connectionID,
            isOverUDP: true
        )
        await self.appendUDPChannel(channel)
        return connection
    }

    package func makeTCPConnection(
        address: DNSServerAddress,
        connectionID: Int,
        eventLoop: any EventLoop,
        logger: Logger,
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> DNSConnection {
        let (connection, channel) = try await Self.makeTestConnection(
            configuration: self.tcpConnectionConfiguration,
            address: address,
            connectionID: connectionID,
            isOverUDP: false
        )
        await self.appendTCPChannel(channel)
        return connection
    }
}

extension TestingDNSConnectionFactory {
    static func makeTestConnection(
        configuration: DNSConnectionConfiguration = .init(),
        address: DNSServerAddress? = nil,
        connectionID: Int = .random(in: .min ... .max),
        isOverUDP: Bool = true
    ) async throws -> (
        connection: DNSConnection,
        channel: NIOAsyncTestingChannel
    ) {
        let ipv4Address: IPv4Address = isOverUDP ? .defaultTestDNSServer : .defaultTestDNSServer
        let address = address ?? .domain(domainName: DomainName(ipv4: ipv4Address), port: 53)
        let channel = NIOAsyncTestingChannel()
        let logger = Logger(label: "test")
        /// FIXME: This is safe but better solution than using nonisolated(unsafe)?
        nonisolated(unsafe) let channelHandler = DNSChannelHandler(
            eventLoop: channel.eventLoop,
            configuration: configuration,
            isOverUDP: isOverUDP,
            logger: logger
        )
        let connection = DNSConnection(
            channel: channel,
            connectionID: connectionID,
            channelHandler: channelHandler,
            configuration: configuration,
            logger: logger
        )
        channel.eventLoop.execute {
            try! channel.pipeline.syncOperations.addHandler(channelHandler)
        }
        try await channel.connect(to: address.asSocketAddress())
        return (connection, channel)
    }
}
