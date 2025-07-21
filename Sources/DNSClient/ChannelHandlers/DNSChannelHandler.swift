import DNSCore
public import DNSModels
import Logging
public import NIOCore

@usableFromInline
package final class DNSChannelHandler: ChannelDuplexHandler {

    struct DeadlineSchedule: NIOScheduledCallbackHandler {
        let channelHandler: NIOLoopBound<DNSChannelHandler>

        func handleScheduledCallback(eventLoop: some EventLoop) {
            let channelHandler = self.channelHandler.value
            switch channelHandler.stateMachine.hitDeadline(now: .now()) {
            case .failPendingQueryAndClose(let context, let query):
                query.promise.fail(with: DNSClientError.queryTimeout)
                channelHandler.closeConnection(
                    context: context,
                    error: DNSClientError.queryTimeout
                )
            case .reschedule(let deadline):
                channelHandler.scheduleDeadlineCallback(deadline: deadline)
            case .clearCallback:
                channelHandler.deadlineCallback = nil
            }
        }
    }

    @usableFromInline
    package typealias InboundIn = ByteBuffer
    @usableFromInline
    package typealias InboundOut = Never

    @usableFromInline
    package typealias OutboundIn = Message
    @usableFromInline
    package typealias OutboundOut = ByteBuffer

    @usableFromInline
    let eventLoop: any EventLoop
    @usableFromInline
    let configuration: DNSConnectionConfiguration
    let decoder: NIOSingleStepByteToMessageProcessor<DNSMessageDecoder>
    @usableFromInline
    private(set) var deadlineCallback: NIOScheduledCallback?
    var stateMachine: StateMachine<ChannelHandlerContext>
    let isOverUDP: Bool
    let logger: Logger

    init(
        eventLoop: any EventLoop,
        configuration: DNSConnectionConfiguration,
        isOverUDP: Bool,
        logger: Logger = Logger(label: "DNSChannelHandler")
    ) {
        self.eventLoop = eventLoop
        self.configuration = configuration
        self.decoder = NIOSingleStepByteToMessageProcessor(DNSMessageDecoder())
        self.isOverUDP = isOverUDP
        self.logger = logger
        self.stateMachine = StateMachine()
    }
}

extension DNSChannelHandler {
    @usableFromInline
    func write(
        message: Message,
        continuation: CheckedContinuation<Message, any Error>,
        requestID: Int
    ) {
        self.eventLoop.assertInEventLoop()

        let deadline: NIODeadline = .now() + TimeAmount(self.configuration.queryTimeout)
        let pendingMessage = PendingQuery(
            promise: DynamicPromise.swift(continuation),
            requestID: requestID,
            deadline: .now() + TimeAmount(self.configuration.queryTimeout)
        )

        switch self.stateMachine.sendQuery(pendingMessage) {
        case .sendQuery(let context):
            var buffer = DNSBuffer(buffer: context.channel.allocator.buffer(capacity: 256))
            do {
                try message.encode(into: &buffer)
            } catch {
                continuation.resume(throwing: error)
                return
            }
            /// FIXME: do we need to handle channel-already-closed being thrown from the promise below?
            context.writeAndFlush(self.wrapOutboundOut(ByteBuffer(dnsBuffer: buffer)), promise: nil)

            if self.deadlineCallback == nil {
                self.scheduleDeadlineCallback(deadline: deadline)
            }
        case .throwError(let error):
            continuation.resume(throwing: error)
        }
    }

    func handleResponse(context: ChannelHandlerContext, message: Message) {
        switch self.stateMachine.receivedResponse(message: message) {
        case .respond(let pendingMessage, let deadlineAction):
            self.processDeadlineCallbackAction(action: deadlineAction)
            pendingMessage.promise.succeed(message)
        case .respondAndClose(let pendingMessage, let error):
            pendingMessage.promise.succeed(message)
            self.closeConnection(context: context, error: error)
        case .closeWithError(let error):
            self.closeConnection(context: context, error: error)
        }
    }

    func handleError(context: ChannelHandlerContext, error: any Error) {
        self.logger.debug(
            "DNSChannelHandler error",
            metadata: ["error": "\(String(reflecting: error))"]
        )
        switch self.stateMachine.close() {
        case .failPendingQueryAndClose(let context, let query):
            query?.promise.fail(with: error)
            self.closeConnection(context: context, error: error)
        case .doNothing:
            // only call fireErrorCaught here as it is called from `closeConnection`
            context.fireErrorCaught(error)
        }
    }

    @usableFromInline
    func scheduleDeadlineCallback(deadline: NIODeadline) {
        self.deadlineCallback = try? self.eventLoop.scheduleCallback(
            at: deadline,
            handler: DeadlineSchedule(channelHandler: .init(self, eventLoop: self.eventLoop))
        )
    }

    func processDeadlineCallbackAction(
        action: StateMachine<ChannelHandlerContext>.DeadlineCallbackAction
    ) {
        switch action {
        case .cancel:
            self.deadlineCallback?.cancel()
            self.deadlineCallback = nil
        case .doNothing:
            break
        }
    }
}

extension DNSChannelHandler {
    @usableFromInline
    package func handlerRemoved(context: ChannelHandlerContext) {
        self.setClosed()
    }

    @usableFromInline
    package func channelActive(context: ChannelHandlerContext) {
        self.stateMachine.setActive(context: context)
        self.logger.trace("Channel active.")
    }

    @usableFromInline
    package func channelInactive(context: ChannelHandlerContext) {
        do {
            try self.decoder.finishProcessing(seenEOF: true) { message in
                self.handleResponse(context: context, message: message)
            }
        } catch let error {
            self.handleError(context: context, error: error)
        }
        self.setClosed()

        self.logger.trace("Channel inactive.")
    }

    @usableFromInline
    package func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)

        do {
            try self.decoder.process(buffer: buffer) { message in
                self.handleResponse(context: context, message: message)
            }
        } catch let error {
            self.handleError(context: context, error: error)
        }
    }

    @usableFromInline
    func cancel(requestID: Int) {
        self.eventLoop.assertInEventLoop()
        switch self.stateMachine.cancel(requestID: requestID) {
        case .cancelPendingQueryAndClose(let context, let pendingQuery):
            pendingQuery.promise.fail(with: DNSClientError.cancelled)
            self.closeConnection(
                context: context,
                error: DNSClientError.cancelled
            )
        case .doNothing:
            break
        }
    }

    private func setClosed() {
        switch self.stateMachine.setClosed() {
        case .failPendingQuery(let query):
            query?.promise.fail(with: DNSClientError.connectionClosed)
            self.deadlineCallback?.cancel()
        case .doNothing:
            break
        }
    }

    private func closeConnection(
        context: ChannelHandlerContext,
        error: (any Error)? = nil
    ) {
        if let error {
            context.fireErrorCaught(error)
        }
        context.close(promise: nil)
    }
}
