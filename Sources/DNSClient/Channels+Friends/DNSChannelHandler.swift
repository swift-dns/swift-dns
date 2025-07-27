import DNSCore
public import DNSModels
import DequeModule
import Logging
public import NIOCore

private let channelHandlerIDGenerator = IncrementalIDGenerator()

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
            case .failAndClose(let context, let query, let deadlineCallbackAction):
                query.fail(
                    with: DNSClientError.queryTimeout,
                    removingIDFrom: &channelHandler.messageIDGenerator
                )
                channelHandler.closeConnection(
                    context: context,
                    error: DNSClientError.queryTimeout
                )
                channelHandler.processDeadlineCallbackAction(action: deadlineCallbackAction)
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
    let id: Int
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
        self.messageIDGenerator = MessageIDGenerator()
        self.stateMachine = StateMachine()
        self.isOverUDP = isOverUDP
        self.id = channelHandlerIDGenerator.next()
        var logger = logger
        logger[metadataKey: "dns_channel_handler_id"] = "\(self.id)"
        self.logger = logger
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

        let pendingMessage = PendingQuery(
            promise: .swift(continuation),
            requestID: message.header.id,
            deadline: .now() + TimeAmount(self.configuration.queryTimeout)
        )

        switch self.stateMachine.sendQuery(pendingMessage) {
        case .sendQuery(let context, let deadlineCallbackAction):
            self.processDeadlineCallbackAction(action: deadlineCallbackAction)

            var buffer = DNSBuffer(buffer: context.channel.allocator.buffer(capacity: 512))
            do {
                try message.encode(into: &buffer)
            } catch {
                /// Act as if we received an early response for the query
                switch self.stateMachine.receivedResponse(requestID: message.header.id) {
                case .respond(let pendingMessage, let deadlineAction):
                    self.processDeadlineCallbackAction(action: deadlineAction)
                    pendingMessage.fail(
                        with: error,
                        removingIDFrom: &self.messageIDGenerator
                    )
                case .respondAndClose(let pendingMessage, let deadlineCallbackAction):
                    pendingMessage.fail(
                        with: error,
                        removingIDFrom: &self.messageIDGenerator
                    )
                    /// The error we got is unrelated to connection closure, so we don't pass it
                    self.closeConnection(context: context, error: nil)
                    self.processDeadlineCallbackAction(action: deadlineCallbackAction)
                case .doNothing:
                    break
                }

                return
            }
            context.writeAndFlush(self.wrapOutboundOut(ByteBuffer(dnsBuffer: buffer)), promise: nil)
        case .throwError(let error):
            pendingMessage.fail(
                with: error,
                removingIDFrom: &self.messageIDGenerator
            )
        }
    }

    func handleResponse(context: ChannelHandlerContext, message: Message) {
        switch self.stateMachine.receivedResponse(requestID: message.header.id) {
        case .respond(let pendingMessage, let deadlineAction):
            self.processDeadlineCallbackAction(action: deadlineAction)
            pendingMessage.succeed(
                with: message,
                removingIDFrom: &self.messageIDGenerator
            )
        case .respondAndClose(let pendingMessage, let deadlineCallbackAction):
            pendingMessage.succeed(
                with: message,
                removingIDFrom: &self.messageIDGenerator
            )
            self.closeConnection(context: context, error: nil)
            self.processDeadlineCallbackAction(action: deadlineCallbackAction)
        case .doNothing:
            break
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
        self.forceClose(context: context, error: .handlerRemoved)
    }

    /// This triggered before when the connection-factory is done so virtually a
    /// new channel is always active in the beginning of its lifecycle.
    @usableFromInline
    package func channelActive(context: ChannelHandlerContext) {
        self.stateMachine.setProcessing(context: context)
        self.logger.trace("Channel is active")
    }

    @usableFromInline
    package func channelInactive(context: ChannelHandlerContext) {
        self.logger.trace(
            "Channel has gone inactive. Will finish processing the remaining bytes and close the connection"
        )
        do {
            try self.decoder.finishProcessing(seenEOF: true) { message in
                self.handleResponse(context: context, message: message)
            }
        } catch let error {
            /// Just log the error.
            /// The actual corresponding message will be just time out.
            self.logDecodingError(error, isLastMessage: true)
        }
        self.forceClose(context: context, error: .channelInactive)
    }

    @usableFromInline
    package func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)

        do {
            try self.decoder.process(buffer: buffer) { message in
                self.handleResponse(context: context, message: message)
            }
        } catch let error {
            /// Just log the error.
            /// The actual corresponding message will be just time out.
            self.logDecodingError(error, isLastMessage: false)
        }
    }

    private func logDecodingError(
        _ error: any Error,
        isLastMessage: Bool,
        function: String = #function,
        line: UInt = #line
    ) {
        self.logger.warning(
            "Encountered an error while decoding a DNS Message",
            metadata: [
                "error": "\(String(reflecting: error))",
                "isLastMessage": "\(isLastMessage)",
            ],
            function: function,
            line: line
        )
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
        case .cancelAndClose(let context, let query, let deadlineCallbackAction):
            query.fail(
                with: DNSClientError.cancelled,
                removingIDFrom: &self.messageIDGenerator
            )
            self.closeConnection(
                context: context,
                error: DNSClientError.cancelled
            )
            self.processDeadlineCallbackAction(action: deadlineCallbackAction)
        case .doNothing:
            break
        }
    }

    func forceClose(context: ChannelHandlerContext, error: DNSClientError) {
        self.logger.debug(
            "Force closing the connection",
            metadata: ["error": "\(String(reflecting: error))"]
        )

        switch self.stateMachine.forceClose() {
        case .failPendingQueriesAndClose(let queries, let deadlineCallbackAction):
            for query in queries {
                query.fail(with: error, removingIDFrom: &self.messageIDGenerator)
            }
            self.processDeadlineCallbackAction(action: deadlineCallbackAction)
            /// Otherwise it's already closed
            if error != .channelInactive {
                self.closeConnection(context: context, error: error)
            }
        case .doNothing:
            /// only call fireErrorCaught here as it might be called from `closeConnection`
            context.fireErrorCaught(error)
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
