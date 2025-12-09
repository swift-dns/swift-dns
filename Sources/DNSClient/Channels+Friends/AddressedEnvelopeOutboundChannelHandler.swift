public import NIOCore

@usableFromInline
final class AddressedEnvelopeOutboundChannelHandler: Sendable, ChannelOutboundHandler {
    @usableFromInline
    typealias OutboundIn = ByteBuffer
    @usableFromInline
    typealias OutboundOut = AddressedEnvelope<ByteBuffer>

    @usableFromInline
    let address: SocketAddress

    @inlinable
    init(address: SocketAddress) {
        self.address = address
    }

    @inlinable
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let buffer = unwrapOutboundIn(data)
        let envelope = AddressedEnvelope(remoteAddress: address, data: buffer)
        context.write(wrapOutboundOut(envelope), promise: promise)
    }
}
