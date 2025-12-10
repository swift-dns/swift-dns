import DNSClient
import Logging
import NIOCore
import NIOEmbedded
import Testing

struct DNSResolverTests {
    @available(swiftDNSApplePlatforms 10.15, *)
    @Test func `resolve A record where the original record is a CNAME`() async throws {
        let (connFactory, resolver) = try await self.makeResolver()
        try await withRunningDNSResolver(resolver) { resolver in
            let queryResource = Resources.dnsQueryAWwwExampleComPacket
            let responseResource = Resources.dnsResponseAWwwExampleComPacket
            let domainName = try #require(responseResource.domainName)

            let expectation = await connFactory.registerExpectationForNewUDPChannel()
            async let asyncResponse = try await resolver.resolveA(
                message: .forQuery(domainName: domainName)
            )

            await expectation.waitFulfillment()

            let channel = try await #require(connFactory.udpChannels.first)
            let channelCount = await connFactory.udpChannels.count
            #expect(channelCount == 1)

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound.readableBytesView.contains(domainName._data.readableBytesView))
            let messageID = try #require(outbound.peekInteger(as: UInt16.self))
            /// The message ID should not be 0 because the channel handler reassigns it
            #expect(messageID != 0)

            let queryBuffer = Utils.buffer(
                from: queryResource,
                changingIDTo: messageID
            )

            #expect(ByteBuffer(dnsBuffer: queryBuffer) == outbound)

            let (buffer, message) = Utils.bufferAndMessage(
                from: responseResource,
                changingIDTo: messageID
            )

            try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

            let response = try await asyncResponse
            /// FIXME: use equatable instead of string comparison
            #expect("\(response.message)" == "\(message)")
        }
    }

    @available(swiftDNSApplePlatforms 10.15, *)
    @Test func `resolve AAAA record where the original record is a CNAME`() async throws {
        let (connFactory, resolver) = try await self.makeResolver()
        try await withRunningDNSResolver(resolver) { resolver in
            let queryResource = Resources.dnsQueryAAAAWwwExampleComPacket
            let responseResource = Resources.dnsResponseAAAAWwwExampleComPacket
            let domainName = try #require(responseResource.domainName)

            let expectation = await connFactory.registerExpectationForNewUDPChannel()
            async let asyncResponse = try await resolver.resolveAAAA(
                message: .forQuery(domainName: domainName)
            )

            await expectation.waitFulfillment()

            let channel = try await #require(connFactory.udpChannels.first)
            let channelCount = await connFactory.udpChannels.count
            #expect(channelCount == 1)

            let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
            #expect(outbound.readableBytesView.contains(domainName._data.readableBytesView))
            let messageID = try #require(outbound.peekInteger(as: UInt16.self))
            /// The message ID should not be 0 because the channel handler reassigns it
            #expect(messageID != 0)

            let queryBuffer = Utils.buffer(
                from: queryResource,
                changingIDTo: messageID
            )

            #expect(ByteBuffer(dnsBuffer: queryBuffer) == outbound)

            let (buffer, message) = Utils.bufferAndMessage(
                from: responseResource,
                changingIDTo: messageID
            )

            try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

            let response = try await asyncResponse
            /// FIXME: use equatable instead of string comparison
            #expect("\(response.message)" == "\(message)")
        }
    }

    func makeResolver() async throws -> (
        factory: TestingDNSConnectionFactory,
        resolver: DNSResolver
    ) {
        let factory = TestingDNSConnectionFactory()
        let client = DNSClient(
            transport: try .preferUDPOrUseTCP(
                serverAddress: .domain(
                    domainName: DomainName(ipv4: IPv4Address(8, 8, 4, 4)),
                    port: 53
                ),
                udpConnectionConfiguration: .init(queryTimeout: .seconds(1)),
                udpConnectionFactory: .other(factory),
                tcpConfiguration: .init(
                    connectionConfiguration: .init(queryTimeout: .seconds(2)),
                    connectionPoolConfiguration: .init(),
                    keepAliveBehavior: .init()
                ),
                tcpConnectionFactory: .other(factory),
                logger: .init(label: "DNSClientTests")
            )
        )
        let resolver = DNSResolver(client: client)
        return (factory, resolver)
    }
}
