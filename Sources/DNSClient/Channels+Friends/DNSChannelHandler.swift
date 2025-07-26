import DNSCore
public import DNSModels
import DequeModule
import Logging
public import NIOCore

@usableFromInline
package final class DNSChannelHandler: ChannelDuplexHandler {

    struct DeadlineSchedule: NIOScheduledCallbackHandler {
        let channelHandler: NIOLoopBound<DNSChannelHandler>

        func handleScheduledCallback(eventLoop: some EventLoop) {
            let channelHandler = self.channelHandler.value
            switch channelHandler.stateMachine.hitDeadline(now: .now()) {
            case .failAndReschedule(let query, let deadlineCallbackAction):
                query.fail(
                    with: DNSClientError.queryTimeout,
                    removingIDFrom: &channelHandler.messageIDGenerator
                )
                channelHandler.processDeadlineCallbackAction(action: deadlineCallbackAction)
            case .failAndClose(let context, let query):
                query.fail(
                    with: DNSClientError.queryTimeout,
                    removingIDFrom: &channelHandler.messageIDGenerator
                )
                channelHandler.closeConnection(
                    context: context,
                    error: DNSClientError.queryTimeout
                )
            case .deadlineCallbackAction(let deadlineCallbackAction):
                channelHandler.processDeadlineCallbackAction(action: deadlineCallbackAction)
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
    @usableFromInline
    var messageIDGenerator: MessageIDGenerator
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
        self.messageIDGenerator = MessageIDGenerator()
        self.stateMachine = StateMachine()
    }
}

extension DNSChannelHandler {
    @usableFromInline
    func produceMessage(
        message factory: consuming MessageFactory<some RDataConvertible>,
        options: DNSRequestOptions
    ) throws(MessageIDGenerator.Errors) -> Message {
        let requestID = try self.messageIDGenerator.next()
        factory.apply(options: options)
        factory.apply(requestID: requestID)
        return factory.takeMessage()
    }

    @usableFromInline
    func write(
        message: Message,
        continuation: CheckedContinuation<Message, any Error>
    ) {
        self.eventLoop.assertInEventLoop()

        let deadline: NIODeadline = .now() + TimeAmount(self.configuration.queryTimeout)
        let pendingMessage = PendingQuery(
            promise: DynamicPromise.swift(continuation),
            requestID: message.header.id,
            deadline: .now() + TimeAmount(self.configuration.queryTimeout)
        )

        switch self.stateMachine.sendQuery(pendingMessage) {
        case .sendQuery(let context):
            var buffer = DNSBuffer(buffer: context.channel.allocator.buffer(capacity: 512))
            do {
                try message.encode(into: &buffer)
            } catch {
                continuation.resume(throwing: error)
                return
            }
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
            pendingMessage.succeed(
                with: message,
                removingIDFrom: &self.messageIDGenerator
            )
        case .respondAndClose(let pendingMessage):
            pendingMessage.succeed(
                with: message,
                removingIDFrom: &self.messageIDGenerator
            )
            self.closeConnection(context: context, error: nil)
        case .doNothing:
            break
        }
    }

    /// FIXME: don't close
    func handleError(context: ChannelHandlerContext, error: any Error) {
        self.logger.debug(
            "DNSChannelHandler error",
            metadata: ["error": "\(String(reflecting: error))"]
        )
        switch self.stateMachine.close() {
        case .failPendingQueriesAndClose(let context, let queries):
            for query in queries {
                query.fail(
                    with: error,
                    removingIDFrom: &self.messageIDGenerator
                )
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
    package func handlerRemoved(context: ChannelHandlerContext) {
        self.setClosed()
    }

    /// This triggered before when the connection-factory is done so virtually a
    /// new channel is always active in the beginning of its lifecycle.
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
    func cancel(requestID: UInt16) {
        self.eventLoop.assertInEventLoop()

        switch self.stateMachine.cancel(requestID: requestID) {
        case .cancel(let query, let deadlineCallbackAction):
            query.fail(
                with: DNSClientError.cancelled,
                removingIDFrom: &self.messageIDGenerator
            )
            self.processDeadlineCallbackAction(action: deadlineCallbackAction)
        case .cancelAndClose(let context, let query):
            query.fail(
                with: DNSClientError.cancelled,
                removingIDFrom: &self.messageIDGenerator
            )
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
        case .failPendingQueries(let queries):
            for query in queries {
                query.fail(
                    with: DNSClientError.connectionClosed,
                    removingIDFrom: &self.messageIDGenerator
                )
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
