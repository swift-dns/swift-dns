public import NIOCore

import struct OrderedCollections.OrderedDictionary

@available(swiftDNSApplePlatforms 15, *)
extension DNSChannelHandler {
    @usableFromInline
    package struct StateMachine<Context>: ~Copyable {

        @usableFromInline
        package enum State: ~Copyable {
            case initialized
            case processing(ProcessingState)
            case closed((any Error)?)

            @usableFromInline
            package var description: String {
                borrowing get {
                    switch self {
                    case .initialized: "initialized"
                    case .processing: "processing"
                    case .closed: "closed"
                    }
                }
            }
        }

        @usableFromInline
        package var _state: State

        package init() {
            self._state = .initialized
        }

        /// `pendingQueriesLookupTable` is sorted by the order of the pending queries.
        /// The order is used to determine the next query which will reach its deadline first.
        /// To not break this assumption, all `deadline`s of `PendingQuery`s must be the same.
        /// Today this is the case. The `deadline` originates from the `DNSClientConfiguration`.
        /// That means it's always the same number.
        /// However if one day we want to allow users to use multiple queryTimeouts, e.g. at function
        /// call sites, then we'll have to reevaluate this logic in `ProcessingState`.
        @usableFromInline
        package struct ProcessingState: ~Copyable {
            package let context: Context
            package var isClosing: Bool
            /// [PendingQuery.requestID: PendingQuery] where PendingQuery.requestID == message.header.id
            private var pendingQueriesLookupTable: OrderedDictionary<UInt16, PendingQuery>

            package init(context: Context, isClosing: Bool = false) {
                self.context = context
                self.isClosing = isClosing
                self.pendingQueriesLookupTable = [:]
            }

            var isEmpty: Bool {
                self.pendingQueriesLookupTable.isEmpty
            }

            consuming func discard() -> (Context, [PendingQuery]) {
                (self.context, Array(self.pendingQueriesLookupTable.values))
            }

            package var firstPendingQuery: PendingQuery? {
                self.pendingQueriesLookupTable.values.first
            }

            mutating func append(_ pendingQuery: PendingQuery) {
                let original = self.pendingQueriesLookupTable.updateValue(
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
                self.pendingQueriesLookupTable.removeValue(forKey: requestID)
            }
        }

        /// handler has become available for processing
        @usableFromInline
        package mutating func setProcessing(context: Context) {
            switch consume self._state {
            case .initialized:
                self = .processing(ProcessingState(context: context))
            case .processing:
                preconditionFailure("Cannot set processing when already processing")
            case .closed:
                preconditionFailure("Cannot set connected state when state is closed")
            }
        }

        /// A send-query preflight check to see if it's needed to process the query at all or not
        package mutating func preflightCheck() throws {
            switch consume self._state {
            case .initialized:
                preconditionFailure("Cannot have intention of sending a query when initialized")
            case .processing(let state):
                if state.isClosing {
                    self = .processing(state)
                    throw DNSClientError.connectionClosing
                } else {
                    self = .processing(state)
                }
            case .closed(let error):
                self = .closed(error)
                throw DNSClientError.connectionClosed
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
            switch consume self._state {
            case .initialized:
                preconditionFailure("Cannot send query when initialized")
            case .processing(var state):
                if state.isClosing {
                    self = .processing(state)
                    return .throwError(DNSClientError.connectionClosing)
                }
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
                self = .processing(state)
                return action
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
            case respondAndClose(PendingQuery, DeadlineCallbackAction)
            case doNothing
        }

        /// handler wants to send a query
        @usableFromInline
        package mutating func receivedResponse(requestID: UInt16) -> ReceivedResponseAction {
            switch consume self._state {
            case .initialized:
                preconditionFailure("Cannot send query when initialized")
            case .processing(var state):
                guard let pendingQuery = state.removeValue(requestID: requestID) else {
                    /// PendingQuery is no longer there. Maybe it was cancelled.
                    self = .processing(state)
                    return .doNothing
                }
                if state.isClosing, state.isEmpty {
                    self = .closed(nil)
                    return .respondAndClose(pendingQuery, .cancel)
                }
                let deadlineCallback = Self.calculateDeadlineCallbackAction(
                    pendingQueryThatWillBeImmediatelyFulfilled: pendingQuery,
                    nextDeadline: state.firstPendingQuery?.deadline
                )
                let action: ReceivedResponseAction = .respond(pendingQuery, deadlineCallback)
                self = .processing(state)
                return action
            case .closed:
                preconditionFailure("Cannot receive query on closed connection")
            }
        }

        @usableFromInline
        package enum HitDeadlineAction {
            case failAndReschedule(PendingQuery, DeadlineCallbackAction)
            case failAndClose(Context, PendingQuery, DeadlineCallbackAction)
            case deadlineCallbackAction(DeadlineCallbackAction)
        }

        @usableFromInline
        package mutating func hitDeadline(now: NIODeadline) -> HitDeadlineAction {
            switch consume self._state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .processing(var state):
                guard let firstQuery = state.firstPendingQuery else {
                    switch state.isClosing {
                    case true:
                        preconditionFailure("Cannot be in closing state with no pending queries")
                    case false:
                        self = .processing(state)
                        return .deadlineCallbackAction(.cancel)
                    }
                }
                if firstQuery.deadline <= now {
                    state.removeValue(requestID: firstQuery.requestID)
                    if state.isClosing, state.isEmpty {
                        self = .closed(nil)
                        return .failAndClose(state.context, firstQuery, .cancel)
                    }
                    let deadlineCallback = Self.calculateDeadlineCallbackAction(
                        pendingQueryThatWillBeImmediatelyFulfilled: firstQuery,
                        nextDeadline: state.firstPendingQuery?.deadline
                    )
                    self = .processing(state)
                    return .failAndReschedule(firstQuery, deadlineCallback)
                } else {
                    self = .processing(state)
                    return .deadlineCallbackAction(.reschedule(firstQuery.deadline))
                }
            case .closed:
                preconditionFailure("Cannot hit deadline when closed")
            }
        }

        @usableFromInline
        package enum CancelAction {
            case cancel(PendingQuery, DeadlineCallbackAction)
            case cancelAndClose(Context, PendingQuery, DeadlineCallbackAction)
            case doNothing
        }

        /// handler wants to cancel a query
        @usableFromInline
        package mutating func cancel(requestID: UInt16) -> CancelAction {
            switch consume self._state {
            case .initialized:
                preconditionFailure("Cannot cancel when initialized")
            case .processing(var state):
                guard let pendingQuery = state.removeValue(requestID: requestID) else {
                    /// PendingQuery is no longer there. Maybe it was cancelled.
                    /// Still there must be another queries pending, so we can't close the connection.
                    /// It can't be that the connection is closing but the state is also empty.
                    assert(!(state.isClosing && state.isEmpty))
                    self = .processing(state)
                    return .doNothing
                }
                if state.isClosing, state.isEmpty {
                    self = .closed(nil)
                    return .cancelAndClose(state.context, pendingQuery, .cancel)
                }
                let deadlineCallback = Self.calculateDeadlineCallbackAction(
                    pendingQueryThatWillBeImmediatelyFulfilled: pendingQuery,
                    nextDeadline: state.firstPendingQuery?.deadline
                )
                self = .processing(state)
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
            switch consume self._state {
            case .initialized:
                self = .closed(nil)
                return .doNothing
            case .processing(var state):
                if state.isClosing {
                    assert(!state.isEmpty)
                    /// Already closing. Let's ignore
                    self = .processing(state)
                    return .doNothing
                } else if state.isEmpty {
                    self = .closed(nil)
                    return .closeConnection(state.context)
                } else {
                    state.isClosing = true
                    let action: GracefulShutdownAction = .waitForPendingQueries(state.context)
                    self = .processing(state)
                    return action
                }
            case .closed(let error):
                self = .closed(error)
                return .doNothing
            }
        }

        @usableFromInline
        package enum CloseAction {
            case failPendingQueriesAndClose([PendingQuery], DeadlineCallbackAction)
            case doNothing
        }

        /// Want to immediately close the connection, or already has closed the connection.
        @usableFromInline
        package mutating func forceClose() -> CloseAction {
            switch consume self._state {
            case .initialized:
                self = .closed(nil)
                return .doNothing
            case .processing(let state):
                let (_, pendingQueries) = state.discard()
                self = .closed(nil)
                return .failPendingQueriesAndClose(pendingQueries, .cancel)
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

        private init(_ state: consuming State) {
            self._state = state
        }

        private static var initialized: Self {
            StateMachine(.initialized)
        }

        private static func processing(_ state: consuming ProcessingState) -> Self {
            StateMachine(.processing(state))
        }

        private static func closed(_ error: (any Error)?) -> Self {
            StateMachine(.closed(error))
        }

        package static func __for_testing(state: consuming State) -> Self {
            StateMachine(state)
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension DNSChannelHandler.StateMachine.ProcessingState {
    package static func __for_testing(
        context: Context,
        isClosing: Bool = false,
        pendingQueries: [PendingQuery]
    ) -> Self {
        var state = Self(
            context: context,
            isClosing: isClosing
        )
        for pendingQuery in pendingQueries {
            state.append(pendingQuery)
        }
        return state
    }

    package func __testing_contains(_ requestID: UInt16) -> Bool {
        self.pendingQueriesLookupTable.keys.contains(requestID)
    }

    package func __testing_values() -> [PendingQuery] {
        Array(self.pendingQueriesLookupTable.values)
    }
}
