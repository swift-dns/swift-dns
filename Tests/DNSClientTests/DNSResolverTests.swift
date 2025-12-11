import DNSClient
import Logging
import NIOCore
import NIOEmbedded
import Testing

struct DNSResolverTests {
    @available(swiftDNSApplePlatforms 10.15, *)
    @Test(arguments: TestingDNSConnectionFactory.makeConnFactoryAndDNSResolvers())
    func `resolve A record where the original record is a CNAME`(
        connFactory: TestingDNSConnectionFactory,
        resolver: DNSResolver
    ) async throws {
        try await withRunningDNSResolver(resolver) { resolver in
            let queryResource = Resources.dnsQueryAWwwExampleComPacket
            let responseResource = Resources.dnsResponseAWwwExampleComPacket
            let domainName = try #require(responseResource.domainName)
            let isOverUDP = await resolver.client.isOverUDP

            let expectation = await connFactory.registerExpectationForNewChannel(udp: isOverUDP)
            async let asyncResponse = try await resolver.resolveA(
                message: .forQuery(domainName: domainName)
            )

            await expectation.waitFulfillment()

            /// With TCP, technically we might have multiple channels.
            /// For now we just get the first one and it's working since PostgresNIO's conn-pool
            /// implementation which we use, just uses the first conn for the first query.
            let channel = try #require(await connFactory.getFirstChannel(udp: isOverUDP))
            let channelCount = await connFactory.udpChannels.count
            #expect(channelCount <= 1)

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
    @Test(arguments: TestingDNSConnectionFactory.makeConnFactoryAndDNSResolvers())
    func `resolve AAAA record where the original record is a CNAME`(
        connFactory: TestingDNSConnectionFactory,
        resolver: DNSResolver
    ) async throws {
        try await withRunningDNSResolver(resolver) { resolver in
            let queryResource = Resources.dnsQueryAAAAWwwExampleComPacket
            let responseResource = Resources.dnsResponseAAAAWwwExampleComPacket
            let domainName = try #require(responseResource.domainName)
            let isOverUDP = await resolver.client.isOverUDP

            let expectation = await connFactory.registerExpectationForNewChannel(udp: isOverUDP)
            async let asyncResponse = try await resolver.resolveAAAA(
                message: .forQuery(domainName: domainName)
            )

            await expectation.waitFulfillment()

            let channel = try #require(await connFactory.getFirstChannel(udp: isOverUDP))
            let channelCount = await connFactory.udpChannels.count
            #expect(channelCount <= 1)

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
}
