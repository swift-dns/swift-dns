public import DNSModels
public import NIOCore

package import struct OrderedCollections.OrderedDictionary

@available(swiftDNS 1.0, *)
extension DNSChannelHandler {
    @usableFromInline
    package struct StateMachine<Context>: ~Copyable {

        @usableFromInline
        package enum State: ~Copyable {
            case initialized
            case active(ActiveState)
            case closing(ActiveState)
            case closed((any Error)?)

            @usableFromInline
            package var description: String {
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
        package var state: State

        package init() {
            self.state = .initialized
        }

        private init(_ state: consuming State) {
            self.state = state
        }

        @usableFromInline
        package struct ActiveState {
            package let context: Context
            package var pendingQueries: OrderedDictionary<UInt16, PendingQuery>

            var firstPendingQuery: PendingQuery? {
                self.pendingQueries.values.first
            }

            package init(context: Context, firstQuery pendingQuery: PendingQuery) {
                self.context = context
                self.pendingQueries = [pendingQuery.requestID: pendingQuery]
            }

            package init(context: Context) {
                self.context = context
                self.pendingQueries = [:]
            }

            mutating func append(_ pendingQuery: PendingQuery) {
                self.pendingQueries[pendingQuery.requestID] = pendingQuery
            }

            mutating func removeValue(requestID: UInt16) -> PendingQuery? {
                self.pendingQueries.removeValue(forKey: requestID)
            }

            func cancel(
                requestID: UInt16
            ) -> (cancel: PendingQuery?, connectionClosedDueToCancellation: [PendingQuery]) {
                let withRequestID = self.pendingQueries[requestID]
                let withoutRequestID = self.pendingQueries
                    .filter({ $0.key != requestID })
                    .map(\.value)
                return (withRequestID, withoutRequestID)
            }
        }

        /// handler has become active
        @usableFromInline
        package mutating func setActive(context: Context) {
            switch consume self.state {
            case .initialized:
                self = .active(ActiveState(context: context))
            case .active:
                preconditionFailure("Cannot set connected state when state is active")
            case .closing:
                preconditionFailure("Cannot set connected state when state is closing")
            case .closed:
                preconditionFailure("Cannot set connected state when state is closed")
            }
        }

        @usableFromInline
        package enum SendQueryAction {
            case sendQuery(Context)
            case throwError(any Error)
        }

        /// handler wants to send a message
        @usableFromInline
        package mutating func sendQuery(_ pendingQuery: PendingQuery) -> SendQueryAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot send message when initialized")
            case .active(var state):
                state.append(pendingQuery)
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
        package enum DeadlineCallbackAction {
            case cancel
            case reschedule(NIODeadline)
            case doNothing
        }

        @usableFromInline
        package enum ReceivedResponseAction {
            case respond(PendingQuery, DeadlineCallbackAction)
            case respondAndClose(PendingQuery, (any Error)?)
            case closeWithError(any Error)
        }

        /// handler wants to send a message
        @usableFromInline
        package mutating func receivedResponse(message: Message) -> ReceivedResponseAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot send message when initialized")
            case .active(var state):
                guard let pendingMessage = state.removeValue(requestID: message.header.id) else {
                    self = .closed(nil)
                    return .closeWithError(
                        DNSClientError.unsolicitedResponse
                    )
                }
                self = .active(state)
                let deadlineCallback: DeadlineCallbackAction =
                    if let nextMessage = state.firstPendingQuery {
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
                guard let pendingMessage = state.removeValue(requestID: message.header.id) else {
                    preconditionFailure("Cannot be in closing state with no pending messages")
                }
                guard let nextMessage = state.firstPendingQuery else {
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
        package enum HitDeadlineAction {
            case failPendingQueriesAndClose(Context, [PendingQuery])
            case reschedule(NIODeadline)
            case clearCallback
        }

        @usableFromInline
        package mutating func hitDeadline(now: NIODeadline) -> HitDeadlineAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .active(let state):
                guard let firstMessage = state.firstPendingQuery else {
                    self = .active(state)
                    return .clearCallback
                }
                if firstMessage.deadline <= now {
                    self = .closed(DNSClientError.queryTimeout)
                    return .failPendingQueriesAndClose(
                        state.context,
                        Array(state.pendingQueries.values)
                    )
                } else {
                    self = .active(state)
                    return .reschedule(firstMessage.deadline)
                }
            case .closing(let state):
                guard let firstMessage = state.firstPendingQuery else {
                    preconditionFailure("Cannot be in closing state with no pending messages")
                }
                if firstMessage.deadline <= now {
                    self = .closed(DNSClientError.queryTimeout)
                    return .failPendingQueriesAndClose(
                        state.context,
                        Array(state.pendingQueries.values)
                    )
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
        package enum CancelAction {
            case failPendingQueriesAndClose(
                Context,
                cancel: PendingQuery,
                closeConnectionDueToCancel: [PendingQuery]
            )
            case doNothing
        }

        /// handler wants to cancel a message
        @usableFromInline
        package mutating func cancel(requestID: UInt16) -> CancelAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .active(let state):
                let (cancel, closeConnectionDueToCancel) = state.cancel(requestID: requestID)
                if let cancel {
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
                if let cancel {
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
        package enum GracefulShutdownAction {
            case waitForPendingQueries(Context)
            case closeConnection(Context)
            case doNothing
        }

        /// Want to gracefully shutdown the handler
        @usableFromInline
        package mutating func gracefulShutdown() -> GracefulShutdownAction {
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
        package enum CloseAction {
            case failPendingQueriesAndClose(Context, [PendingQuery])
            case doNothing
        }

        /// Want to close the connection
        @usableFromInline
        package mutating func close() -> CloseAction {
            switch consume self.state {
            case .initialized:
                self = .closed(nil)
                return .doNothing
            case .active(let state):
                self = .closed(nil)
                return .failPendingQueriesAndClose(
                    state.context,
                    Array(state.pendingQueries.values)
                )
            case .closing(let state):
                self = .closed(nil)
                return .failPendingQueriesAndClose(
                    state.context,
                    Array(state.pendingQueries.values)
                )
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        @usableFromInline
        package enum SetClosedAction {
            case failPendingQueries([PendingQuery])
            case doNothing
        }

        /// The connection has been closed
        @usableFromInline
        package mutating func setClosed() -> SetClosedAction {
            switch consume self.state {
            case .initialized:
                self = .closed(nil)
                return .doNothing
            case .active(let state):
                self = .closed(nil)
                return .failPendingQueries(Array(state.pendingQueries.values))
            case .closing(let state):
                self = .closed(nil)
                return .failPendingQueries(Array(state.pendingQueries.values))
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
