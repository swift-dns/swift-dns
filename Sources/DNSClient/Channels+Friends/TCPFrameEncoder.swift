import NIOCore

struct TCPFrameEncoder: MessageToByteEncoder {
    func encode(data: ByteBuffer, out outboundBuffer: inout ByteBuffer) throws {
        try outboundBuffer.writeLengthPrefixed(as: UInt16.self) { outboundBuffer in
            outboundBuffer.writeImmutableBuffer(data)
        }
    }
}
