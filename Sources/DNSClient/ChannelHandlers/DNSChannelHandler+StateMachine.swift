public import DNSModels
public import NIOCore

public import struct DequeModule.Deque

@available(swiftDNS 1.0, *)
extension DNSChannelHandler {
    @usableFromInline
    struct StateMachine<Context>: ~Copyable {

        @usableFromInline
        enum State: ~Copyable {
            case initialized
            case active(ActiveState)
            case closing(ActiveState)
            case closed((any Error)?)

            @usableFromInline
            var description: String {
                borrowing get {
                    switch self {
                    case .initialized: "initialized"
                    case .active: "active"
                    case .closing: "closing"
                    case .closed: "closed"
                    }
                }
            }
        }

        @usableFromInline
        var state: State

        init() {
            self.state = .initialized
        }

        private init(_ state: consuming State) {
            self.state = state
        }

        @usableFromInline
        struct ActiveState {
            let context: Context
            var pendingQueries: Deque<PendingMessage>

            func cancel(
                requestID: Int
            ) -> (cancel: [PendingMessage], connectionClosedDueToCancellation: [PendingMessage]) {
                var withRequestID = [PendingMessage]()
                var withoutRequestID = [PendingMessage]()
                for message in pendingQueries {
                    if message.requestID == requestID {
                        withRequestID.append(message)
                    } else {
                        withoutRequestID.append(message)
                    }
                }
                return (withRequestID, withoutRequestID)
            }
        }

        /// handler has become active
        @usableFromInline
        mutating func setActive(context: Context) {
            switch consume self.state {
            case .initialized:
                self = .active(ActiveState(context: context, pendingQueries: []))
            case .active:
                preconditionFailure("Cannot set connected state when state is active")
            case .closing:
                preconditionFailure("Cannot set connected state when state is closing")
            case .closed:
                preconditionFailure("Cannot set connected state when state is closed")
            }
        }

        @usableFromInline
        enum SendQueryAction {
            case sendQuery(Context)
            case throwError(any Error)
        }

        /// handler wants to send a message
        @usableFromInline
        mutating func sendQuery(_ pendingQuery: PendingMessage) -> SendQueryAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot send message when initialized")
            case .active(var state):
                state.pendingQueries.append(pendingQuery)
                self = .active(state)
                return .sendQuery(state.context)
            case .closing(let state):
                self = .closing(state)
                return .throwError(DNSClientError.connectionClosing)
            case .closed(let error):
                self = .closed(error)
                return .throwError(DNSClientError.connectionClosed)
            }
        }

        @usableFromInline
        enum DeadlineCallbackAction {
            case cancel
            case reschedule(NIODeadline)
            case doNothing
        }

        @usableFromInline
        enum ReceivedResponseAction {
            case respond(PendingMessage, DeadlineCallbackAction)
            case respondAndClose(PendingMessage, (any Error)?)
            case closeWithError(any Error)
        }

        /// handler wants to send a message
        @usableFromInline
        mutating func receivedResponse(message: Message) -> ReceivedResponseAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot send message when initialized")
            case .active(var state):
                guard let pendingMessage = state.pendingQueries.popFirst() else {
                    self = .closed(nil)
                    return .closeWithError(
                        DNSClientError.unsolicitedResponse
                    )
                }
                self = .active(state)
                let deadlineCallback: DeadlineCallbackAction =
                    if let nextMessage = state.pendingQueries.first {
                        if nextMessage.deadline < pendingMessage.deadline {
                            // if the next message has an earlier deadline than the current then reschedule the callback
                            .reschedule(nextMessage.deadline)
                        } else {
                            // otherwise do nothing
                            .doNothing
                        }
                    } else {
                        // if there are no more messages cancel the callback
                        .cancel
                    }
                return .respond(pendingMessage, deadlineCallback)
            case .closing(var state):
                guard let pendingMessage = state.pendingQueries.popFirst() else {
                    preconditionFailure("Cannot be in closing state with no pending messages")
                }
                guard let nextMessage = state.pendingQueries.first else {
                    self = .closed(nil)
                    return .respondAndClose(pendingMessage, nil)
                }
                self = .closing(state)
                let deadlineCallback: DeadlineCallbackAction =
                    if nextMessage.deadline < pendingMessage.deadline {
                        // if the next message has an earlier deadline than the current then reschedule the callback
                        .reschedule(nextMessage.deadline)
                    } else {
                        // otherwise do nothing
                        .doNothing
                    }
                return .respond(pendingMessage, deadlineCallback)
            case .closed:
                preconditionFailure("Cannot receive message on closed connection")
            }
        }

        @usableFromInline
        enum HitDeadlineAction {
            case failPendingQueriesAndClose(Context, Deque<PendingMessage>)
            case reschedule(NIODeadline)
            case clearCallback
        }

        @usableFromInline
        mutating func hitDeadline(now: NIODeadline) -> HitDeadlineAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .active(let state):
                guard let firstMessage = state.pendingQueries.first else {
                    self = .active(state)
                    return .clearCallback
                }
                if firstMessage.deadline <= now {
                    self = .closed(DNSClientError.queryTimeout)
                    return .failPendingQueriesAndClose(state.context, state.pendingQueries)
                } else {
                    self = .active(state)
                    return .reschedule(firstMessage.deadline)
                }
            case .closing(let state):
                guard let firstMessage = state.pendingQueries.first else {
                    preconditionFailure("Cannot be in closing state with no pending messages")
                }
                if firstMessage.deadline <= now {
                    self = .closed(DNSClientError.queryTimeout)
                    return .failPendingQueriesAndClose(state.context, state.pendingQueries)
                } else {
                    self = .closing(state)
                    return .reschedule(firstMessage.deadline)
                }
            case .closed(let error):
                self = .closed(error)
                return .clearCallback
            }
        }

        @usableFromInline
        enum CancelAction {
            case failPendingQueriesAndClose(
                Context,
                cancel: [PendingMessage],
                closeConnectionDueToCancel: [PendingMessage]
            )
            case doNothing
        }

        /// handler wants to cancel a message
        @usableFromInline
        mutating func cancel(requestID: Int) -> CancelAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .active(let state):
                let (cancel, closeConnectionDueToCancel) = state.cancel(requestID: requestID)
                if cancel.count > 0 {
                    self = .closed(CancellationError())
                    return .failPendingQueriesAndClose(
                        state.context,
                        cancel: cancel,
                        closeConnectionDueToCancel: closeConnectionDueToCancel
                    )
                } else {
                    self = .active(state)
                    return .doNothing
                }
            case .closing(let state):
                let (cancel, closeConnectionDueToCancel) = state.cancel(requestID: requestID)
                if cancel.count > 0 {
                    self = .closed(CancellationError())
                    return .failPendingQueriesAndClose(
                        state.context,
                        cancel: cancel,
                        closeConnectionDueToCancel: closeConnectionDueToCancel
                    )
                } else {
                    self = .closing(state)
                    return .doNothing
                }
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        @usableFromInline
        enum GracefulShutdownAction {
            case waitForPendingQueries(Context)
            case closeConnection(Context)
            case doNothing
        }

        /// Want to gracefully shutdown the handler
        @usableFromInline
        mutating func gracefulShutdown() -> GracefulShutdownAction {
            switch consume self.state {
            case .initialized:
                self = .closed(nil)
                return .doNothing
            case .active(let state):
                if state.pendingQueries.count > 0 {
                    self = .closing(state)
                    return .waitForPendingQueries(state.context)
                } else {
                    self = .closed(nil)
                    return .closeConnection(state.context)
                }
            case .closing(let state):
                self = .closing(state)
                return .doNothing
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        @usableFromInline
        enum CloseAction {
            case failPendingQueriesAndClose(Context, Deque<PendingMessage>)
            case doNothing
        }

        /// Want to close the connection
        @usableFromInline
        mutating func close() -> CloseAction {
            switch consume self.state {
            case .initialized:
                self = .closed(nil)
                return .doNothing
            case .active(let state):
                self = .closed(nil)
                return .failPendingQueriesAndClose(state.context, state.pendingQueries)
            case .closing(let state):
                self = .closed(nil)
                return .failPendingQueriesAndClose(state.context, state.pendingQueries)
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        @usableFromInline
        enum SetClosedAction {
            case failPendingQueries(Deque<PendingMessage>)
            case doNothing
        }

        /// The connection has been closed
        @usableFromInline
        mutating func setClosed() -> SetClosedAction {
            switch consume self.state {
            case .initialized:
                self = .closed(nil)
                return .doNothing
            case .active(let state):
                self = .closed(nil)
                return .failPendingQueries(state.pendingQueries)
            case .closing(let state):
                self = .closed(nil)
                return .failPendingQueries(state.pendingQueries)
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        private static var initialized: Self {
            StateMachine(.initialized)
        }

        private static func active(_ state: ActiveState) -> Self {
            StateMachine(.active(state))
        }

        private static func closing(_ state: ActiveState) -> Self {
            StateMachine(.closing(state))
        }

        private static func closed(_ error: (any Error)?) -> Self {
            StateMachine(.closed(error))
        }
    }
}
