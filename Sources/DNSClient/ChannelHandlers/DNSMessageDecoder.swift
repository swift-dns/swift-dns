import DNSModels
import NIOCore

struct DNSMessageDecoder: NIOSingleStepByteToMessageDecoder {
    typealias InboundOut = Message

    func decode(buffer: inout ByteBuffer) throws -> Message? {
        var dnsBuffer = DNSBuffer(buffer: buffer)
        defer {
            buffer = ByteBuffer(dnsBuffer: dnsBuffer)
        }
        // FIXME: need to handle a case where we need more packets and buffer is incomplete?
        return try Message(from: &dnsBuffer)
    }

    func decodeLast(buffer: inout ByteBuffer, seenEOF: Bool) throws -> Message? {
        try self.decode(buffer: &buffer)
    }
}
