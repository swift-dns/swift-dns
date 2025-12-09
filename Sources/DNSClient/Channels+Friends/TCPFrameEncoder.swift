public import NIOCore

@usableFromInline
struct TCPFrameEncoder: Sendable, MessageToByteEncoder {
    @usableFromInline
    typealias OutboundIn = ByteBuffer

    @inlinable
    init() {}

    @inlinable
    func encode(data: OutboundIn, out outboundBuffer: inout ByteBuffer) throws {
        try outboundBuffer.writeLengthPrefixed(as: UInt16.self) { outboundBuffer in
            outboundBuffer.writeImmutableBuffer(data)
        }
    }
}
