import DNSModels
import NIOCore

struct DNSMessageDecoder: NIOSingleStepByteToMessageDecoder {
    typealias InboundOut = Message

    let emptyBuffer = ByteBuffer()

    func decode(buffer: inout ByteBuffer) throws -> Message? {
        var dnsBuffer = DNSBuffer(buffer: buffer)
        /// Avoid CoW when used in dnsBuffer
        buffer = emptyBuffer
        defer {
            /// Need to keep the buffer up to date so `NIOSingleStepByteToMessageDecoder` knows
            buffer = ByteBuffer(dnsBuffer: dnsBuffer)
        }
        return try Message(from: &dnsBuffer)
    }

    func decodeLast(buffer: inout ByteBuffer, seenEOF: Bool) throws -> Message? {
        try self.decode(buffer: &buffer)
    }
}
