public import NIOCore

@usableFromInline
final class AddressedEnvelopeInboundChannelHandler: Sendable, ChannelInboundHandler {
    @usableFromInline
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    @usableFromInline
    typealias InboundOut = ByteBuffer

    @inlinable
    init() {}

    @inlinable
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = unwrapInboundIn(data).data
        context.fireChannelRead(wrapInboundOut(buffer))
    }
}
