public import struct DNSModels.Message
public import struct NIOCore.EventLoopPromise
public import struct NIOCore.NIODeadline

@usableFromInline
package struct PendingQuery {
    @usableFromInline
    package init(promise: DynamicPromise<Message>, requestID: UInt16, deadline: NIODeadline) {
        self.promise = promise
        self.requestID = requestID
        self.deadline = deadline
    }

    @usableFromInline
    package var promise: DynamicPromise<Message>
    @usableFromInline
    package let requestID: UInt16
    package let deadline: NIODeadline

    @inlinable
    package func succeed(with value: Message, removingIDFrom: inout MessageIDGenerator) {
        self.promise._succeed(with: value)
        removingIDFrom.remove(self.requestID)
    }

    /// FIXME: This "removing ID" should happen in the channel handler?
    @inlinable
    package func fail(with error: any Error, removingIDFrom: inout MessageIDGenerator) {
        self.promise._fail(with: error)
        removingIDFrom.remove(self.requestID)
    }
}

@usableFromInline
package enum DynamicPromise<T: Sendable>: Sendable {
    case nio(EventLoopPromise<T>)
    case swift(CheckedContinuation<T, any Error>)

    @usableFromInline
    func _succeed(with value: T) {
        switch self {
        case .nio(let eventLoopPromise):
            eventLoopPromise.succeed(value)
        case .swift(let checkedContinuation):
            checkedContinuation.resume(returning: value)
        }
    }

    @usableFromInline
    func _fail(with error: any Error) {
        switch self {
        case .nio(let eventLoopPromise):
            eventLoopPromise.fail(error)
        case .swift(let checkedContinuation):
            checkedContinuation.resume(throwing: error)
        }
    }
}
