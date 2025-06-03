import DNSCore
import DNSModels
import NIOCore

final class DNSChannelHandler: ChannelDuplexHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = Never

    typealias OutboundIn = Message
    typealias OutboundOut = ByteBuffer

    let queryPool: QueryPool
    let decoder: NIOSingleStepByteToMessageProcessor<DNSMessageDecoder>

    init(queryPool: QueryPool) {
        self.queryPool = queryPool
        self.decoder = NIOSingleStepByteToMessageProcessor(DNSMessageDecoder())
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = unwrapInboundIn(data)
        do {
            try self.decoder.process(buffer: buffer) { message in
                queryPool.succeed(with: message)
            }
        } catch {
            // FIXME: handle error
            context.fireErrorCaught(error)
        }
    }

    func write(
        context: ChannelHandlerContext,
        data: NIOAny,
        promise: EventLoopPromise<Void>?
    ) {
        let message = unwrapOutboundIn(data)
        var buffer = context.channel.allocator.buffer(capacity: 256)
        assert(
            queryPool.contains(message),
            "QueryPool does not contain an entry for this message? \(message)"
        )
        do {
            try message.encode(into: &buffer)
        } catch {
            queryPool.fail(id: message.header.id, with: error)
            promise?.fail(error)
            return
        }
        context.write(NIOAny(buffer), promise: promise)
    }
}
