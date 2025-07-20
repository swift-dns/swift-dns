import DNSCore
public import DNSModels
import DequeModule
import Logging
public import NIOCore

@usableFromInline
final class DNSChannelHandler: ChannelDuplexHandler {

    struct DeadlineSchedule: NIOScheduledCallbackHandler {
        let channelHandler: NIOLoopBound<DNSChannelHandler>

        func handleScheduledCallback(eventLoop: some EventLoop) {
            let channelHandler = self.channelHandler.value
            switch channelHandler.state.hitDeadline(now: .now()) {
            case .failPendingQueriesAndClose(let context, let queries):
                for query in queries {
                    query.promise.fail(with: DNSClientError.queryTimeout)
                }
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
    typealias InboundIn = ByteBuffer
    @usableFromInline
    typealias InboundOut = Never

    @usableFromInline
    typealias OutboundIn = Message
    @usableFromInline
    typealias OutboundOut = ByteBuffer

    @usableFromInline
    let eventLoop: any EventLoop
    @usableFromInline
    let configuration: DNSConnectionConfiguration
    let decoder: NIOSingleStepByteToMessageProcessor<DNSMessageDecoder>
    @usableFromInline
    private(set) var deadlineCallback: NIOScheduledCallback?
    var state: StateMachine<ChannelHandlerContext>
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
        self.state = StateMachine()
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
        let pendingMessage = PendingMessage(
            promise: DynamicPromise.swift(continuation),
            requestID: requestID,
            deadline: .now() + TimeAmount(self.configuration.queryTimeout)
        )

        switch self.state.sendQuery(pendingMessage) {
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
        switch self.state.receivedResponse(message: message) {
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
        switch self.state.close() {
        case .failPendingQueriesAndClose(let context, let queries):
            for query in queries {
                query.promise.fail(with: error)
            }
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
        case .reschedule(let deadline):
            self.scheduleDeadlineCallback(deadline: deadline)
        case .doNothing:
            break
        }
    }
}

extension DNSChannelHandler {
    @usableFromInline
    func handlerRemoved(context: ChannelHandlerContext) {
        self.setClosed()
    }

    @usableFromInline
    func channelActive(context: ChannelHandlerContext) {
        self.state.setActive(context: context)
        self.logger.trace("Channel active.")
    }

    @usableFromInline
    func channelInactive(context: ChannelHandlerContext) {
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
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
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
        switch self.state.cancel(requestID: requestID) {
        case .failPendingQueriesAndClose(
            let context,
            let cancelled,
            let closeConnectionDueToCancel
        ):
            for query in cancelled {
                query.promise.fail(with: DNSClientError.cancelled)
            }
            for query in closeConnectionDueToCancel {
                query.promise.fail(with: DNSClientError.connectionClosedDueToCancellation)
            }
            self.closeConnection(
                context: context,
                error: DNSClientError.cancelled
            )

        case .doNothing:
            break
        }
    }

    private func setClosed() {
        switch self.state.setClosed() {
        case .failPendingQueries(let queries):
            for query in queries {
                query.promise.fail(with: DNSClientError.connectionClosed)
            }
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
