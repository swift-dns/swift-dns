import DNSModels
import NIOCore

final class DNSEncoderChannelHandler: Sendable, ChannelOutboundHandler {
    typealias OutboundIn = Message
    typealias OutboundOut = ByteBuffer

    let queryPool: QueryPool

    init(queryPool: QueryPool) {
        self.queryPool = queryPool
    }

    func write(
        context: ChannelHandlerContext,
        data: NIOAny,
        promise: EventLoopPromise<Void>?
    ) {
        let message = unwrapOutboundIn(data)
        do {
            var buffer = context.channel.allocator.buffer(capacity: 512)
            try message.encode(into: &buffer)
            context.write(wrapOutboundOut(buffer), promise: promise)
        } catch {
            context.fireErrorCaught(error)
        }
    }
}
