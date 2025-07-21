public import DNSModels
public import NIOCore

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
            package var pendingQuery: PendingQuery?

            mutating func takePendingQuery() -> PendingQuery? {
                defer { self.pendingQuery = nil }
                return self.pendingQuery
            }

            package init(context: Context, pendingQuery: PendingQuery?) {
                self.context = context
                self.pendingQuery = pendingQuery
            }
        }

        /// handler has become active
        @usableFromInline
        package mutating func setActive(context: Context) {
            switch consume self.state {
            case .initialized:
                self = .active(ActiveState(context: context, pendingQuery: nil))
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

        /// handler wants to send a query
        @usableFromInline
        package mutating func sendQuery(_ pendingQuery: PendingQuery) -> SendQueryAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot send query when initialized")
            case .active(var state):
                state.pendingQuery = pendingQuery
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
                preconditionFailure("Cannot send query when initialized")
            case .active(var state):
                guard let pendingQuery = state.takePendingQuery() else {
                    self = .closed(nil)
                    return .closeWithError(DNSClientError.unsolicitedResponse)
                }
                self = .active(state)
                return .respond(pendingQuery, DeadlineCallbackAction.cancel)
            case .closing(var state):
                guard let pendingQuery = state.takePendingQuery() else {
                    preconditionFailure("Cannot be in closing state with no pending querys")
                }
                self = .closed(nil)
                return .respondAndClose(pendingQuery, nil)
            case .closed:
                preconditionFailure("Cannot receive query on closed connection")
            }
        }

        @usableFromInline
        package enum HitDeadlineAction {
            case failPendingQueryAndClose(Context, PendingQuery)
            case reschedule(NIODeadline)
            case clearCallback
        }

        @usableFromInline
        package mutating func hitDeadline(now: NIODeadline) -> HitDeadlineAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .active(let state):
                guard let query = state.pendingQuery else {
                    self = .active(state)
                    return .clearCallback
                }
                if query.deadline <= now {
                    self = .closed(DNSClientError.queryTimeout)
                    return .failPendingQueryAndClose(state.context, query)
                } else {
                    self = .active(state)
                    return .reschedule(query.deadline)
                }
            case .closing(let state):
                guard let query = state.pendingQuery else {
                    preconditionFailure("Cannot be in closing state with no pending querys")
                }
                if query.deadline <= now {
                    self = .closed(DNSClientError.queryTimeout)
                    return .failPendingQueryAndClose(state.context, query)
                } else {
                    self = .closing(state)
                    return .reschedule(query.deadline)
                }
            case .closed(let error):
                self = .closed(error)
                return .clearCallback
            }
        }

        @usableFromInline
        package enum CancelAction {
            case cancelPendingQueryAndClose(Context, pendingQuery: PendingQuery)
            case doNothing
        }

        /// handler wants to cancel a query
        @usableFromInline
        package mutating func cancel(requestID: Int) -> CancelAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .active(let state):
                guard let query = state.pendingQuery else {
                    self = .active(state)
                    return .doNothing
                }
                if query.requestID == requestID {
                    self = .closed(CancellationError())
                    return .cancelPendingQueryAndClose(state.context, pendingQuery: query)
                } else {
                    self = .active(state)
                    return .doNothing
                }
            case .closing(let state):
                guard let query = state.pendingQuery else {
                    self = .closing(state)
                    return .doNothing
                }
                if query.requestID == requestID {
                    self = .closed(CancellationError())
                    return .cancelPendingQueryAndClose(state.context, pendingQuery: query)
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
            case waitForPendingQuery(Context)
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
                if state.pendingQuery != nil {
                    self = .closing(state)
                    return .waitForPendingQuery(state.context)
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
            case failPendingQueryAndClose(Context, PendingQuery?)
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
                return .failPendingQueryAndClose(state.context, state.pendingQuery)
            case .closing(let state):
                self = .closed(nil)
                assert(state.pendingQuery != nil)
                return .failPendingQueryAndClose(state.context, state.pendingQuery)
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        @usableFromInline
        package enum SetClosedAction {
            case failPendingQuery(PendingQuery?)
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
                return .failPendingQuery(state.pendingQuery)
            case .closing(let state):
                self = .closed(nil)
                assert(state.pendingQuery != nil)
                return .failPendingQuery(state.pendingQuery)
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
