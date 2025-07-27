import NIOCore

final class AddressedEnvelopeOutboundChannelHandler: Sendable, ChannelOutboundHandler {
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = AddressedEnvelope<ByteBuffer>

    let address: SocketAddress

    init(address: SocketAddress) {
        self.address = address
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let buffer = unwrapOutboundIn(data)
        let envelope = AddressedEnvelope(remoteAddress: address, data: buffer)
        context.write(wrapOutboundOut(envelope), promise: promise)
    }
}
