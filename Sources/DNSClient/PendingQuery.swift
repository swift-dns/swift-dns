public import struct DNSModels.Message
public import struct NIOCore.EventLoopPromise
public import struct NIOCore.NIODeadline

@usableFromInline
package struct PendingQuery {
    @usableFromInline
    package init(promise: DynamicPromise<Message>, requestID: Int, deadline: NIODeadline) {
        self.promise = promise
        self.requestID = requestID
        self.deadline = deadline
    }

    package var promise: DynamicPromise<Message>
    package let requestID: Int
    package let deadline: NIODeadline
}

@usableFromInline
package enum DynamicPromise<T: Sendable>: Sendable {
    case nio(EventLoopPromise<T>)
    case swift(CheckedContinuation<T, any Error>)

    package func succeed(_ value: T) {
        switch self {
        case .nio(let eventLoopPromise):
            eventLoopPromise.succeed(value)
        case .swift(let checkedContinuation):
            checkedContinuation.resume(returning: value)
        }
    }

    package func fail(with error: any Error) {
        switch self {
        case .nio(let eventLoopPromise):
            eventLoopPromise.fail(error)
        case .swift(let checkedContinuation):
            checkedContinuation.resume(throwing: error)
        }
    }
}
