import DNSModels
import NIOCore
import NIOPosix
import Testing

/// A trait that sends a dns message over udp to 240.1.2.3, with the edns part of
/// the message populated with a message in utf8.
/// This is so we can see the test boundaries in a packet capture.
actor PacketCaptureMarkerTrait: TestScoping, TestTrait {
    var channel: (any Channel)?

    deinit {
        try? channel?.close().wait()
    }

    private init() {}

    static let shared = PacketCaptureMarkerTrait()

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @concurrent @Sendable () async throws -> Void
    ) async throws {
        let testName = test.displayName ?? test.name
        if #available(swiftDNSApplePlatforms 15, *) {
            await self.send(
                subDomain: "test.start",
                info: "\(testName)"
            )
        }
        do {
            try await function()
            if #available(swiftDNSApplePlatforms 15, *) {
                await self.send(
                    subDomain: "test.end.with.success",
                    info: "\(testName)"
                )
            }
        } catch {
            if #available(swiftDNSApplePlatforms 15, *) {
                await self.send(
                    subDomain: "test.end.with.failure",
                    info: "\(testName)"
                )
            }
            throw error
        }
    }

    /// Send a dns message over udp to 240.1.2.3, with the edns part of
    /// the message populated with a message in utf8.
    /// This is so we can see the test boundaries in a packet capture.
    @available(swiftDNSApplePlatforms 15, *)
    func send(subDomain: String, info: String) async {
        do {
            try await self._send(
                subDomain: subDomain,
                info: info
            )
        } catch {
            fatalError(
                """
                Failed to send dns marker packet.
                Error: \(String(reflecting: error))
                """
            )
        }
    }

    /// Send a dns message over udp to 240.1.2.3, with the edns part of
    /// the message populated with a message in utf8.
    /// This is so we can see the test boundaries in a packet capture.
    @available(swiftDNSApplePlatforms 15, *)
    func _send(subDomain: String, info: String) async throws {
        var message = try MessageFactory<A>
            .forQuery(domainName: "\(subDomain).marker.packet.local.")
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
                        .unknown(.max, ByteBuffer(string: info))
                    )
                ]
            )
        )
        var buffer = DNSBuffer()
        try message.encode(into: &buffer)
        let envelope = AddressedEnvelope(
            remoteAddress: try! SocketAddress(
                ipAddress: "240.1.2.3",
                port: 53
            ),
            data: ByteBuffer(dnsBuffer: buffer)
        )

        let channel = try await self.getChannel()
        try await channel.writeAndFlush(envelope)
    }

    func getChannel() async throws -> any Channel {
        if let channel {
            return channel
        }
        let newChannel = try await self.makeChannel()
        self.channel = newChannel
        return newChannel
    }

    func makeChannel() async throws -> any Channel {
        try await DatagramBootstrap(
            group: NIOSingletons.posixEventLoopGroup
        ).bind(
            host: "0.0.0.0",
            port: 53412
        ).get()
    }
}

extension TestTrait where Self == PacketCaptureMarkerTrait {
    static var packetCaptureMarker: Self {
        PacketCaptureMarkerTrait.shared
    }
}
