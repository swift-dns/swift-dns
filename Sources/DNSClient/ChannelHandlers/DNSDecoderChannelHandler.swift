import DNSModels
import NIOCore

final class DNSDecoderChannelHandler: Sendable, ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = Never

    let queryPool: QueryPool

    init(queryPool: QueryPool) {
        self.queryPool = queryPool
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        do {
            let message = try Message(from: &buffer)
            queryPool.succeed(with: message)
        } catch {
            context.fireErrorCaught(error)
        }
    }
}
