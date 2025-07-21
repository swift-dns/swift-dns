import DNSClient
import DNSModels
import NIOCore
import NIOPosix
import Testing

@Suite
struct DNSChannelHandlerStateMachineTests {
    // Function required as the #expect macro does not work with non-copyable types
    func expect(_ value: Bool, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(value, sourceLocation: sourceLocation)
    }

    let pendingQuery = PendingQuery(
        promise: .nio(MultiThreadedEventLoopGroup.singleton.next().makePromise()),
        requestID: 1,
        deadline: .now() + .seconds(1)
    )

    let message = try! MessageFactory<A>.forQuery(name: "mahdibm.com").message

    @Test func fullChainResponseWorks() {
        typealias State = DNSChannelHandler.StateMachine<Int>.State
        var stateMachine = DNSChannelHandler.StateMachine<Int>()

        stateMachine.setActive(context: 1)
        expect(stateMachine.state == State.active(.init(context: 1, pendingQuery: nil)))

        let action1 = stateMachine.sendQuery(pendingQuery)
        #expect(action1 == .sendQuery(1))
        expect(stateMachine.state == State.active(.init(context: 1, pendingQuery: pendingQuery)))

        let action2 = stateMachine.receivedResponse(message: message)
        #expect(action2 == .respond(pendingQuery, .cancel))
        pendingQuery.promise.succeed(message)
        expect(stateMachine.state == State.active(.init(context: 1, pendingQuery: nil)))

        let action3 = stateMachine.setClosed()
        #expect(action3 == .failPendingQuery(nil))
        expect(stateMachine.state == State.closed(nil))
    }
}

extension DNSChannelHandler.StateMachine<Int>.State {
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
                    && lhs.pendingQuery == rhs.pendingQuery
            default:
                return false
            }
        case .closing(let lhs):
            switch rhs {
            case .closing(let rhs):
                return lhs.context == rhs.context
                    && lhs.pendingQuery == rhs.pendingQuery
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

extension DNSChannelHandler.StateMachine<Int>.ActiveState: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.context == rhs.context
            && lhs.pendingQuery == rhs.pendingQuery
    }
}

extension PendingQuery: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.requestID == rhs.requestID
            && lhs.deadline == rhs.deadline
    }
}

extension DNSChannelHandler.StateMachine<Int>.SendQueryAction: Equatable {
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

extension DNSChannelHandler.StateMachine<Int>.ReceivedResponseAction: Equatable {
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

extension DNSChannelHandler.StateMachine<Int>.SetClosedAction: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.failPendingQuery(let lhs), .failPendingQuery(let rhs)):
            return lhs == rhs
        case (.doNothing, .doNothing):
            return true
        default:
            return false
        }
    }
}
