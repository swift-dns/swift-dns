import NIOCore

final class TCPFrameDecoder: ByteToMessageDecoder {
    enum DecodingError: Error {
        case couldNotReadSize(ByteBuffer)
    }

    typealias InboundOut = ByteBuffer

    func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        var readBuffer = buffer
        guard let size: UInt16 = readBuffer.readInteger() else {
            throw DecodingError.couldNotReadSize(readBuffer)
        }

        guard let slice = readBuffer.readSlice(length: Int(size)) else {
            return .needMoreData
        }

        buffer.moveReaderIndex(to: readBuffer.readerIndex)
        context.fireChannelRead(wrapInboundOut(slice))

        return .continue
    }

    func decodeLast(
        context: ChannelHandlerContext,
        buffer: inout ByteBuffer,
        seenEOF: Bool
    ) throws -> DecodingState {
        try decode(context: context, buffer: &buffer)
    }
}
