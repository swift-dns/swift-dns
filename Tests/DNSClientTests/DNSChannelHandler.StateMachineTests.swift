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

    @Test func orderOfPendingQueriesIsPreserved() throws {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var messageIDGenerator = MessageIDGenerator()

        stateMachine.setActive(context: 1)
        expect(stateMachine.state == State.active(.init(context: 1)))

        let pendingQueries = try (0..<1000).map { _ in
            PendingQuery(
                promise: .nio(MultiThreadedEventLoopGroup.singleton.next().makePromise()),
                requestID: try messageIDGenerator.next(),
                deadline: .now() + .seconds(10)
            )
        }
        for pendingQuery in pendingQueries {
            let action = stateMachine.sendQuery(pendingQuery)
            switch action {
            case .sendQuery(let context, _):
                #expect(context == 1)
            default:
                Issue.record("Expected sendQuery action")
            }
        }

        switch stateMachine.state {
        case .active(let context):
            #expect(context.context == 1)
            #expect(context.__testing_values() == pendingQueries)
            #expect(context.firstPendingQuery == pendingQueries.first)
        default:
            Issue.record("Expected active state")
        }

        /// Don't leak the promise
        for pendingQuery in pendingQueries {
            pendingQuery.fail(
                with: DNSClientError.connectionClosed,
                removingIDFrom: &messageIDGenerator
            )
        }
    }

    @Test func sendQueryAndReceivedResponseWorks() {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (message, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: 1)
        expect(stateMachine.state == State.active(.init(context: 1)))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery(1, .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine.state == State.active(.init(context: 1, firstQuery: pendingQuery))
        )

        let action2 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
        #expect(action2 == .respond(pendingQuery, .cancel))
        pendingQuery.succeed(with: message, removingIDFrom: &noOpMessageIDGenerator)
        expect(stateMachine.state == State.active(.init(context: 1)))

        let action3 = stateMachine.setClosed()
        #expect(action3 == .failPendingQueries([]))
        expect(stateMachine.state == State.closed(nil))
    }

    @Test func sendQueryThrowsErrorWhenClosing() {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (message1, pendingQuery1) = makeMessageAndPendingQuery()
        let (_, pendingQuery2) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: 1)
        expect(stateMachine.state == State.active(.init(context: 1)))

        let action1 = stateMachine.sendQuery(pendingQuery1)
        #expect(action1 == .sendQuery(1, .reschedule(pendingQuery1.deadline)))
        expect(
            stateMachine.state == State.active(.init(context: 1, firstQuery: pendingQuery1))
        )

        let action2 = stateMachine.gracefulShutdown()
        #expect(action2 == .waitForPendingQueries(1))
        expect(stateMachine.state == State.closing(.init(context: 1, firstQuery: pendingQuery1)))

        let action3 = stateMachine.sendQuery(pendingQuery2)
        #expect(action3 == .throwError(DNSClientError.connectionClosing))
        expect(stateMachine.state == State.closing(.init(context: 1, firstQuery: pendingQuery1)))
        pendingQuery2.fail(
            with: DNSClientError.connectionClosing,
            removingIDFrom: &noOpMessageIDGenerator
        )
        expect(stateMachine.state == State.closing(.init(context: 1, firstQuery: pendingQuery1)))

        let action4 = stateMachine.receivedResponse(requestID: pendingQuery1.requestID)
        #expect(action4 == .respondAndClose(pendingQuery1))
        pendingQuery1.succeed(with: message1, removingIDFrom: &noOpMessageIDGenerator)
        expect(stateMachine.state == State.closed(nil))
    }

    @Test func receivedResponseWorksWhenClosingAndReschedulesDeadline() {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (message1, pendingQuery1) = makeMessageAndPendingQuery()
        let (message2, pendingQuery2) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: 1)
        expect(stateMachine.state == State.active(.init(context: 1)))

        let action1 = stateMachine.sendQuery(pendingQuery1)
        #expect(action1 == .sendQuery(1, .reschedule(pendingQuery1.deadline)))
        expect(
            stateMachine.state == State.active(.init(context: 1, firstQuery: pendingQuery1))
        )

        let action2 = stateMachine.sendQuery(pendingQuery2)
        #expect(action2 == .sendQuery(1, .doNothing))
        expect(
            stateMachine.state
                == State.active(
                    .init(__testing_context: 1, pendingQueries: [pendingQuery1, pendingQuery2])
                )
        )

        let action3 = stateMachine.gracefulShutdown()
        #expect(action3 == .waitForPendingQueries(1))
        expect(
            stateMachine.state
                == State.closing(
                    .init(
                        __testing_context: 1,
                        pendingQueries: [pendingQuery1, pendingQuery2]
                    )
                )
        )

        let action4 = stateMachine.receivedResponse(requestID: pendingQuery2.requestID)
        #expect(action4 == .respond(pendingQuery2, .reschedule(pendingQuery1.deadline)))
        pendingQuery2.succeed(with: message2, removingIDFrom: &noOpMessageIDGenerator)
        expect(
            stateMachine.state
                == State.closing(.init(context: 1, firstQuery: pendingQuery1))
        )

        let action5 = stateMachine.receivedResponse(requestID: pendingQuery1.requestID)
        #expect(action5 == .respondAndClose(pendingQuery1))
        pendingQuery1.succeed(with: message1, removingIDFrom: &noOpMessageIDGenerator)
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
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action2 = stateMachine.cancel(requestID: pendingQuery.requestID)
        #expect(action2 == .cancel(pendingQuery, .cancel))
        expect(stateMachine.state == State.active(.init(context: "context!")))

        pendingQuery.fail(with: DNSClientError.cancelled, removingIDFrom: &noOpMessageIDGenerator)
    }

    @Test func cancelledBeforeResponseAndResponseArrivesLater() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (_, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action2 = stateMachine.cancel(requestID: pendingQuery.requestID)
        #expect(action2 == .cancel(pendingQuery, .cancel))
        expect(stateMachine.state == State.active(.init(context: "context!")))
        /// Response is failed due to cancellation
        pendingQuery.fail(with: DNSClientError.cancelled, removingIDFrom: &noOpMessageIDGenerator)
        expect(stateMachine.state == State.active(.init(context: "context!")))

        /// No matching pending query is there anymore
        let action3 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
        #expect(action3 == .doNothing)
    }

    @Test func cancelledWithMultiplePendingQueriesWorksAndReschedulesDeadlineCorrectly() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (_, pendingQuery1) = makeMessageAndPendingQuery()
        let (_, pendingQuery2) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery1)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery1.deadline)))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery1))
        )

        let action2 = stateMachine.sendQuery(pendingQuery2)
        #expect(action2 == .sendQuery("context!", .doNothing))
        expect(
            stateMachine.state
                == State.active(
                    .init(
                        __testing_context: "context!",
                        pendingQueries: [pendingQuery1, pendingQuery2]
                    )
                )
        )

        let action3 = stateMachine.cancel(requestID: pendingQuery1.requestID)
        /// Action asks to reschedule deadline for the next pending query
        #expect(action3 == .cancel(pendingQuery1, .reschedule(pendingQuery2.deadline)))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery2))
        )
        /// Response is failed due to cancellation
        pendingQuery1.fail(with: DNSClientError.cancelled, removingIDFrom: &noOpMessageIDGenerator)
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery2))
        )

        let action4 = stateMachine.cancel(requestID: pendingQuery2.requestID)
        /// Action asks to cancel deadline because no more queries are available
        #expect(action4 == .cancel(pendingQuery2, .cancel))
        expect(stateMachine.state == State.active(.init(context: "context!")))
        /// Response is failed due to cancellation
        pendingQuery2.fail(with: DNSClientError.cancelled, removingIDFrom: &noOpMessageIDGenerator)
        expect(stateMachine.state == State.active(.init(context: "context!")))
    }

    @Test func cancelledBeforeQuery() {
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
        #expect(action2 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action3 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
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

    @Test func forceCloseAfterActivationThenQueryThrowsError() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.forceClose()
        #expect(action1 == StateMachine.CloseAction.failPendingQueriesAndClose([]))
        expect(stateMachine.state == .closed(nil))

        let (_, pendingQuery) = makeMessageAndPendingQuery()
        let action2 = stateMachine.sendQuery(pendingQuery)
        #expect(action2 == .throwError(DNSClientError.connectionClosed))
        expect(stateMachine.state == .closed(nil))

        pendingQuery.fail(
            with: DNSClientError.connectionClosed,
            removingIDFrom: &noOpMessageIDGenerator
        )
    }

    @Test func forceCloseBeforeActivationDoesNothing() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        let action1 = stateMachine.forceClose()
        #expect(action1 == StateMachine.CloseAction.doNothing)
        expect(stateMachine.state == .closed(nil))
    }

    @Test func forceCloseAfterCloseDoesNothing() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.forceClose()
        #expect(action1 == StateMachine.CloseAction.failPendingQueriesAndClose([]))
        expect(stateMachine.state == .closed(nil))

        let action2 = stateMachine.forceClose()
        #expect(action2 == StateMachine.CloseAction.doNothing)
        expect(stateMachine.state == .closed(nil))
    }

    @Test func forceCloseAfterQuery() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (_, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action2 = stateMachine.sendQuery(pendingQuery)
        #expect(action2 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action1 = stateMachine.forceClose()
        #expect(
            action1
                == StateMachine.CloseAction.failPendingQueriesAndClose([pendingQuery])
        )
        expect(stateMachine.state == .closed(nil))

        pendingQuery.fail(
            with: DNSClientError.connectionClosed,
            removingIDFrom: &noOpMessageIDGenerator
        )
    }

    @Test func forceCloseAfterResponse() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (message, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action2 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
        #expect(action2 == .respond(pendingQuery, .cancel))
        pendingQuery.succeed(with: message, removingIDFrom: &noOpMessageIDGenerator)
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action3 = stateMachine.forceClose()
        #expect(
            action3
                == StateMachine.CloseAction.failPendingQueriesAndClose([])
        )
        expect(stateMachine.state == .closed(nil))
    }

    @Test func forceCloseAfterMultipleQueries() {
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
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery1.deadline)))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery1))
        )

        let action2 = stateMachine.sendQuery(pendingQuery2)
        #expect(action2 == .sendQuery("context!", .doNothing))
        expect(
            stateMachine.state
                == State.active(
                    .init(
                        __testing_context: "context!",
                        pendingQueries: [pendingQuery1, pendingQuery2]
                    )
                )
        )

        let action3 = stateMachine.receivedResponse(requestID: pendingQuery2.requestID)
        #expect(action3 == .respond(pendingQuery2, .reschedule(pendingQuery1.deadline)))
        pendingQuery2.succeed(with: message2, removingIDFrom: &noOpMessageIDGenerator)
        expect(
            stateMachine.state
                == State.active(
                    .init(__testing_context: "context!", pendingQueries: [pendingQuery1])
                )
        )

        let action4 = stateMachine.sendQuery(pendingQuery3)
        #expect(action4 == .sendQuery("context!", .doNothing))
        expect(
            stateMachine.state
                == State.active(
                    .init(
                        __testing_context: "context!",
                        pendingQueries: [pendingQuery1, pendingQuery3]
                    )
                )
        )

        let action5 = stateMachine.forceClose()
        #expect(
            action5
                == StateMachine.CloseAction.failPendingQueriesAndClose([
                    pendingQuery1, pendingQuery3,
                ])
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

    @Test func forceCloseForcesConnectionCloseWhenClosingAndThereArePendingQueries() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (_, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))

        let action2 = stateMachine.gracefulShutdown()
        #expect(action2 == .waitForPendingQueries("context!"))
        expect(
            stateMachine.state
                == State.closing(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action3 = stateMachine.forceClose()
        #expect(action3 == .failPendingQueriesAndClose([pendingQuery]))
        expect(stateMachine.state == State.closed(nil))

        pendingQuery.fail(
            with: DNSClientError.connectionClosed,
            removingIDFrom: &noOpMessageIDGenerator
        )
        expect(stateMachine.state == State.closed(nil))
    }

    @Test func hitDeadlineWorksForInflightQuery() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (_, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))

        /// Intentionally pass `pendingQuery.deadline` as `now`. Still should fail and reschedule.
        let action2 = stateMachine.hitDeadline(now: pendingQuery.deadline)
        #expect(action2 == .failAndReschedule(pendingQuery, .cancel))
        expect(stateMachine.state == State.active(.init(context: "context!")))

        pendingQuery.fail(
            with: DNSClientError.queryTimeout,
            removingIDFrom: &noOpMessageIDGenerator
        )
        expect(stateMachine.state == State.active(.init(context: "context!")))
    }

    @Test func hitDeadlineDoesNothingWhenNoPendingQueries() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.hitDeadline(now: .now() + .seconds(1))
        #expect(action1 == .deadlineCallbackAction(.cancel))
        expect(stateMachine.state == State.active(.init(context: "context!")))
    }

    @Test func hitDeadlineDoesNotCancelQueryWithUnexpiredDeadline() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (message, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine.state == State.active(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action2 = stateMachine.hitDeadline(now: pendingQuery.deadline + .seconds(-1))
        #expect(action2 == .deadlineCallbackAction(.reschedule(pendingQuery.deadline)))
        expect(
            stateMachine.state == State.active(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action3 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
        #expect(action3 == .respond(pendingQuery, .cancel))
        pendingQuery.succeed(with: message, removingIDFrom: &noOpMessageIDGenerator)
        expect(stateMachine.state == State.active(.init(context: "context!")))
    }

    @Test func hitDeadlineWithMultiplePendingQueriesWorksAndReschedulesDeadlineCorrectly() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (_, pendingQuery1) = makeMessageAndPendingQuery()
        let (_, pendingQuery2) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery1)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery1.deadline)))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery1))
        )

        let action2 = stateMachine.sendQuery(pendingQuery2)
        #expect(action2 == .sendQuery("context!", .doNothing))
        expect(
            stateMachine.state
                == State.active(
                    .init(
                        __testing_context: "context!",
                        pendingQueries: [pendingQuery1, pendingQuery2]
                    )
                )
        )

        let action3 = stateMachine.hitDeadline(now: pendingQuery1.deadline + .seconds(1))
        /// Action asks to reschedule deadline for the next pending query
        #expect(action3 == .failAndReschedule(pendingQuery1, .reschedule(pendingQuery2.deadline)))
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery2))
        )
        /// Response is failed due to cancellation
        pendingQuery1.fail(
            with: DNSClientError.queryTimeout,
            removingIDFrom: &noOpMessageIDGenerator
        )
        expect(
            stateMachine.state
                == State.active(.init(context: "context!", firstQuery: pendingQuery2))
        )

        let action4 = stateMachine.hitDeadline(now: pendingQuery2.deadline + .seconds(1))
        /// Action asks to cancel deadline because no more queries are available
        #expect(action4 == .failAndReschedule(pendingQuery2, .cancel))
        expect(stateMachine.state == State.active(.init(context: "context!")))
        /// Response is failed due to cancellation
        pendingQuery2.fail(
            with: DNSClientError.queryTimeout,
            removingIDFrom: &noOpMessageIDGenerator
        )
        expect(stateMachine.state == State.active(.init(context: "context!")))
    }

    @Test func hitDeadlineClosesConnectionWhenClosingAndNoMorePendingQueries() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (_, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))

        let action2 = stateMachine.gracefulShutdown()
        #expect(action2 == .waitForPendingQueries("context!"))
        expect(
            stateMachine.state
                == State.closing(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action3 = stateMachine.hitDeadline(now: pendingQuery.deadline + .seconds(1))
        #expect(action3 == .failAndClose("context!", pendingQuery))
        expect(stateMachine.state == State.closed(nil))

        pendingQuery.fail(
            with: DNSClientError.queryTimeout,
            removingIDFrom: &noOpMessageIDGenerator
        )
        expect(stateMachine.state == State.closed(nil))
    }

    @Test func gracefulShutdownClosesConnectionImmediatelyWhenNoPendingQueries() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.gracefulShutdown()
        #expect(action1 == .closeConnection("context!"))
        expect(stateMachine.state == State.closed(nil))
    }

    @Test func gracefulShutdownBeforeActivationClosesImmediately() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        let action1 = stateMachine.gracefulShutdown()
        #expect(action1 == .doNothing)
        expect(stateMachine.state == State.closed(nil))
    }

    @Test func gracefulShutdownWhenClosingDoesNothing() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var noOpMessageIDGenerator = MessageIDGenerator()
        let (message, pendingQuery) = makeMessageAndPendingQuery()

        stateMachine.setActive(context: "context!")
        expect(stateMachine.state == State.active(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))

        let action2 = stateMachine.gracefulShutdown()
        #expect(action2 == .waitForPendingQueries("context!"))
        expect(
            stateMachine.state
                == State.closing(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action3 = stateMachine.gracefulShutdown()
        #expect(action3 == .doNothing)
        expect(
            stateMachine.state
                == State.closing(.init(context: "context!", firstQuery: pendingQuery))
        )

        let action4 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
        #expect(action4 == .respondAndClose(pendingQuery))
        pendingQuery.succeed(with: message, removingIDFrom: &noOpMessageIDGenerator)
        expect(stateMachine.state == State.closed(nil))
    }

    @Test func gracefulShutdownWhenClosedDoesNothing() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        let action1 = stateMachine.gracefulShutdown()
        #expect(action1 == .doNothing)
        expect(stateMachine.state == State.closed(nil))

        let action2 = stateMachine.gracefulShutdown()
        #expect(action2 == .doNothing)
        expect(stateMachine.state == State.closed(nil))
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

            // Function required as the #expect macro does not work with non-copyable types
            func expect(_ value: Bool, sourceLocation: SourceLocation = #_sourceLocation) {
                #expect(value, sourceLocation: sourceLocation)
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
                switch action1 {
                case .sendQuery(let context, _):
                    #expect(context == 1)
                    switch stateMachine.state {
                    case .active(let state):
                        #expect(state.context == 1)
                        expect(state.__testing_contains(pendingQuery.requestID))
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

                let action2 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
                switch action2 {
                case .respond(let pendingQuery, _):
                    #expect(pendingQuery == pendingQuery)
                    pendingQuery.succeed(with: message, removingIDFrom: &messageIDGenerator)
                    switch stateMachine.state {
                    case .active(let state):
                        #expect(state.context == 1)
                        expect(!state.__testing_contains(pendingQuery.requestID))
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
    ) async {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var messageIDGenerator = MessageIDGenerator()

        stateMachine.setActive(context: 1)
        expect(stateMachine.state == State.active(.init(context: 1)))

        for _ in 0..<queryCount {
            let requestID = try! messageIDGenerator.next()
            let pendingQuery = PendingQuery(
                promise: .nio(MultiThreadedEventLoopGroup.singleton.next().makePromise()),
                requestID: requestID,
                deadline: .now() + .seconds(10)
            )
            var message = try! MessageFactory<A>.forQuery(name: "mahdibm.com").takeMessage()
            message.header.id = requestID

            let action1 = stateMachine.sendQuery(pendingQuery)
            switch action1 {
            case .sendQuery(let context, _):
                #expect(context == 1)
                switch stateMachine.state {
                case .active(let state):
                    #expect(state.context == 1)
                    expect(state.__testing_contains(pendingQuery.requestID))
                default:
                    Issue.record("Expected active state")
                }
            default:
                Issue.record("Expected sendQuery action")
            }

            /// Simulate network latency
            try! await Task.sleep(
                for: .milliseconds(latencyRange.randomElement()!),
                tolerance: .zero
            )

            let action2 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)

            switch action2 {
            case .respond(let pendingQuery, _):
                #expect(pendingQuery == pendingQuery)
                pendingQuery.succeed(with: message, removingIDFrom: &messageIDGenerator)
                switch stateMachine.state {
                case .active(let state):
                    #expect(state.context == 1)
                    expect(!state.__testing_contains(pendingQuery.requestID))
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
                    && lhs.__testing_values() == rhs.__testing_values()
            default:
                return false
            }
        case .closing(let lhs):
            switch rhs {
            case .closing(let rhs):
                return lhs.context == rhs.context
                    && lhs.__testing_values() == rhs.__testing_values()
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

extension DNSChannelHandler.StateMachine.ActiveState where Context: Equatable {
    static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        lhs.context == rhs.context
            && lhs.__testing_values() == rhs.__testing_values()
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
        case (.sendQuery(let lhs1, let lhs2), .sendQuery(let rhs1, let rhs2)):
            return lhs1 == rhs1
                && lhs2 == rhs2
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
        case (.respondAndClose(let lhs), .respondAndClose(let rhs)):
            return lhs == rhs
        case (.doNothing, .doNothing):
            return true
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
            .cancel(let lhs, let lhs2),
            .cancel(let rhs, let rhs2)
        ):
            return lhs == rhs
                && lhs2 == rhs2
        case (.cancelAndClose(let lhs, let lhs2), .cancelAndClose(let rhs, let rhs2)):
            return lhs == rhs
                && lhs2 == rhs2
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
            .failPendingQueriesAndClose(let lhs),
            .failPendingQueriesAndClose(let rhs)
        ):
            return lhs == rhs
        case (.doNothing, .doNothing):
            return true
        default:
            return false
        }
    }
}

extension DNSChannelHandler.StateMachine.HitDeadlineAction: Equatable where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.failAndReschedule(let lhs1, let lhs2), .failAndReschedule(let rhs1, let rhs2)):
            return lhs1 == rhs1
                && lhs2 == rhs2
        case (.failAndClose(let lhs1, let lhs2), .failAndClose(let rhs1, let rhs2)):
            return lhs1 == rhs1
                && lhs2 == rhs2
        case (.deadlineCallbackAction(let lhs), .deadlineCallbackAction(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension DNSChannelHandler.StateMachine.GracefulShutdownAction: Equatable
where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.waitForPendingQueries(let lhs), .waitForPendingQueries(let rhs)):
            return lhs == rhs
        case (.closeConnection(let lhs), .closeConnection(let rhs)):
            return lhs == rhs
        case (.doNothing, .doNothing):
            return true
        default:
            return false
        }
    }
}
