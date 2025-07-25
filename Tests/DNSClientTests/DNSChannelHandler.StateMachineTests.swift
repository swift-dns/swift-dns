import DNSClient
import DNSModels
import NIOCore
import NIOPosix
import Testing

import struct OrderedCollections.OrderedDictionary

@Suite
struct DNSChannelHandlerStateMachineTests {
    // Function required as the #expect macro does not work with non-copyable types
    func expect(_ value: Bool, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(value, sourceLocation: sourceLocation)
    }

    @Test func fullChainResponseWorks() {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (message, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: 1)
        expect(stateMachine.state == State.active(.init(context: 1)))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery(1))
        expect(
            stateMachine.state == State.active(.init(context: 1, firstQuery: pendingQuery))
        )

        let action2 = stateMachine.receivedResponse(message: message)
        #expect(action2 == .respond(pendingQuery, .cancel))
        pendingQuery.succeed(with: message, removingIDFrom: &noOpMessageIDGenerator)
        expect(stateMachine.state == State.active(.init(context: 1)))

        let action3 = stateMachine.setClosed()
        #expect(action3 == .failPendingQueries([]))
        expect(stateMachine.state == State.closed(nil))
    }

    @Test func cancelledBeforeResponse() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (_, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!"))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action2 = stateMachine.cancel(requestID: pendingQuery.requestID)
        #expect(
            action2
                == .failPendingQueriesAndClose(
                    "context!",
                    cancel: pendingQuery,
                    closeConnectionDueToCancel: []
                )
        )
        expect(stateMachine.state == State.closed(CancellationError()))

        pendingQuery.fail(with: DNSClientError.cancelled, removingIDFrom: &noOpMessageIDGenerator)
        expect(stateMachine.state == State.closed(CancellationError()))
    }

    @Test func cancelledBeforeQuery() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (message, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.cancel(requestID: pendingQuery.requestID)
        #expect(action1 == .doNothing)
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action2 = stateMachine.sendQuery(pendingQuery)
        #expect(action2 == .sendQuery("context!"))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action3 = stateMachine.receivedResponse(message: message)
        #expect(action3 == .respond(pendingQuery, .cancel))
        pendingQuery.succeed(with: message, removingIDFrom: &noOpMessageIDGenerator)
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action4 = stateMachine.setClosed()
        #expect(action4 == .failPendingQueries([]))
        expect(stateMachine.state == State.closed(nil))
    }

    /// Assumption is the channel handler is always `active` when it reaches a user,
    /// and never `initialized`.
    @Test func cancelledBeforeActivation() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        let stateMachine = StateMachine()

        /// Assert the state, so we can statically recreate it for the exit test
        expect(stateMachine.state == State.initialized)

        /// This code-path should be unreachable
        await #expect(processExitsWith: .failure) {
            var stateMachine = StateMachine.__for_testing(state: .initialized)
            _ = stateMachine.cancel(requestID: .random(in: .min ... .max))
        }
    }

    @Test func closeAfterActivation() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.close()
        #expect(action1 == StateMachine.CloseAction.failPendingQueriesAndClose("context!", []))
        expect(stateMachine.state == .closed(nil))

        /// This code-path should be unreachable
        await #expect(processExitsWith: .failure) {
            var stateMachine = StateMachine.__for_testing(
                state: .active(.init(context: "context!"))
            )
            let (_, pendingQuery) = makeMessageAndPendingQuery()
            _ = stateMachine.sendQuery(pendingQuery)
        }
    }

    @Test func closeAfterQuery() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (_, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action2 = stateMachine.sendQuery(pendingQuery)
        #expect(action2 == .sendQuery("context!"))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action1 = stateMachine.close()
        #expect(
            action1
                == StateMachine.CloseAction.failPendingQueriesAndClose(
                    "context!",
                    [pendingQuery]
                )
        )
        expect(stateMachine.state == .closed(nil))

        pendingQuery.fail(
            with: DNSClientError.connectionClosed,
            removingIDFrom: &noOpMessageIDGenerator
        )
    }

    @Test func closeAfterResponse() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (message, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!"))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action2 = stateMachine.receivedResponse(message: message)
        #expect(action2 == .respond(pendingQuery, .cancel))
        pendingQuery.succeed(with: message, removingIDFrom: &noOpMessageIDGenerator)
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action3 = stateMachine.close()
        #expect(
            action3
                == StateMachine.CloseAction.failPendingQueriesAndClose("context!", [])
        )
        expect(stateMachine.state == .closed(nil))
    }

    @Test func closeAfterMultipleQueries() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (_, pendingQuery1) = makeMessageAndPendingQuery()
        let (message2, pendingQuery2) = makeMessageAndPendingQuery()
        let (_, pendingQuery3) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery1)
        #expect(action1 == .sendQuery("context!"))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery1))
        )

        let action2 = stateMachine.sendQuery(pendingQuery2)
        #expect(action2 == .sendQuery("context!"))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", pendingQueries: [pendingQuery1, pendingQuery2]))
        )

        let action3 = stateMachine.receivedResponse(message: message2)
        #expect(action3 == .respond(pendingQuery2, .reschedule(pendingQuery1.deadline)))
        pendingQuery2.succeed(with: message2, removingIDFrom: &noOpMessageIDGenerator)
        expect(stateMachine.state == State.active(.init(context: "context!", pendingQueries: [pendingQuery1])))

        let action4 = stateMachine.sendQuery(pendingQuery3)
        #expect(action4 == .sendQuery("context!"))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", pendingQueries: [pendingQuery1, pendingQuery3]))
        )

        let action5 = stateMachine.close()
        #expect(
            action5
                == StateMachine.CloseAction.failPendingQueriesAndClose("context!", [pendingQuery1, pendingQuery3])
        )
        expect(stateMachine.state == .closed(nil))

        pendingQuery1.fail(
            with: DNSClientError.connectionClosed,
            removingIDFrom: &noOpMessageIDGenerator
        )
        pendingQuery3.fail(
            with: DNSClientError.connectionClosed,
            removingIDFrom: &noOpMessageIDGenerator
        )
    }

    @Test(arguments: [(queryCount: 1_000, latencyRange: 20...250)])
    func concurrentlySendingQueriesWorks(
        queryCount: Int,
        latencyRange: ClosedRange<Int>
    ) async throws {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        stateMachine.setActive(context: 1)
        expect(stateMachine.state == State.active(.init(context: 1)))

        actor QuerySender {
            var stateMachine: StateMachine
            let latencyRange: ClosedRange<Int>
            var messageIDGenerator = MessageIDGenerator()

            init(stateMachine: consuming StateMachine, latencyRange: ClosedRange<Int>) {
                self.stateMachine = stateMachine
                self.latencyRange = latencyRange
            }

            func sendQuery() async throws {
                let requestID = try messageIDGenerator.next()
                let pendingQuery = PendingQuery(
                    promise: .nio(MultiThreadedEventLoopGroup.singleton.next().makePromise()),
                    requestID: requestID,
                    deadline: .now() + .seconds(10)
                )
                var message = try! MessageFactory<A>.forQuery(name: "mahdibm.com").takeMessage()
                message.header.id = requestID

                let action1 = stateMachine.sendQuery(pendingQuery)
                #expect(action1 == .sendQuery(1))
                switch action1 {
                case .sendQuery(let context):
                    #expect(context == 1)
                    switch stateMachine.state {
                    case .active(let state):
                        #expect(state.context == 1)
                        #expect(
                            state.pendingQueries.map(\.requestID).contains(pendingQuery.requestID)
                        )
                    default:
                        Issue.record("Expected active state")
                    }
                default:
                    Issue.record("Expected sendQuery action")
                }

                /// Simulate network latency
                try await Task.sleep(
                    for: .milliseconds(latencyRange.randomElement()!),
                    tolerance: .zero
                )

                let action2 = stateMachine.receivedResponse(message: message)

                switch action2 {
                case .respond(let pendingQuery, _):
                    #expect(pendingQuery == pendingQuery)
                    pendingQuery.succeed(with: message, removingIDFrom: &messageIDGenerator)
                    switch stateMachine.state {
                    case .active(let state):
                        #expect(state.context == 1)
                        #expect(
                            !state.pendingQueries.map(\.requestID).contains(pendingQuery.requestID)
                        )
                    default:
                        Issue.record("Expected active state")
                    }
                default:
                    Issue.record("Expected respond action")
                }
            }
        }

        let querySender = QuerySender(
            stateMachine: stateMachine,
            latencyRange: latencyRange
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<queryCount {
                group.addTask {
                    try await querySender.sendQuery()
                }
            }
            try await group.waitForAll()
        }
    }

    @Test(arguments: [(queryCount: 30, latencyRange: 20...100)])
    func sequentiallySendingQueriesWorks(
        queryCount: Int,
        latencyRange: ClosedRange<Int>
    ) async throws {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var messageIDGenerator = MessageIDGenerator()

        stateMachine.setActive(context: 1)
        expect(stateMachine.state == State.active(.init(context: 1)))

        for _ in 0..<queryCount {
            let requestID = try messageIDGenerator.next()
            let pendingQuery = PendingQuery(
                promise: .nio(MultiThreadedEventLoopGroup.singleton.next().makePromise()),
                requestID: requestID,
                deadline: .now() + .seconds(10)
            )
            var message = try! MessageFactory<A>.forQuery(name: "mahdibm.com").takeMessage()
            message.header.id = requestID

            let action1 = stateMachine.sendQuery(pendingQuery)
            #expect(action1 == .sendQuery(1))
            switch action1 {
            case .sendQuery(let context):
                #expect(context == 1)
                switch stateMachine.state {
                case .active(let state):
                    #expect(state.context == 1)
                    #expect(
                        state.pendingQueries.map(\.requestID).contains(pendingQuery.requestID)
                    )
                default:
                    Issue.record("Expected active state")
                }
            default:
                Issue.record("Expected sendQuery action")
            }

            /// Simulate network latency
            try await Task.sleep(
                for: .milliseconds(latencyRange.randomElement()!),
                tolerance: .zero
            )

            let action2 = stateMachine.receivedResponse(message: message)

            switch action2 {
            case .respond(let pendingQuery, _):
                #expect(pendingQuery == pendingQuery)
                pendingQuery.succeed(with: message, removingIDFrom: &messageIDGenerator)
                switch stateMachine.state {
                case .active(let state):
                    #expect(state.context == 1)
                    #expect(
                        !state.pendingQueries.map(\.requestID).contains(pendingQuery.requestID)
                    )
                default:
                    Issue.record("Expected active state")
                }
            default:
                Issue.record("Expected respond action")
            }
        }

        let action3 = stateMachine.setClosed()
        #expect(action3 == .failPendingQueries([]))
        expect(stateMachine.state == State.closed(nil))
    }
}

private func makeMessageAndPendingQuery() -> (Message, PendingQuery) {
    let pendingQuery = PendingQuery(
        promise: .nio(MultiThreadedEventLoopGroup.singleton.next().makePromise()),
        requestID: .random(in: .min ... .max),
        deadline: .now() + .seconds(10)
    )
    var message = try! MessageFactory<A>.forQuery(name: "mahdibm.com").takeMessage()
    message.header.id = pendingQuery.requestID
    return (message, pendingQuery)
}

extension DNSChannelHandler.StateMachine.State where Context: Equatable {
    static func == (_ lhs: borrowing Self, _ rhs: borrowing Self) -> Bool {
        switch lhs {
        case .initialized:
            switch rhs {
            case .initialized:
                return true
            default:
                return false
            }
        case .active(let lhs):
            switch rhs {
            case .active(let rhs):
                return lhs.context == rhs.context
                    && lhs.pendingQueries == rhs.pendingQueries
            default:
                return false
            }
        case .closing(let lhs):
            switch rhs {
            case .closing(let rhs):
                return lhs.context == rhs.context
                    && lhs.pendingQueries == rhs.pendingQueries
            default:
                return false
            }
        case .closed(let lhs):
            switch rhs {
            case .closed(let rhs):
                switch (lhs, rhs) {
                case (.some(let lhs), .some(let rhs)):
                    return "\(String(describing: lhs))" == "\(String(describing: rhs))"
                case (.none, .none):
                    return true
                default:
                    return false
                }
            default:
                return false
            }
        }
    }

    static func != (_ lhs: borrowing Self, _ rhs: borrowing Self) -> Bool {
        !(lhs == rhs)
    }
}

extension DNSChannelHandler.StateMachine.ActiveState: Equatable where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.context == rhs.context
            && lhs.pendingQueries == rhs.pendingQueries
    }
}

extension PendingQuery: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.requestID == rhs.requestID
            && lhs.deadline == rhs.deadline
    }
}

extension DNSChannelHandler.StateMachine.SendQueryAction: Equatable where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.sendQuery(let lhs), .sendQuery(let rhs)):
            return lhs == rhs
        case (.throwError(let lhs), .throwError(let rhs)):
            return "\(String(describing: lhs))" == "\(String(describing: rhs))"
        default:
            return false
        }
    }
}

extension DNSChannelHandler.StateMachine.DeadlineCallbackAction: Equatable
where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.cancel, .cancel):
            return true
        case (.reschedule(let lhs), .reschedule(let rhs)):
            return lhs == rhs
        case (.doNothing, .doNothing):
            return true
        default:
            return false
        }
    }
}

extension DNSChannelHandler.StateMachine.ReceivedResponseAction: Equatable
where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.respond(let lhs1, let lhs2), .respond(let rhs1, let rhs2)):
            return lhs1 == rhs1
                && lhs2 == rhs2
        case (.respondAndClose(let lhs1, let lhs2), .respondAndClose(let rhs1, let rhs2)):
            return lhs1 == rhs1
                && "\(String(describing: lhs2))" == "\(String(describing: rhs2))"
        case (.closeWithError(let lhs), .closeWithError(let rhs)):
            return "\(String(describing: lhs))" == "\(String(describing: rhs))"
        default:
            return false
        }
    }
}

extension DNSChannelHandler.StateMachine.SetClosedAction: Equatable where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.failPendingQueries(let lhs), .failPendingQueries(let rhs)):
            return lhs == rhs
        case (.doNothing, .doNothing):
            return true
        default:
            return false
        }
    }
}

extension DNSChannelHandler.StateMachine.CancelAction: Equatable where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (
            .failPendingQueriesAndClose(let lhs, let lhs2, let lhs3),
            .failPendingQueriesAndClose(let rhs, let rhs2, let rhs3)
        ):
            return lhs == rhs
                && lhs2 == rhs2
                && lhs3 == rhs3
        case (.doNothing, .doNothing):
            return true
        default:
            return false
        }
    }
}

extension DNSChannelHandler.StateMachine.CloseAction: Equatable where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (
            .failPendingQueriesAndClose(let lhs, let lhs2),
            .failPendingQueriesAndClose(let rhs, let rhs2)
        ):
            return lhs == rhs
                && lhs2 == rhs2
        case (.doNothing, .doNothing):
            return true
        default:
            return false
        }
    }
}
