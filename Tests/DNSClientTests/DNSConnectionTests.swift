import DNSClient
import DNSModels
import Logging
import NIOEmbedded
import Testing

@Suite
struct DNSConnectionTests {
    // Function required as the #expect macro does not work with non-copyable types
    func expect(_ value: Bool, sourceLocation: SourceLocation = #_sourceLocation) {
        // let channel = NIOAsyncTestingChannel()
        // let logger = Logger(label: "test")
        // let factory = DNSConnectionFactory(configuration: .init(), serverAddress: .domain(name: "127.0.0.1", port: 53))
        // let connection = try await ValkeyConnection.setupChannelAndConnect(
        //     channel,
        //     configuration: .init(),
        //     logger: logger
        // )
        // try await channel.processHello()

        // async let fooResult = connection.get("foo").map { String(buffer: $0) }

        // let outbound = try await channel.waitForOutboundWrite(as: ByteBuffer.self)
        // #expect(outbound == RESPToken(.command(["GET", "foo"])).base)

        // try await channel.writeInbound(RESPToken(.bulkString("Bar")).base)
        // #expect(try await fooResult == "Bar")
    }
}
