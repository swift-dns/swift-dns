import DNSModels
import NIOCore

struct DNSMessageDecoder: NIOSingleStepByteToMessageDecoder {
    typealias InboundOut = Message

    func decode(buffer: inout ByteBuffer) throws -> Message? {
        // FIXME: need to handle a case where we need more packets and buffer is incomplete?
        try Message(from: &buffer)
    }

    func decodeLast(buffer: inout ByteBuffer, seenEOF: Bool) throws -> Message? {
        try self.decode(buffer: &buffer)
    }
}
