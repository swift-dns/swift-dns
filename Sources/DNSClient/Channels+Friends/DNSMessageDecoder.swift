import DNSModels
import NIOCore

struct DNSMessageDecoder: NIOSingleStepByteToMessageDecoder {
    typealias InboundOut = Message

    let emptyBuffer = ByteBuffer()

    /// FIXME: after a decoding error, see if we can just return the first 2 bytes of the buffer
    /// as the message ID, so then the channel handler can properly throw an error for the query.
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
        /// Make sure we have at least one byte to read
        /// We might receive and empty buffer when the channel goes inactive
        guard buffer.readableBytes > 0 else {
            return nil
        }

        return try self.decode(buffer: &buffer)
    }
}
