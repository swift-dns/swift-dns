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

    @available(swiftDNSApplePlatforms 15, *)
    @Test func orderOfPendingQueriesIsPreserved() throws {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()

        stateMachine.setProcessing(context: 1)
        expect(stateMachine._state == State.processing(.init(context: 1)))

        let pendingQueries = (0..<1000).map { _ in
            queryProducer.produceFakeMessageAndPendingQuery().1
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

        switch stateMachine._state {
        case .processing(let context):
            #expect(context.context == 1)
            #expect(context.__testing_values() == pendingQueries)
            #expect(context.firstPendingQuery == pendingQueries.first)
        default:
            Issue.record("Expected active state")
        }

        /// Don't leak the promise
        for pendingQuery in pendingQueries {
            queryProducer.fulfillQuery(
                pendingQuery: pendingQuery,
                with: DNSClientError.connectionClosed
            )
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func preflightCheckThrowsDoesNothingWhenProcessing() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        #expect(throws: Never.self) {
            try stateMachine.preflightCheck()
        }
        expect(stateMachine._state == State.processing(.init(context: "context!")))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func preflightCheckThrowsErrorWhenClosing() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (_, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))

        let action2 = stateMachine.gracefulShutdown()
        #expect(action2 == .waitForPendingQueries("context!"))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        isClosing: true,
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        #expect(throws: DNSClientError.connectionClosing) {
            try stateMachine.preflightCheck()
        }
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        isClosing: true,
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: DNSClientError.connectionClosed
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func preflightCheckThrowsErrorWhenClosed() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action2 = stateMachine.gracefulShutdown()
        #expect(action2 == .closeConnection("context!"))
        expect(stateMachine._state == State.closed(nil))

        #expect(throws: DNSClientError.connectionClosed) {
            try stateMachine.preflightCheck()
        }
        expect(stateMachine._state == State.closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func sendQueryAndReceivedResponseWorks() {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (message, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: 1)
        expect(stateMachine._state == State.processing(.init(context: 1)))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery(1, .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: 1,
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action2 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
        #expect(action2 == .respond(pendingQuery, .cancel))
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: message
        )
        expect(stateMachine._state == State.processing(.init(context: 1)))

        let action3 = stateMachine.forceClose()
        #expect(action3 == .failPendingQueriesAndClose([], .cancel))
        expect(stateMachine._state == State.closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func sendQueryThrowsErrorWhenClosing() {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (message1, pendingQuery1) = queryProducer.produceFakeMessageAndPendingQuery()
        let (_, pendingQuery2) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: 1)
        expect(stateMachine._state == State.processing(.init(context: 1)))

        let action1 = stateMachine.sendQuery(pendingQuery1)
        #expect(action1 == .sendQuery(1, .reschedule(pendingQuery1.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: 1,
                        pendingQueries: [pendingQuery1]
                    )
                )
        )

        let action2 = stateMachine.gracefulShutdown()
        #expect(action2 == .waitForPendingQueries(1))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: 1,
                        isClosing: true,
                        pendingQueries: [pendingQuery1]
                    )
                )
        )

        let action3 = stateMachine.sendQuery(pendingQuery2)
        #expect(action3 == .throwError(DNSClientError.connectionClosing))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: 1,
                        isClosing: true,
                        pendingQueries: [pendingQuery1]
                    )
                )
        )
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery2,
            with: DNSClientError.connectionClosing
        )
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: 1,
                        isClosing: true,
                        pendingQueries: [pendingQuery1]
                    )
                )
        )

        let action4 = stateMachine.receivedResponse(requestID: pendingQuery1.requestID)
        #expect(action4 == .respondAndClose(pendingQuery1, .cancel))
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery1,
            with: message1
        )
        expect(stateMachine._state == State.closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func receivedResponseWorksWhenClosingAndReschedulesDeadline() {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (message1, pendingQuery1) = queryProducer.produceFakeMessageAndPendingQuery()
        let (message2, pendingQuery2) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: 1)
        expect(stateMachine._state == State.processing(.init(context: 1)))

        let action1 = stateMachine.sendQuery(pendingQuery1)
        #expect(action1 == .sendQuery(1, .reschedule(pendingQuery1.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: 1,
                        pendingQueries: [pendingQuery1]
                    )
                )
        )

        let action2 = stateMachine.sendQuery(pendingQuery2)
        #expect(action2 == .sendQuery(1, .doNothing))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: 1,
                        pendingQueries: [pendingQuery1, pendingQuery2]
                    )
                )
        )

        let action3 = stateMachine.gracefulShutdown()
        #expect(action3 == .waitForPendingQueries(1))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: 1,
                        isClosing: true,
                        pendingQueries: [pendingQuery1, pendingQuery2]
                    )
                )
        )

        let action4 = stateMachine.receivedResponse(requestID: pendingQuery2.requestID)
        #expect(action4 == .respond(pendingQuery2, .reschedule(pendingQuery1.deadline)))
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery2,
            with: message2
        )
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: 1,
                        isClosing: true,
                        pendingQueries: [pendingQuery1]
                    )
                )
        )

        let action5 = stateMachine.receivedResponse(requestID: pendingQuery1.requestID)
        #expect(action5 == .respondAndClose(pendingQuery1, .cancel))
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery1,
            with: message1
        )
        expect(stateMachine._state == State.closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func cancelBeforeResponse() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (_, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action2 = stateMachine.cancel(requestID: pendingQuery.requestID)
        #expect(action2 == .cancel(pendingQuery, .cancel))
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: DNSClientError.cancelled
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func cancelBeforeQuery() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (message, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.cancel(requestID: pendingQuery.requestID)
        #expect(action1 == .doNothing)
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action2 = stateMachine.sendQuery(pendingQuery)
        #expect(action2 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action3 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
        #expect(action3 == .respond(pendingQuery, .cancel))
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: message
        )
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action4 = stateMachine.forceClose()
        #expect(action4 == .failPendingQueriesAndClose([], .cancel))
        expect(stateMachine._state == State.closed(nil))
    }

    /// Assumption is the channel handler is always `active` when it reaches a user,
    /// and never `initialized`.
    @available(swiftDNSApplePlatforms 15, *)
    @Test func cancelBeforeActivation() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        let stateMachine = StateMachine()

        /// Assert the state, so we can statically recreate it for the exit test
        expect(stateMachine._state == State.initialized)

        /// This code-path should be unreachable
        await #expect(processExitsWith: .failure) {
            var stateMachine = StateMachine.__for_testing(state: .initialized)
            _ = stateMachine.cancel(requestID: .random(in: .min ... .max))
        }
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func cancelBeforeResponseAndResponseArrivesLater() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (_, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action2 = stateMachine.cancel(requestID: pendingQuery.requestID)
        #expect(action2 == .cancel(pendingQuery, .cancel))
        expect(stateMachine._state == State.processing(.init(context: "context!")))
        /// Response is failed due to cancellation
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: DNSClientError.cancelled
        )
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        /// No matching pending query is there anymore
        let action3 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
        #expect(action3 == .doNothing)
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func cancelUnavailableQueryDoesNothingThenResponseArrivesLater() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (message, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let unrelatedID = queryProducer.getNewRequestID()
        let action2 = stateMachine.cancel(requestID: unrelatedID)
        #expect(action2 == .doNothing)
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action5 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
        #expect(action5 == .respond(pendingQuery, .cancel))
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: message
        )
        expect(stateMachine._state == State.processing(.init(context: "context!")))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func cancelWithMultiplePendingQueriesWorksAndReschedulesDeadlineCorrectly() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (_, pendingQuery1) = queryProducer.produceFakeMessageAndPendingQuery()
        let (_, pendingQuery2) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery1)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery1.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery1]
                    )
                )
        )

        let action2 = stateMachine.sendQuery(pendingQuery2)
        #expect(action2 == .sendQuery("context!", .doNothing))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery1, pendingQuery2]
                    )
                )
        )

        let action3 = stateMachine.cancel(requestID: pendingQuery1.requestID)
        /// Action asks to reschedule deadline for the next pending query
        #expect(action3 == .cancel(pendingQuery1, .reschedule(pendingQuery2.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery2]
                    )
                )
        )
        /// Response is failed due to cancellation
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery1,
            with: DNSClientError.cancelled
        )
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery2]
                    )
                )
        )

        let action4 = stateMachine.cancel(requestID: pendingQuery2.requestID)
        /// Action asks to cancel deadline because no more queries are available
        #expect(action4 == .cancel(pendingQuery2, .cancel))
        expect(stateMachine._state == State.processing(.init(context: "context!")))
        /// Response is failed due to cancellation
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery2,
            with: DNSClientError.cancelled
        )
        expect(stateMachine._state == State.processing(.init(context: "context!")))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func cancelWhenClosingWithMultiplePendingQueriesWorksAndReschedulesDeadlineCorrectly() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (_, pendingQuery1) = queryProducer.produceFakeMessageAndPendingQuery()
        let (_, pendingQuery2) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery1)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery1.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery1]
                    )
                )
        )

        let action2 = stateMachine.sendQuery(pendingQuery2)
        #expect(action2 == .sendQuery("context!", .doNothing))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery1, pendingQuery2]
                    )
                )
        )

        let action3 = stateMachine.gracefulShutdown()
        #expect(action3 == .waitForPendingQueries("context!"))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        isClosing: true,
                        pendingQueries: [pendingQuery1, pendingQuery2]
                    )
                )
        )

        let action4 = stateMachine.cancel(requestID: pendingQuery1.requestID)
        /// Action asks to reschedule deadline for the next pending query
        #expect(action4 == .cancel(pendingQuery1, .reschedule(pendingQuery2.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        isClosing: true,
                        pendingQueries: [pendingQuery2]
                    )
                )
        )
        /// Response is failed due to cancellation
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery1,
            with: DNSClientError.cancelled
        )
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        isClosing: true,
                        pendingQueries: [pendingQuery2]
                    )
                )
        )

        let action5 = stateMachine.cancel(requestID: pendingQuery2.requestID)
        /// Action asks to cancel deadline because no more queries are available
        #expect(action5 == .cancelAndClose("context!", pendingQuery2, .cancel))
        expect(stateMachine._state == State.closed(nil))
        /// Response is failed due to cancellation
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery2,
            with: DNSClientError.cancelled
        )
        expect(stateMachine._state == State.closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func cancelWhenClosedDoesNothing() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()

        let action1 = stateMachine.forceClose()
        #expect(action1 == StateMachine.CloseAction.doNothing)
        expect(stateMachine._state == State.closed(nil))

        let requestID = queryProducer.getNewRequestID()
        let action2 = stateMachine.cancel(requestID: requestID)
        #expect(action2 == .doNothing)
        expect(stateMachine._state == State.closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func forceCloseAfterActivationThenQueryThrowsError() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.forceClose()
        #expect(action1 == StateMachine.CloseAction.failPendingQueriesAndClose([], .cancel))
        expect(stateMachine._state == .closed(nil))

        let (_, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()
        let action2 = stateMachine.sendQuery(pendingQuery)
        #expect(action2 == .throwError(DNSClientError.connectionClosed))
        expect(stateMachine._state == .closed(nil))

        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: DNSClientError.connectionClosed
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func forceCloseBeforeActivationDoesNothing() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        let action1 = stateMachine.forceClose()
        #expect(action1 == StateMachine.CloseAction.doNothing)
        expect(stateMachine._state == .closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func forceCloseAfterCloseDoesNothing() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.forceClose()
        #expect(action1 == StateMachine.CloseAction.failPendingQueriesAndClose([], .cancel))
        expect(stateMachine._state == .closed(nil))

        let action2 = stateMachine.forceClose()
        #expect(action2 == StateMachine.CloseAction.doNothing)
        expect(stateMachine._state == .closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func forceCloseAfterQuery() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (_, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action2 = stateMachine.sendQuery(pendingQuery)
        #expect(action2 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action1 = stateMachine.forceClose()
        #expect(
            action1
                == StateMachine.CloseAction.failPendingQueriesAndClose([pendingQuery], .cancel)
        )
        expect(stateMachine._state == .closed(nil))

        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: DNSClientError.connectionClosed
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func forceCloseAfterResponse() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (message, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action2 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
        #expect(action2 == .respond(pendingQuery, .cancel))
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: message
        )
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action3 = stateMachine.forceClose()
        #expect(
            action3
                == StateMachine.CloseAction.failPendingQueriesAndClose([], .cancel)
        )
        expect(stateMachine._state == .closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func forceCloseAfterMultipleQueries() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (_, pendingQuery1) = queryProducer.produceFakeMessageAndPendingQuery()
        let (message2, pendingQuery2) = queryProducer.produceFakeMessageAndPendingQuery()
        let (_, pendingQuery3) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery1)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery1.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery1]
                    )
                )
        )

        let action2 = stateMachine.sendQuery(pendingQuery2)
        #expect(action2 == .sendQuery("context!", .doNothing))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery1, pendingQuery2]
                    )
                )
        )

        let action3 = stateMachine.receivedResponse(requestID: pendingQuery2.requestID)
        #expect(action3 == .respond(pendingQuery2, .reschedule(pendingQuery1.deadline)))
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery2,
            with: message2
        )
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery1]
                    )
                )
        )

        let action4 = stateMachine.sendQuery(pendingQuery3)
        #expect(action4 == .sendQuery("context!", .doNothing))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery1, pendingQuery3]
                    )
                )
        )

        let action5 = stateMachine.forceClose()
        #expect(
            action5
                == StateMachine.CloseAction.failPendingQueriesAndClose(
                    [pendingQuery1, pendingQuery3],
                    .cancel
                )
        )
        expect(stateMachine._state == .closed(nil))

        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery1,
            with: DNSClientError.connectionClosed
        )
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery3,
            with: DNSClientError.connectionClosed
        )
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func forceCloseForcesConnectionCloseWhenClosingAndThereArePendingQueries() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (_, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))

        let action2 = stateMachine.gracefulShutdown()
        #expect(action2 == .waitForPendingQueries("context!"))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        isClosing: true,
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action3 = stateMachine.forceClose()
        #expect(action3 == .failPendingQueriesAndClose([pendingQuery], .cancel))
        expect(stateMachine._state == State.closed(nil))

        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: DNSClientError.connectionClosed
        )
        expect(stateMachine._state == State.closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func hitDeadlineWorksForInflightQuery() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (_, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))

        /// Intentionally pass `pendingQuery.deadline` as `now`. Still should fail and reschedule.
        let action2 = stateMachine.hitDeadline(now: pendingQuery.deadline)
        #expect(action2 == .failAndReschedule(pendingQuery, .cancel))
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: DNSClientError.queryTimeout
        )
        expect(stateMachine._state == State.processing(.init(context: "context!")))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func hitDeadlineDoesNothingWhenNoPendingQueries() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.hitDeadline(now: .now() + .seconds(1))
        #expect(action1 == .deadlineCallbackAction(.cancel))
        expect(stateMachine._state == State.processing(.init(context: "context!")))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func hitDeadlineDoesNotCancelQueryWithUnexpiredDeadline() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (message, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action2 = stateMachine.hitDeadline(now: pendingQuery.deadline + .seconds(-1))
        #expect(action2 == .deadlineCallbackAction(.reschedule(pendingQuery.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action3 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
        #expect(action3 == .respond(pendingQuery, .cancel))
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: message
        )
        expect(stateMachine._state == State.processing(.init(context: "context!")))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func hitDeadlineWithMultiplePendingQueriesWorksAndReschedulesDeadlineCorrectly() {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (_, pendingQuery1) = queryProducer.produceFakeMessageAndPendingQuery()
        let (_, pendingQuery2) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery1)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery1.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery1]
                    )
                )
        )

        let action2 = stateMachine.sendQuery(pendingQuery2)
        #expect(action2 == .sendQuery("context!", .doNothing))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery1, pendingQuery2]
                    )
                )
        )

        let action3 = stateMachine.hitDeadline(now: pendingQuery1.deadline + .seconds(1))
        /// Action asks to reschedule deadline for the next pending query
        #expect(action3 == .failAndReschedule(pendingQuery1, .reschedule(pendingQuery2.deadline)))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery2]
                    )
                )
        )
        /// Response is failed due to cancellation
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery1,
            with: DNSClientError.queryTimeout
        )
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        pendingQueries: [pendingQuery2]
                    )
                )
        )

        let action4 = stateMachine.hitDeadline(now: pendingQuery2.deadline + .seconds(1))
        /// Action asks to cancel deadline because no more queries are available
        #expect(action4 == .failAndReschedule(pendingQuery2, .cancel))
        expect(stateMachine._state == State.processing(.init(context: "context!")))
        /// Response is failed due to cancellation
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery2,
            with: DNSClientError.queryTimeout
        )
        expect(stateMachine._state == State.processing(.init(context: "context!")))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func hitDeadlineClosesConnectionWhenClosingAndNoMorePendingQueries() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (_, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))

        let action2 = stateMachine.gracefulShutdown()
        #expect(action2 == .waitForPendingQueries("context!"))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        isClosing: true,
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action3 = stateMachine.hitDeadline(now: pendingQuery.deadline + .seconds(1))
        #expect(action3 == .failAndClose("context!", pendingQuery, .cancel))
        expect(stateMachine._state == State.closed(nil))

        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: DNSClientError.queryTimeout
        )
        expect(stateMachine._state == State.closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func gracefulShutdownClosesConnectionImmediatelyWhenNoPendingQueries() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.gracefulShutdown()
        #expect(action1 == .closeConnection("context!"))
        expect(stateMachine._state == State.closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func gracefulShutdownBeforeActivationClosesImmediately() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        let action1 = stateMachine.gracefulShutdown()
        #expect(action1 == .doNothing)
        expect(stateMachine._state == State.closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func gracefulShutdownWhenClosingDoesNothing() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()
        let (message, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

        stateMachine.setProcessing(context: "context!")
        expect(stateMachine._state == State.processing(.init(context: "context!")))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery("context!", .reschedule(pendingQuery.deadline)))

        let action2 = stateMachine.gracefulShutdown()
        #expect(action2 == .waitForPendingQueries("context!"))
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        isClosing: true,
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action3 = stateMachine.gracefulShutdown()
        #expect(action3 == .doNothing)
        expect(
            stateMachine._state
                == State.processing(
                    .__for_testing(
                        context: "context!",
                        isClosing: true,
                        pendingQueries: [pendingQuery]
                    )
                )
        )

        let action4 = stateMachine.receivedResponse(requestID: pendingQuery.requestID)
        #expect(action4 == .respondAndClose(pendingQuery, .cancel))
        queryProducer.fulfillQuery(
            pendingQuery: pendingQuery,
            with: message
        )
        expect(stateMachine._state == State.closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test func gracefulShutdownWhenClosedDoesNothing() async {
        typealias StateMachine = DNSChannelHandler.StateMachine<String>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        let action1 = stateMachine.gracefulShutdown()
        #expect(action1 == .doNothing)
        expect(stateMachine._state == State.closed(nil))

        let action2 = stateMachine.gracefulShutdown()
        #expect(action2 == .doNothing)
        expect(stateMachine._state == State.closed(nil))
    }

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: [(queryCount: 1_000, latencyRange: 20...250)])
    func concurrentlySendingQueriesWorks(
        queryCount: Int,
        latencyRange: ClosedRange<Int>
    ) async throws {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()

        stateMachine.setProcessing(context: 1)
        expect(stateMachine._state == State.processing(.init(context: 1)))

        actor QuerySender {
            var stateMachine: StateMachine
            let latencyRange: ClosedRange<Int>
            var queryProducer = QueryProducer()

            init(stateMachine: consuming StateMachine, latencyRange: ClosedRange<Int>) {
                self.stateMachine = stateMachine
                self.latencyRange = latencyRange
            }

            // Function required as the #expect macro does not work with non-copyable types
            func expect(_ value: Bool, sourceLocation: SourceLocation = #_sourceLocation) {
                #expect(value, sourceLocation: sourceLocation)
            }

            func sendQuery() async throws {
                let (message, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

                let action1 = stateMachine.sendQuery(pendingQuery)
                switch action1 {
                case .sendQuery(let context, _):
                    #expect(context == 1)
                    switch stateMachine._state {
                    case .processing(let state):
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
                    queryProducer.fulfillQuery(
                        pendingQuery: pendingQuery,
                        with: message
                    )
                    switch stateMachine._state {
                    case .processing(let state):
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

    @available(swiftDNSApplePlatforms 15, *)
    @Test(arguments: [(queryCount: 30, latencyRange: 20...100)])
    func sequentiallySendingQueriesWorks(
        queryCount: Int,
        latencyRange: ClosedRange<Int>
    ) async {
        typealias StateMachine = DNSChannelHandler.StateMachine<Int>
        typealias State = StateMachine.State
        var stateMachine = StateMachine()
        var queryProducer = QueryProducer()

        stateMachine.setProcessing(context: 1)
        expect(stateMachine._state == State.processing(.init(context: 1)))

        for _ in 0..<queryCount {
            let (message, pendingQuery) = queryProducer.produceFakeMessageAndPendingQuery()

            let action1 = stateMachine.sendQuery(pendingQuery)
            switch action1 {
            case .sendQuery(let context, _):
                #expect(context == 1)
                switch stateMachine._state {
                case .processing(let state):
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
                queryProducer.fulfillQuery(
                    pendingQuery: pendingQuery,
                    with: message
                )
                switch stateMachine._state {
                case .processing(let state):
                    #expect(state.context == 1)
                    expect(!state.__testing_contains(pendingQuery.requestID))
                default:
                    Issue.record("Expected active state")
                }
            default:
                Issue.record("Expected respond action")
            }
        }

        let action3 = stateMachine.forceClose()
        #expect(action3 == .failPendingQueriesAndClose([], .cancel))
        expect(stateMachine._state == State.closed(nil))
    }
}

@available(swiftDNSApplePlatforms 15, *)
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
        case .processing(let lhs):
            switch rhs {
            case .processing(let rhs):
                return lhs == rhs
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

@available(swiftDNSApplePlatforms 15, *)
extension DNSChannelHandler.StateMachine.ProcessingState where Context: Equatable {
    static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        lhs.context == rhs.context
            && lhs.isClosing == rhs.isClosing
            && lhs.__testing_values() == rhs.__testing_values()
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension PendingQuery: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.requestID == rhs.requestID
            && lhs.deadline == rhs.deadline
    }
}

@available(swiftDNSApplePlatforms 15, *)
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

@available(swiftDNSApplePlatforms 15, *)
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

@available(swiftDNSApplePlatforms 15, *)
extension DNSChannelHandler.StateMachine.ReceivedResponseAction: Equatable
where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.respond(let lhs1, let lhs2), .respond(let rhs1, let rhs2)):
            return lhs1 == rhs1
                && lhs2 == rhs2
        case (.respondAndClose(let lhs1, let lhs2), .respondAndClose(let rhs1, let rhs2)):
            return lhs1 == rhs1
                && lhs2 == rhs2
        case (.doNothing, .doNothing):
            return true
        default:
            return false
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension DNSChannelHandler.StateMachine.CancelAction: Equatable where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (
            .cancel(let lhs, let lhs2),
            .cancel(let rhs, let rhs2)
        ):
            return lhs == rhs
                && lhs2 == rhs2
        case (
            .cancelAndClose(let lhs, let lhs2, let lhs3),
            .cancelAndClose(let rhs, let rhs2, let rhs3)
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

@available(swiftDNSApplePlatforms 15, *)
extension DNSChannelHandler.StateMachine.CloseAction: Equatable where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (
            .failPendingQueriesAndClose(let lhs1, let lhs2),
            .failPendingQueriesAndClose(let rhs1, let rhs2)
        ):
            return lhs1 == rhs1
                && lhs2 == rhs2
        case (.doNothing, .doNothing):
            return true
        default:
            return false
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension DNSChannelHandler.StateMachine.HitDeadlineAction: Equatable where Context: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.failAndReschedule(let lhs1, let lhs2), .failAndReschedule(let rhs1, let rhs2)):
            return lhs1 == rhs1
                && lhs2 == rhs2
        case (
            .failAndClose(let lhs1, let lhs2, let lhs3), .failAndClose(let rhs1, let rhs2, let rhs3)
        ):
            return lhs1 == rhs1
                && lhs2 == rhs2
                && lhs3 == rhs3
        case (.deadlineCallbackAction(let lhs), .deadlineCallbackAction(let rhs)):
            return lhs == rhs
        default:
            return false
        }
    }
}

@available(swiftDNSApplePlatforms 15, *)
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

@available(swiftDNSApplePlatforms 15, *)
extension DNSClientError: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.description == rhs.description
    }
}

@available(swiftDNSApplePlatforms 15, *)
extension QueryProducer {
    mutating func produceFakeMessageAndPendingQuery() -> (Message, PendingQuery) {
        let factory = try! MessageFactory<A>.forQuery(domainName: "mahdibm.com")
        let message = try! self.produceDNSMessage(
            message: factory,
            options: []
        )
        let producedMessage = try! ProducedMessage(
            message: message,
            allocator: .init()
        )
        let pendingQuery = producedMessage.producePendingQuery(
            promise: .nio(DNSClient.defaultUDPEventLoopGroup.next().makePromise()),
            deadline: .now() + .seconds(10)
        )
        return (message, pendingQuery)
    }

    mutating func getNewRequestID() -> UInt16 {
        let factory = try! MessageFactory<A>.forQuery(domainName: "mahdibm.com")
        let producedMessage = try! self.produceMessage(
            message: factory,
            options: [],
            allocator: .init()
        )
        return producedMessage.messageID
    }
}
