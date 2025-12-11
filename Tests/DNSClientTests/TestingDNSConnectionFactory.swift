import DNSClient
import Logging
import NIOCore
import NIOEmbedded
import Testing

/// This is not supposed to be used concurrently, although it is Sendable to satisfy the
/// ``AnyDNSConnectionFactory`` protocol.
@available(swiftDNSApplePlatforms 10.15, *)
actor TestingDNSConnectionFactory {
    typealias ChannelsKeyPath = ReferenceWritableKeyPath<
        TestingDNSConnectionFactory, [NIOAsyncTestingChannel]
    >

    let udpConnectionConfiguration: DNSConnectionConfiguration
    let tcpConnectionConfiguration: DNSConnectionConfiguration

    var udpChannels: [NIOAsyncTestingChannel] = []
    var tcpChannels: [NIOAsyncTestingChannel] = []

    var udpExpectations: [Expectation] = []
    var tcpExpectations: [Expectation] = []

    init(
        udpConnectionConfiguration: DNSConnectionConfiguration = .init(),
        tcpConnectionConfiguration: DNSConnectionConfiguration = .init()
    ) {
        self.udpConnectionConfiguration = udpConnectionConfiguration
        self.tcpConnectionConfiguration = tcpConnectionConfiguration
    }
}

extension TestingDNSConnectionFactory {
    typealias FactoryAndResolver = (
        factory: TestingDNSConnectionFactory,
        resolver: DNSResolver
    )

    static func makeConnFactoryAndDNSResolvers() -> [FactoryAndResolver] {
        [
            self.makeUDPConnFactoryAndDNSResolver(),
            self.makeTCPConnFactoryAndDNSResolver(),
        ]
    }

    private static func makeUDPConnFactoryAndDNSResolver() -> FactoryAndResolver {
        let factory = TestingDNSConnectionFactory()
        let client = DNSClient(
            transport: try! .preferUDPOrUseTCP(
                serverAddress: .domain(
                    domainName: DomainName(ipv4: .defaultTestDNSServer),
                    port: 53
                ),
                udpConnectionConfiguration: .init(queryTimeout: .seconds(1)),
                udpConnectionFactory: .other(factory),
                tcpConfiguration: .init(
                    connectionConfiguration: .init(queryTimeout: .seconds(2)),
                    connectionPoolConfiguration: .init(
                        minimumConnectionCount: 1,
                        maximumConnectionSoftLimit: 1,
                        maximumConnectionHardLimit: 1
                    ),
                    keepAliveBehavior: .init()
                ),
                tcpConnectionFactory: .other(factory),
                logger: .init(label: "DNSClientTests")
            )
        )
        let resolver = DNSResolver(client: client)
        return (factory, resolver)
    }

    private static func makeTCPConnFactoryAndDNSResolver() -> FactoryAndResolver {
        let factory = TestingDNSConnectionFactory()
        let client = DNSClient(
            transport: try! .tcp(
                serverAddress: .domain(
                    domainName: DomainName(ipv4: .defaultTestDNSServer),
                    port: 53
                ),
                configuration: .init(
                    connectionConfiguration: .init(queryTimeout: .seconds(2)),
                    connectionPoolConfiguration: .init(
                        minimumConnectionCount: 1,
                        maximumConnectionSoftLimit: 1,
                        maximumConnectionHardLimit: 1
                    ),
                    keepAliveBehavior: .init()
                ),
                connectionFactory: .other(factory),
                logger: .init(label: "DNSClientTests")
            )
        )
        let resolver = DNSResolver(client: client)
        return (factory, resolver)
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

        func waitFulfillment(timeout: Duration = .seconds(1)) async throws {
            try await withTimeout(in: timeout, clock: .continuous) {
                for await _ in self.stream {}
            }
        }
    }

    func registerExpectationForNewChannel(udp: Bool) -> Expectation {
        let expectation = Expectation()
        if udp {
            self.udpExpectations.append(expectation)
        } else {
            self.tcpExpectations.append(expectation)
        }
        return expectation
    }

    func getFirstChannel(udp: Bool) -> NIOAsyncTestingChannel? {
        if udp {
            return self.udpChannels.first
        } else {
            return self.tcpChannels.first
        }
    }

    func waitForOutboundMessage(udp: Bool) async throws -> Message {
        let udpChannels = self.udpChannels
        let tcpChannels = self.tcpChannels
        return try await withTimeout(in: .seconds(1), clock: .continuous) {
            if udp {
                try #require(udpChannels.count == 1)
                return try await self.udpChannels[0].waitForOutboundMessage()
            } else {
                try #require(tcpChannels.count == 1)
                return try await self.tcpChannels[0].waitForOutboundMessage()
            }
        }
    }

    func writeInboundMessage(udp: Bool, message: Message) async throws {
        if udp {
            try #require(self.udpChannels.count == 1)
            try await self.udpChannels[0].writeInboundMessage(message)
        } else {
            try #require(self.tcpChannels.count == 1)
            try await self.tcpChannels[0].writeInboundMessage(message)
        }
    }
}

@available(swiftDNSApplePlatforms 10.15, *)
extension TestingDNSConnectionFactory: AnyDNSConnectionFactory {
    private func appendUDPChannel(_ channel: NIOAsyncTestingChannel) {
        self.udpChannels.append(channel)
        for expectation in self.udpExpectations {
            expectation.fulfill()
        }
        self.udpExpectations.removeAll()
    }

    private func appendTCPChannel(_ channel: NIOAsyncTestingChannel) {
        self.tcpChannels.append(channel)
        for expectation in self.tcpExpectations {
            expectation.fulfill()
        }
        self.tcpExpectations.removeAll()
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
