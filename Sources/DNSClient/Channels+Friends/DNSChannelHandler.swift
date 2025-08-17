import DNSCore
public import DNSModels
import DequeModule
import Logging
public import NIOCore

@available(swiftDNSApplePlatforms 15, *)
private let channelHandlerIDGenerator = IncrementalIDGenerator()

@available(swiftDNSApplePlatforms 15, *)
@usableFromInline
package final class DNSChannelHandler: ChannelDuplexHandler {

    struct DeadlineSchedule: NIOScheduledCallbackHandler {
        let channelHandler: NIOLoopBound<DNSChannelHandler>

        func handleScheduledCallback(eventLoop: some EventLoop) {
            let channelHandler = self.channelHandler.value
            switch channelHandler.stateMachine.hitDeadline(now: .now()) {
            case .failAndReschedule(let query, let deadlineCallbackAction):
                channelHandler.queryProducer.fullfilQuery(
                    pendingQuery: query,
                    with: DNSClientError.queryTimeout
                )
                channelHandler.processDeadlineCallbackAction(action: deadlineCallbackAction)
            case .failAndClose(let context, let query, let deadlineCallbackAction):
                channelHandler.queryProducer.fullfilQuery(
                    pendingQuery: query,
                    with: DNSClientError.queryTimeout
                )
                channelHandler.closeConnectionAndTakeDeadlineAction(
                    context: context,
                    deadlineCallbackAction: deadlineCallbackAction,
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
    var queryProducer: QueryProducer
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
        self.queryProducer = QueryProducer()
        self.stateMachine = StateMachine()
        self.isOverUDP = isOverUDP
        self.id = channelHandlerIDGenerator.next()
        var logger = logger
        logger[metadataKey: "dns_channel_handler_id"] = "\(self.id)"
        self.logger = logger
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension DNSChannelHandler {
    @usableFromInline
    func preflightCheck() throws {
        try self.stateMachine.preflightCheck()
    }

    @usableFromInline
    func write(
        producedMessage: consuming ProducedMessage,
        promise: PendingQuery.DynamicPromise<Message>
    ) {
        self.eventLoop.assertInEventLoop()

        let pendingQuery = producedMessage.producePendingQuery(
            promise: promise,
            deadline: .now() + TimeAmount(self.configuration.queryTimeout)
        )

        switch self.stateMachine.sendQuery(pendingQuery) {
        case .sendQuery(let context, let deadlineCallbackAction):
            self.processDeadlineCallbackAction(action: deadlineCallbackAction)

            context.writeAndFlush(
                self.wrapOutboundOut(ByteBuffer(dnsBuffer: producedMessage.buffer)),
                promise: nil
            )
        case .throwError(let error):
            self.queryProducer.fullfilQuery(
                pendingQuery: pendingQuery,
                with: error
            )
        }
    }

    func handleResponse(
        context: ChannelHandlerContext,
        decodingResult: DNSMessageDecoder.DecodingResult
    ) {
        func fullfilQueryWithDecodingResult(pendingQuery: PendingQuery) {
            switch decodingResult {
            case .message(let message):
                self.queryProducer.fullfilQuery(
                    pendingQuery: pendingQuery,
                    with: message
                )
            case .identifiableError(_, let error):
                self.queryProducer.fullfilQuery(
                    pendingQuery: pendingQuery,
                    with: DNSClientError.decodingError(error)
                )
            }
        }

        switch self.stateMachine.receivedResponse(requestID: decodingResult.messageID) {
        case .respond(let pendingQuery, let deadlineAction):
            self.processDeadlineCallbackAction(action: deadlineAction)
            fullfilQueryWithDecodingResult(pendingQuery: pendingQuery)
        case .respondAndClose(let pendingQuery, let deadlineCallbackAction):
            fullfilQueryWithDecodingResult(pendingQuery: pendingQuery)
            self.closeConnectionAndTakeDeadlineAction(
                context: context,
                deadlineCallbackAction: deadlineCallbackAction,
                error: nil
            )
        case .doNothing:
            break
        }
    }

    func processDeadlineCallbackAction(
        action: StateMachine<ChannelHandlerContext>.DeadlineCallbackAction
    ) {
        switch action {
        case .cancel:
            self.deadlineCallback?.cancel()
            self.deadlineCallback = nil
        case .reschedule(let deadline):
            self.deadlineCallback = try? self.eventLoop.scheduleCallback(
                at: deadline,
                handler: DeadlineSchedule(channelHandler: .init(self, eventLoop: self.eventLoop))
            )
        case .doNothing:
            break
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
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
            try self.decoder.finishProcessing(seenEOF: true) { decodingResult in
                self.handleResponse(
                    context: context,
                    decodingResult: decodingResult
                )
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
            try self.decoder.process(buffer: buffer) { decodingResult in
                self.handleResponse(
                    context: context,
                    decodingResult: decodingResult
                )
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
            self.queryProducer.fullfilQuery(
                pendingQuery: query,
                with: DNSClientError.cancelled
            )
            self.processDeadlineCallbackAction(action: deadlineCallbackAction)
        case .cancelAndClose(let context, let query, let deadlineCallbackAction):
            self.queryProducer.fullfilQuery(
                pendingQuery: query,
                with: DNSClientError.cancelled
            )
            self.closeConnectionAndTakeDeadlineAction(
                context: context,
                deadlineCallbackAction: deadlineCallbackAction,
                error: DNSClientError.cancelled
            )
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
                self.queryProducer.fullfilQuery(
                    pendingQuery: query,
                    with: error
                )
            }
            self.processDeadlineCallbackAction(action: deadlineCallbackAction)
            /// Otherwise it's already closed
            if !error.isChannelInactive {
                self._closeConnection(context: context, error: error)
            }
        case .doNothing:
            /// only call fireErrorCaught here as it might be called from `closeConnection`
            context.fireErrorCaught(error)
        }
    }

    /// State machine itself is in charge of returning the correct deadline callback action of `.cancel`.
    /// The deadline callback action always should be `.cancel` here.
    private func closeConnectionAndTakeDeadlineAction(
        context: ChannelHandlerContext,
        deadlineCallbackAction: StateMachine<ChannelHandlerContext>.DeadlineCallbackAction,
        error: (any Error)? = nil,
    ) {
        self.processDeadlineCallbackAction(action: deadlineCallbackAction)
        self._closeConnection(context: context, error: error)
    }

    /// Prefer to use `closeConnectionAndTakeDeadlineAction`.
    /// The state machines expects the deadline to be cancelled when connection is closed.
    /// State machine itself is in charge of returning the correct deadline callback action of `.cancel`.
    private func _closeConnection(
        context: ChannelHandlerContext,
        error: (any Error)? = nil
    ) {
        if let error {
            context.fireErrorCaught(error)
        }
        context.close(promise: nil)
    }
}
