import DNSClient
import NIOCore
import NIOEmbedded

extension NIOAsyncTestingChannel {
    func waitForOutboundMessage() async throws -> Message {
        let outbound = try await self.waitForOutboundWrite(as: ByteBuffer.self)
        var buffer = DNSBuffer(buffer: outbound)
        let message = try Message(from: &buffer)
        return message
    }

    func writeInboundMessage(_ message: Message) async throws {
        var buffer = DNSBuffer()
        try message.encode(into: &buffer)
        try await self.writeInbound(ByteBuffer(dnsBuffer: buffer))
    }
}
