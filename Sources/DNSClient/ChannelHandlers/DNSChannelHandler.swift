import DNSCore
import DNSModels
import Logging
import NIOCore

final class DNSChannelHandler: ChannelDuplexHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = Never

    typealias OutboundIn = Message
    typealias OutboundOut = ByteBuffer

    let queryPool: QueryPool
    let decoder: NIOSingleStepByteToMessageProcessor<DNSMessageDecoder>
    let logger: Logger

    init(queryPool: QueryPool, logger: Logger = Logger(label: "DNSChannelHandler")) {
        self.queryPool = queryPool
        self.decoder = NIOSingleStepByteToMessageProcessor(DNSMessageDecoder())
        self.logger = logger
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        do {
            try self.decoder.process(buffer: buffer) { message in
                if !queryPool.succeed(with: message) {
                    logger.warning(
                        "Failed to succeed a message. Ignoring message",
                        metadata: [
                            "id": .stringConvertible(message.header.id)
                        ]
                    )
                    return
                }
            }
        } catch {
            /// Only decode the ID as we likely failed to decode the full message
            guard let id = buffer.readInteger(as: UInt16.self) else {
                logger.warning(
                    "Failed to read ID from buffer. Ignoring message",
                    metadata: [
                        "buffer": .stringConvertible(buffer)
                    ]
                )
                return
            }

            if !queryPool.fail(id: id, with: error) {
                logger.warning(
                    "Failed to fail a message. Ignoring message",
                    metadata: [
                        "id": .stringConvertible(id)
                    ]
                )
                return
            }

            context.fireErrorCaught(error)
        }
    }

    func write(
        context: ChannelHandlerContext,
        data: NIOAny,
        promise: EventLoopPromise<Void>?
    ) {
        let message = unwrapOutboundIn(data)
        var buffer = DNSBuffer(buffer: context.channel.allocator.buffer(capacity: 256))
        assert(
            queryPool.contains(message),
            "QueryPool does not contain an entry for this message? \(message)"
        )
        do {
            try message.encode(into: &buffer)
        } catch {
            if !queryPool.fail(id: message.header.id, with: error) {
                /// How come the message ID was no recognized? Our internal inconsistency?
                assertionFailure("Failed to fail a message with ID: \(message.header.id)")
            }
            promise?.fail(error)
            return
        }
        context.write(NIOAny(ByteBuffer(dnsBuffer: buffer)), promise: promise)
    }
}
