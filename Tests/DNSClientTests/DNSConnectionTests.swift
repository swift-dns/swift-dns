import DNSClient
import DNSModels
import Logging
import NIOCore
import NIOEmbedded
import Testing

@Suite
struct DNSConnectionTests {
    @available(swiftDNSApplePlatforms 15, *)
    @Test func `simple A query`() async throws {
        typealias QueryableType = A

        let (connection, channel) = try await self.makeTestConnection()
        let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
        let domainName = try #require(responseResource.domainName)

        async let asyncResponse = try await connection.send(
            message: MessageFactory<QueryableType>.forQuery(name: domainName),
            options: .default,
            allocator: .init()
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
        let messageID = try #require(outbound.peekInteger(as: UInt16.self))
        /// The message ID should not be 0 because the channel handler reassigns it
        #expect(messageID != 0)

        let (buffer, message) = try self.bufferAndMessage(
            from: responseResource,
            changingIDTo: messageID
        )

        try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

        let response = try await asyncResponse
        /// FIXME: use equatable instead of string comparison
        #expect("\(response)" == "\(message)")
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func `simple AAAA query`() async throws {
        typealias QueryableType = AAAA

        let (connection, channel) = try await self.makeTestConnection()
        let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
        let domainName = try #require(responseResource.domainName)

        async let asyncResponse = try await connection.send(
            message: MessageFactory<QueryableType>.forQuery(name: domainName),
            options: .default,
            allocator: .init()
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
        let messageID = try #require(outbound.peekInteger(as: UInt16.self))
        /// The message ID should not be 0 because the channel handler reassigns it
        #expect(messageID != 0)

        let (buffer, message) = try self.bufferAndMessage(
            from: responseResource,
            changingIDTo: messageID
        )

        try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

        let response = try await asyncResponse
        /// FIXME: use equatable instead of string comparison
        #expect("\(response)" == "\(message)")
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func `simple TXT query`() async throws {
        typealias QueryableType = TXT

        let (connection, channel) = try await self.makeTestConnection()
        let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
        let domainName = try #require(responseResource.domainName)

        async let asyncResponse = try await connection.send(
            message: MessageFactory<QueryableType>.forQuery(name: domainName),
            options: .default,
            allocator: .init()
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
        let messageID = try #require(outbound.peekInteger(as: UInt16.self))
        /// The message ID should not be 0 because the channel handler reassigns it
        #expect(messageID != 0)

        let (buffer, message) = try self.bufferAndMessage(
            from: responseResource,
            changingIDTo: messageID
        )

        try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

        let response = try await asyncResponse
        /// FIXME: use equatable instead of string comparison
        #expect("\(response)" == "\(message)")
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func `simple PTR query`() async throws {
        typealias QueryableType = PTR

        let (connection, channel) = try await self.makeTestConnection()
        let (_, responseResource) = Resources.forQuery(queryableType: QueryableType.self)
        let domainName = try #require(responseResource.domainName)

        async let asyncResponse = try await connection.send(
            message: MessageFactory<QueryableType>.forQuery(name: domainName),
            options: .default,
            allocator: .init()
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
        let messageID = try #require(outbound.peekInteger(as: UInt16.self))
        /// The message ID should not be 0 because the channel handler reassigns it
        #expect(messageID != 0)

        let (buffer, message) = try self.bufferAndMessage(
            from: responseResource,
            changingIDTo: messageID
        )

        try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

        let response = try await asyncResponse
        /// FIXME: use equatable instead of string comparison
        #expect("\(response)" == "\(message)")
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func `concurrent MX queries over one connection`() async throws {
        typealias QueryableType = MX

        let (connection, channel) = try await self.makeTestConnection()

        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for _ in 0..<100 {
                taskGroup.addTask {
                    let (_, responseResource) = Resources.forQuery(
                        queryableType: QueryableType.self
                    )
                    let domainName = try #require(responseResource.domainName)

                    async let asyncResponse = try await connection.send(
                        message: MessageFactory<QueryableType>.forQuery(name: domainName),
                        options: .default,
                        allocator: .init()
                    )

                    let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
                    #expect(outbound.readableBytesView.contains(domainName.data.readableBytesView))
                    let messageID = try #require(outbound.peekInteger(as: UInt16.self))
                    /// The message ID should not be 0 because the channel handler reassigns it
                    #expect(messageID != 0)

                    let (buffer, message) = try self.bufferAndMessage(
                        from: responseResource,
                        changingIDTo: messageID
                    )

                    try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

                    let response = try await asyncResponse
                    /// FIXME: use equatable instead of string comparison
                    #expect(
                        "\(response)" == "\(message)",
                        "\(response.header.id) != \(message.header.id)"
                    )
                }
            }

            try await taskGroup.waitForAll()
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    func bufferAndMessage(
        from resource: Resources,
        changingIDTo messageID: UInt16?
    ) throws -> (buffer: DNSBuffer, message: Message) {
        var buffer = resource.buffer()
        buffer.moveReaderIndex(forwardBy: 42)
        buffer.moveDNSPortionStartIndex(forwardBy: 42)
        if let messageID {
            buffer.setInteger(messageID, at: 42)
        }
        let readerIndex = buffer.readerIndex
        let message = try Message(from: &buffer)
        /// Reset the reader index to reuse the buffer
        buffer.moveReaderIndex(to: readerIndex)
        return (buffer, message)
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
