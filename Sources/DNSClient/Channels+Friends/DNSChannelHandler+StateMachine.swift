public import NIOCore

import struct OrderedCollections.OrderedDictionary

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

        /// `_pendingQueriesLookupTable` is sorted by the order of the pending queries.
        /// The order is used to determine the next query which will reach its deadline first.
        /// To not break this assumption, all `deadline`s of `PendingQuery`s must be the same.
        /// Today this is the case. The `deadline` originates from the `DNSClientConfiguration`.
        /// That means it's always the same number.
        /// However if one day we want to allow users to use multiple queryTimeouts, e.g. at function
        /// call sites, then we'll have to reevaluate this logic in `ActiveState`.
        @usableFromInline
        package struct ActiveState: ~Copyable {
            package let context: Context
            /// [PendingQuery.requestID: PendingQuery] where PendingQuery.requestID == message.header.id
            var _pendingQueriesLookupTable: OrderedDictionary<UInt16, PendingQuery>

            package init(context: Context, firstQuery pendingQuery: PendingQuery) {
                self.context = context
                self._pendingQueriesLookupTable = [pendingQuery.requestID: pendingQuery]
            }

            package init(__testing_context context: Context, pendingQueries: [PendingQuery]) {
                self.context = context
                self._pendingQueriesLookupTable = OrderedDictionary(
                    uniqueKeysWithValues: pendingQueries.map { ($0.requestID, $0) }
                )
            }

            package init(context: Context) {
                self.context = context
                self._pendingQueriesLookupTable = [:]
            }

            var isEmpty: Bool {
                self._pendingQueriesLookupTable.isEmpty
            }

            consuming func discard() -> (Context, [PendingQuery]) {
                (self.context, Array(self._pendingQueriesLookupTable.values))
            }

            package var firstPendingQuery: PendingQuery? {
                self._pendingQueriesLookupTable.values.first
            }

            mutating func append(_ pendingQuery: PendingQuery) {
                let original = self._pendingQueriesLookupTable.updateValue(
                    pendingQuery,
                    forKey: pendingQuery.requestID
                )
                assert(
                    original == nil,
                    """
                    State machine must not have been asked to add duplicate pending queries.
                    This will result in a query leak where the query is never fulfilled.
                    This is a bug in the channel handler. The channel handler must not have passed a
                    pending query with a duplicate in-flight request ID.
                    Please report this bug at https://github.com/mahdibm/swift-dns/issues.
                    The new pending query is: \(pendingQuery), the original pending query is: \(original!).
                    """
                )
            }

            @discardableResult
            mutating func removeValue(requestID: UInt16) -> PendingQuery? {
                self._pendingQueriesLookupTable.removeValue(forKey: requestID)
            }

            package func __testing_contains(_ requestID: UInt16) -> Bool {
                self._pendingQueriesLookupTable.keys.contains(requestID)
            }

            package func __testing_values() -> [PendingQuery] {
                Array(self._pendingQueriesLookupTable.values)
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
            case sendQuery(Context, DeadlineCallbackAction)
            case throwError(any Error)
        }

        /// handler wants to send a query
        @usableFromInline
        package mutating func sendQuery(_ pendingQuery: PendingQuery) -> SendQueryAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot send query when initialized")
            case .active(var state):
                let wasEmpty = state.isEmpty
                state.append(pendingQuery)
                /// If wasn't empty, then already has a deadline callback scheduled with a deadline
                /// that will occur sooner than `pendingQuery`'s deadline.
                /// We are sure that `pendingQuery`'s deadline will be later, because we have an
                /// agreement that the query timeouts are the same for a given channel.
                /// For example the query function doesn't currently accept a custom query timeout.
                let deadlineCallback: DeadlineCallbackAction =
                    wasEmpty ? .reschedule(pendingQuery.deadline) : .doNothing
                let action: SendQueryAction = .sendQuery(state.context, deadlineCallback)
                self = .active(state)
                return action
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
            case respondAndClose(PendingQuery)
            case doNothing
        }

        /// handler wants to send a query
        @usableFromInline
        package mutating func receivedResponse(requestID: UInt16) -> ReceivedResponseAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot send query when initialized")
            case .active(var state):
                guard let pendingQuery = state.removeValue(requestID: requestID) else {
                    /// PendingQuery is no longer there. Maybe it was cancelled.
                    self = .active(state)
                    return .doNothing
                }
                let deadlineCallback = Self.calculateDeadlineCallbackAction(
                    pendingQueryThatWillBeImmediatelyFulfilled: pendingQuery,
                    nextDeadline: state.firstPendingQuery?.deadline
                )
                let action: ReceivedResponseAction = .respond(pendingQuery, deadlineCallback)
                self = .active(state)
                return action
            case .closing(var state):
                guard let pendingQuery = state.removeValue(requestID: requestID) else {
                    /// PendingQuery is no longer there. Maybe it was cancelled.
                    /// Still there must be another queries pending, so we can't close the connection.
                    assert(!state.isEmpty)
                    self = .closing(state)
                    return .doNothing
                }
                guard let nextQuery = state.firstPendingQuery else {
                    /// `pendingQuery` was the last query. We can close the connection now.
                    self = .closed(nil)
                    return .respondAndClose(pendingQuery)
                }
                let deadlineCallback = Self.calculateDeadlineCallbackAction(
                    pendingQueryThatWillBeImmediatelyFulfilled: pendingQuery,
                    nextDeadline: nextQuery.deadline
                )
                self = .closing(state)
                return .respond(pendingQuery, deadlineCallback)
            case .closed:
                preconditionFailure("Cannot receive query on closed connection")
            }
        }

        @usableFromInline
        package enum HitDeadlineAction {
            case failAndReschedule(PendingQuery, DeadlineCallbackAction)
            case failAndClose(Context, PendingQuery)
            case deadlineCallbackAction(DeadlineCallbackAction)
        }

        @usableFromInline
        package mutating func hitDeadline(now: NIODeadline) -> HitDeadlineAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .active(var state):
                guard let firstQuery = state.firstPendingQuery else {
                    self = .active(state)
                    return .deadlineCallbackAction(.cancel)
                }
                if firstQuery.deadline <= now {
                    state.removeValue(requestID: firstQuery.requestID)
                    let deadlineCallback = Self.calculateDeadlineCallbackAction(
                        pendingQueryThatWillBeImmediatelyFulfilled: firstQuery,
                        nextDeadline: state.firstPendingQuery?.deadline
                    )
                    self = .active(state)
                    return .failAndReschedule(firstQuery, deadlineCallback)
                } else {
                    self = .active(state)
                    return .deadlineCallbackAction(.reschedule(firstQuery.deadline))
                }
            case .closing(var state):
                guard let firstQuery = state.firstPendingQuery else {
                    preconditionFailure("Cannot be in closing state with no pending queries")
                }
                if firstQuery.deadline <= now {
                    state.removeValue(requestID: firstQuery.requestID)
                    if let nextQuery = state.firstPendingQuery {
                        self = .closing(state)
                        return .failAndReschedule(firstQuery, .reschedule(nextQuery.deadline))
                    } else {
                        self = .closed(nil)
                        return .failAndClose(state.context, firstQuery)
                    }
                } else {
                    self = .closing(state)
                    return .deadlineCallbackAction(.reschedule(firstQuery.deadline))
                }
            case .closed(let error):
                self = .closed(error)
                return .deadlineCallbackAction(.cancel)
            }
        }

        @usableFromInline
        package enum CancelAction {
            case cancel(PendingQuery, DeadlineCallbackAction)
            case cancelAndClose(Context, PendingQuery)
            case doNothing
        }

        /// handler wants to cancel a query
        @usableFromInline
        package mutating func cancel(requestID: UInt16) -> CancelAction {
            switch consume self.state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .active(var state):
                if let existingQuery = state.removeValue(requestID: requestID) {
                    let deadlineCallback = Self.calculateDeadlineCallbackAction(
                        pendingQueryThatWillBeImmediatelyFulfilled: existingQuery,
                        nextDeadline: state.firstPendingQuery?.deadline
                    )
                    let action: CancelAction = .cancel(existingQuery, deadlineCallback)
                    self = .active(state)
                    return action
                } else {
                    self = .active(state)
                    return .doNothing
                }
            case .closing(var state):
                guard let pendingQuery = state.removeValue(requestID: requestID) else {
                    /// PendingQuery is no longer there. Maybe it was cancelled.
                    /// Still there must be another queries pending, so we can't close the connection.
                    assert(!state.isEmpty)
                    self = .closing(state)
                    return .doNothing
                }
                guard let nextQuery = state.firstPendingQuery else {
                    /// `pendingQuery` was the last query. We can close the connection now.
                    self = .closed(nil)
                    return .cancelAndClose(state.context, pendingQuery)
                }
                let deadlineCallback = Self.calculateDeadlineCallbackAction(
                    pendingQueryThatWillBeImmediatelyFulfilled: pendingQuery,
                    nextDeadline: nextQuery.deadline
                )
                self = .closing(state)
                return .cancel(pendingQuery, deadlineCallback)
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
                if state.isEmpty {
                    self = .closed(nil)
                    return .closeConnection(state.context)
                } else {
                    let action: GracefulShutdownAction = .waitForPendingQueries(state.context)
                    self = .closing(state)
                    return action
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
            case failPendingQueriesAndClose([PendingQuery])
            case doNothing
        }

        /// Want to close the connection
        @usableFromInline
        package mutating func forceClose() -> CloseAction {
            switch consume self.state {
            case .initialized:
                self = .closed(nil)
                return .doNothing
            case .active(let state):
                let (_, pendingQueries) = state.discard()
                self = .closed(nil)
                return .failPendingQueriesAndClose(pendingQueries)
            case .closing(let state):
                let (_, pendingQueries) = state.discard()
                self = .closed(nil)
                return .failPendingQueriesAndClose(pendingQueries)
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
                let (_, pendingQueries) = state.discard()
                self = .closed(nil)
                return .failPendingQueries(pendingQueries)
            case .closing(let state):
                let (_, pendingQueries) = state.discard()
                self = .closed(nil)
                return .failPendingQueries(pendingQueries)
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        static func calculateDeadlineCallbackAction(
            /// Ignoring because the query is not inflight so the deadline doesn't matter anymore
            pendingQueryThatWillBeImmediatelyFulfilled _: PendingQuery,
            nextDeadline: NIODeadline?
        ) -> DeadlineCallbackAction {
            if let nextDeadline {
                /// if there are any remaining deadlines, reschedule the callback.
                /// Even if the last query already had a deadline callback scheduled, that's
                /// no longer accurate so let's just reschedule
                return .reschedule(nextDeadline)
            } else {
                /// otherwise cancel the callback
                return .cancel
            }
        }

        private static var initialized: Self {
            StateMachine(.initialized)
        }

        private static func active(_ state: consuming ActiveState) -> Self {
            StateMachine(.active(state))
        }

        private static func closing(_ state: consuming ActiveState) -> Self {
            StateMachine(.closing(state))
        }

        private static func closed(_ error: (any Error)?) -> Self {
            StateMachine(.closed(error))
        }

        package static func __for_testing(state: consuming State) -> Self {
            StateMachine(state)
        }
    }
}
