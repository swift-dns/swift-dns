import DNSClient
import NIOCore
import NIOEmbedded
import Testing

struct DNSResolverTests {
    @available(swiftDNSApplePlatforms 10.15, *)
    @Test func `resolve A record where the original record is a CNAME`() async throws {
        let (connection, channel) = try await Utils.makeTestConnection()
        let responseResource = Resources.dnsResponseAWwwExampleComPacket
        let domainName = try #require(responseResource.domainName)

        async let (_, asyncResponse) = try await connection.send(
            message: MessageFactory<A>.forQuery(domainName: domainName),
            allocator: .init()
        )

        let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        #expect(outbound.readableBytesView.contains(domainName._data.readableBytesView))
        let messageID = try #require(outbound.peekInteger(as: UInt16.self))
        /// The message ID should not be 0 because the channel handler reassigns it
        #expect(messageID != 0)

        let (buffer, message) = Utils.bufferAndMessage(
            from: responseResource,
            changingIDTo: messageID
        )

        try await channel.writeInbound(ByteBuffer(dnsBuffer: buffer))

        let response = try await asyncResponse
        /// FIXME: use equatable instead of string comparison
        #expect("\(response)" == "\(message)")
    }
}
