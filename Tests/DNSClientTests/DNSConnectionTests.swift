import DNSClient
import DNSModels
import Logging
import NIOCore
import NIOEmbedded
import Testing

@Suite
struct DNSConnectionTests {
    @available(swiftDNSApplePlatforms 15, *)
    @Test func `connection works`() async throws {
        let (connection, channel) = try await self.makeTestConnection()
        let domainName = try DomainName(string: "mahdibm.com")

        async let asyncResponse = try await connection.send(
            message: MessageFactory<MX>.forQuery(name: domainName),
            options: .default,
            allocator: .init()
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
        let messageID = try #require(outbound.peekInteger(as: UInt16.self))
        /// The message ID should not be 0 because the channel handler reassigns it
        #expect(messageID != 0)

        var buffer = Resources.dnsQueryMXMahdibmComPacket.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.setInteger(messageID, at: 42)
        let readerIndex = buffer.readerIndex
        let message = try Message(from: &buffer)
        /// Reset the reader index to reuse the buffer
        buffer.moveReaderIndex(to: readerIndex)

        try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

        let response = try await asyncResponse
        #expect("\(response)" == "\(message)")
    }

    @available(swiftDNSApplePlatforms 15, *)
    func makeTestConnection(
        configuration: DNSConnectionConfiguration = .init(),
        address: DNSServerAddress = .domain(
            name: DomainName(ipv4: IPv4Address(8, 8, 4, 4)),
            port: 53
        ),
        isOverUDP: Bool = true
    ) async throws -> (
        connection: DNSConnection,
        channel: NIOAsyncTestingChannel
    ) {
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
            connectionID: .random(in: .min ... .max),
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
