import DNSModels
import NIOCore
import NIOPosix
import Testing

/// A trait that sends a dns message over udp to 240.1.2.3, with the edns part of
/// the message populated with a message in utf8.
/// This is so we can see the test boundaries in a packet capture.
struct PacketCaptureMarkerTrait: TestScoping, TestTrait {
    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        let testName = test.displayName ?? test.name
        let word = test.isSuite ? "suite" : "test"
        if #available(swiftDNSApplePlatforms 15, *) {
            try await self.send(string: "Will run \(word) '\(testName)'")
        }
        try await function()
        if #available(swiftDNSApplePlatforms 15, *) {
            try await self.send(string: "Finished running \(word) '\(testName)'")
        }
    }

    /// Send a dns message over udp to 240.1.2.3, with the edns part of
    /// the message populated with a message in utf8.
    /// This is so we can see the test boundaries in a packet capture.
    @available(swiftDNSApplePlatforms 15, *)
    func send(string: String) async throws {
        var message = try MessageFactory<A>
            .forQuery(domainName: "running.test.marker.packet.local.")
            .__testing_copyMessage()
        message.header.id = .max
        message.edns = EDNS(
            rcodeHigh: 0,
            version: 0,
            flags: .init(dnssecOk: false, z: 0),
            maxPayload: 4096,
            options: OPT(
                options: [
                    (
                        .unknown(.max),
                        .unknown(.max, ByteBuffer(string: string))
                    )
                ]
            )
        )
        var buffer = DNSBuffer()
        try message.encode(into: &buffer)

        try await DatagramBootstrap(
            group: NIOSingletons.posixEventLoopGroup
        ).bind(
            host: "0.0.0.0",
            port: 53412
        ).flatMapThrowing { channel in
            try NIOAsyncChannel(
                wrappingChannelSynchronously: channel,
                configuration: NIOAsyncChannel.Configuration(
                    inboundType: AddressedEnvelope<ByteBuffer>.self,
                    outboundType: AddressedEnvelope<ByteBuffer>.self
                )
            )
        }.get().executeThenClose { inbound, outbound in
            try await outbound.write(
                AddressedEnvelope(
                    remoteAddress: try SocketAddress(
                        ipAddress: "240.1.2.3",
                        port: 53
                    ),
                    data: ByteBuffer(dnsBuffer: buffer)
                )
            )
        }
    }
}

extension TestTrait where Self == PacketCaptureMarkerTrait {
    static var packetCaptureMarker: Self {
        PacketCaptureMarkerTrait()
    }
}
